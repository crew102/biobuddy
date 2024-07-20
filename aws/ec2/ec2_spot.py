import json

from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_s3 as s3,
    RemovalPolicy
)
from constructs import Construct
from cdk_ec2_spot_simple import SpotInstance
import boto3

LOCAL_IP = '108.51.225.117/32'


def _get_secret(secret_name):
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=secret_name)
    ss = response['SecretString']
    a_dict = json.loads(ss)
    return a_dict[secret_name]


class EC2spot(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Create a VPC with a public subnet
        vpc = ec2.Vpc(
            self, "ccb-vpc",
            max_azs=2,
            subnet_configuration=[
                ec2.SubnetConfiguration(
                    subnet_type=ec2.SubnetType.PUBLIC,
                    name="Public",
                    cidr_mask=24
                )
            ]
        )

        # The read-secrets-from-ec2 ARN
        role_arn = _get_secret("READ-SECRETS-FROM-EC2")
        # Reference the existing IAM Role
        # TODO: Rename this role
        secrets_role = iam.Role.from_role_arn(
            self, "ccb-existing-secrets-role",
            role_arn=role_arn,
            # Set mutable to False as the role is not defined within this stack
            mutable=False
        )

        bucket = s3.Bucket(
            self, "catchall-data-bucket",
            removal_policy=RemovalPolicy.RETAIN
        )
        policy = iam.PolicyStatement(
            actions=["s3:*"],
            resources=[bucket.bucket_arn, f"{bucket.bucket_arn}/*"]
        )
        secrets_role.attach_inline_policy(
            iam.Policy(self, "ccb-read-s3-bucket", statements=[policy])
        )

        sg = ec2.SecurityGroup(
            self, id="ccb-security-group",
            vpc=vpc, allow_all_outbound=True
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(LOCAL_IP),
            connection=ec2.Port.tcp(22)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(LOCAL_IP),
            connection=ec2.Port.tcp(9443)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(LOCAL_IP),
            connection=ec2.Port.tcp(8787)
        )
        sg.add_ingress_rule(
            peer=ec2.Peer.ipv4(LOCAL_IP),
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

        # See notes re: how to get an AMI programmatically at runtime
        machine_image = ec2.MachineImage.generic_linux(
            ami_map={"us-east-1": "ami-04a81a99f5ec58529"},
            user_data=user_data
        )
        spot_instance = SpotInstance(
            self, "app-spot",
            instance_type=ec2.InstanceType("t3.medium"),
            machine_image=machine_image,
            vpc=vpc,
            key_name="pair-2",
            security_group=sg,
            role=secrets_role,
            block_devices=[
                ec2.BlockDevice(
                    device_name="/dev/sda1",
                    # TODO(cbaker): update this
                    volume=ec2.BlockDeviceVolume.ebs(20)
                )
            ],
            user_data=ec2.UserData.custom(startup_script),
            vpc_subnets=ec2.SubnetSelection(subnets=[vpc.public_subnets[0]])
        )

        # Associate the Elastic IP with the Spot Instance
        ec2.CfnEIPAssociation(
            self, "eip-spot-association",
            # existing elastic IP
            allocation_id="eipalloc-023ea7cfc4367442b",
            instance_id=spot_instance.instance_id,
        )
