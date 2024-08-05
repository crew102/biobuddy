import json
import os
import re

from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_s3 as s3
)
from constructs import Construct
from cdk_ec2_spot_simple import SpotInstance
import boto3

INSTANCE_TYPE = "t3.medium"
AMI_ID = "ami-04a81a99f5ec58529"
EBS_VOLUME_SIZE = 20


def _get_secret(secret_name):
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    ss = response["SecretString"]
    a_dict = json.loads(ss)
    return a_dict[secret_name]


class EC2spot(Stack):

    def __init__(self, scope: Construct, id: str, environment: str,
                 allocation_id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Create a VPC with a public subnet
        vpc = ec2.Vpc(
            self, f"{environment}-vpc",
            max_azs=2,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    subnet_type=ec2.SubnetType.PUBLIC,
                    name=f"{environment}-subnet", cidr_mask=24
                )
            ],
        )

        # The read-secrets-from-ec2 ARN
        role_arn = _get_secret("READ-SECRETS-FROM-EC2")
        # Reference the existing IAM Role
        secrets_role = iam.Role.from_role_arn(
            self, "existing-secrets-role",
            role_arn=role_arn,
            mutable=False
        )

        bid = "catchall-data-bucket"
        bid_id = bid.replace("-", "")
        s3_client = boto3.client("s3")
        bucks = s3_client.list_buckets()
        bucket_exists = [
            i for i in bucks["Buckets"] if re.search(bid_id, i["Name"])
        ]
        if not bucket_exists:
            s3.Bucket(
                self,
                bid,
                public_read_access=True,
                website_index_document="index.html",
                block_public_access=s3.BlockPublicAccess(
                    block_public_acls=False,
                    ignore_public_acls=False,
                    block_public_policy=False,
                    restrict_public_buckets=False,
                ),
            )

        sg = ec2.SecurityGroup(
            self, id=f"{environment}-security-group",
            vpc=vpc, allow_all_outbound=True
        )
        ip = os.environ.get("LOCAL_IP")
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(ip),
            connection=ec2.Port.tcp(22)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(ip),
            connection=ec2.Port.tcp(9443)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(ip),
            connection=ec2.Port.tcp(8787)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(ip),
            connection=ec2.Port.tcp(3838)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.HTTPS.tcp(443)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.HTTP.tcp(80)
        )

        with open("ec2-startup.sh", "r") as f:
            startup_script = f.read()
        user_data = ec2.UserData.custom(startup_script)
        machine_image = ec2.MachineImage.generic_linux(
            ami_map={"us-east-1": AMI_ID},
            user_data=user_data
        )
        spot_instance = SpotInstance(
            self, f"{environment}-app-spot",
            instance_type=ec2.InstanceType(INSTANCE_TYPE),
            machine_image=machine_image,
            vpc=vpc,
            key_name="pair-2",
            security_group=sg,
            role=secrets_role,
            block_devices=[
                ec2.BlockDevice(
                    device_name="/dev/sda1",
                    volume=ec2.BlockDeviceVolume.ebs(EBS_VOLUME_SIZE)
                )
            ],
            user_data=ec2.UserData.custom(startup_script),
            vpc_subnets=ec2.SubnetSelection(subnets=[vpc.public_subnets[0]])
        )

        ec2.CfnEIPAssociation(
            self, f"{environment}-eip-spot-association",
            allocation_id=allocation_id,
            instance_id=spot_instance.instance_id,
        )
