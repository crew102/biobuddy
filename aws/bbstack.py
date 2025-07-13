import os
import re
import subprocess

from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_iam as iam,
    aws_s3 as s3,
    aws_lambda as _lambda,
    aws_events as events,
    aws_events_targets as targets,
    aws_secretsmanager as secretsmanager
)
from constructs import Construct
from cdk_ec2_spot_simple import SpotInstance
import boto3

from deploy_utils import get_latest_commit_sha, get_local_ip
from shutdown.lambda_fun import get_secret

DEFAULT_INSTANCE_TYPE = "t3.large"
RESTART_INSTANCE_TYPE = "t3.medium"
AMI_ID = "ami-04a81a99f5ec58529"
EBS_VOLUME_SIZE = 20

LOCAL_IP = get_local_ip()


class BiobuddyStack(Stack):

    def __init__(self, scope: Construct, id: str, environment: str,
                 allocation_id: str, restart = False, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        if restart:
            instance_type = RESTART_INSTANCE_TYPE
        else:
            instance_type = DEFAULT_INSTANCE_TYPE

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
        role_arn = get_secret("READ-SECRETS-FROM-EC2")
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
        # No big deal if local IP changes, just update security settings in
        # AWS web app/console
        if LOCAL_IP is not None:
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
        # Not terribly proud of this hack, but it's simpler than using a script
        # argument where I would have to upload the script to S3
        startup_script = re.sub(
            '"\\$1"', get_latest_commit_sha(), startup_script
        )
        user_data = ec2.UserData.custom(startup_script)
        machine_image = ec2.MachineImage.generic_linux(
            ami_map={"us-east-1": AMI_ID},
            user_data=user_data
        )
        spot_instance = SpotInstance(
            self, f"{environment}-app-spot",
            instance_type=ec2.InstanceType(instance_type),
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
            user_data=user_data,
            vpc_subnets=ec2.SubnetSelection(subnets=[vpc.public_subnets[0]])
        )

        ec2.CfnEIPAssociation(
            self, f"{environment}-eip-spot-association",
            allocation_id=allocation_id,
            instance_id=spot_instance.instance_id,
        )

        # Create a Lambda layer with boto3
        layer_dir = "shutdown/lambda-layer"
        requirements_file = os.path.join(layer_dir, "requirements.txt")
        subprocess.run([
            "pip", "install", "-r", requirements_file, "-t", layer_dir
        ])
        lambda_layer = _lambda.LayerVersion(
            self, "lambda-layer",
            code=_lambda.Code.from_asset(layer_dir),
            compatible_runtimes=[_lambda.Runtime.PYTHON_3_9]
        )

        # Redeployment trigger functionality via EventBridge and Lambda
        lambda_function = _lambda.Function(
            self, "spot-interruption-handler",
            runtime=_lambda.Runtime.PYTHON_3_9,
            handler="lambda_fun.trigger_redeployment",
            code=_lambda.Code.from_asset("shutdown"),
            layers=[lambda_layer]
        )

        # Grant the Lambda function permission to read the GitHub token secret
        github_token_secret = secretsmanager.Secret.from_secret_name_v2(
            self, "gh-pat-secret", "GITHUB_PAT"
        )
        github_token_secret.grant_read(lambda_function)

        # Create the EventBridge rule
        spot_interruption_rule = events.Rule(
            self, "spot-interruption-rule",
            event_pattern=events.EventPattern(
                source=["aws.ec2"],
                detail_type=["EC2 Spot Instance Interruption Warning"]
            )
        )
        spot_interruption_rule.add_target(targets.LambdaFunction(lambda_function))
