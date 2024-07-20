import json

from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_iam as iam,
    aws_lambda as _lambda,
    aws_events as events,
    aws_events_targets as targets,
    RemovalPolicy
)
from constructs import Construct
from cdk_ec2_spot_simple import SpotInstance
import boto3

LOCAL_IP = '108.51.225.117/32'


def _get_secret_via_sm_arn(secret_name):
    # Initialize the Secrets Manager client
    client = boto3.client('secretsmanager')

    # Paginate through all secrets if necessary
    paginator = client.get_paginator('list_secrets')

    arn_val = ''
    for page in paginator.paginate():
        for secret in page['SecretList']:
            if secret['Name'] == secret_name:
                arn_val = secret['ARN']

    # Get the secret value
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=arn_val)
    ss = response['SecretString']
    a_dict = json.loads(ss)
    return a_dict[secret_name]


class EcsOnFargate(Stack):

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

        # Create an ECS Cluster
        cluster = ecs.Cluster(
            self, "ecs-cluster",
            vpc=vpc, enable_fargate_capacity_providers=True
        )
        cluster.apply_removal_policy(RemovalPolicy.DESTROY)

        # Define the Task Definition
        task_definition = ecs.FargateTaskDefinition(
            self, "fargate-task",
            memory_limit_mib=512, cpu=256,
        )
        # Add container to the Task Definition
        task_definition.add_container(
            "HelloWorldContainer",
            image=ecs.ContainerImage.from_registry("hello-world"),
            logging=ecs.LogDriver.aws_logs(stream_prefix="HelloWorld")
        )

        # IAM Role for Lambda
        lambda_role = iam.Role(
            self, "lambda-iam-role",
            assumed_by=iam.ServicePrincipal("lambda.amazonaws.com"),
            managed_policies=[
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "service-role/AWSLambdaBasicExecutionRole"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AmazonECS_FullAccess"
                ),
                iam.ManagedPolicy.from_aws_managed_policy_name(
                    "AmazonEC2ContainerRegistryReadOnly"
                )
            ]
        )

        # Lambda function to start Fargate Task
        start_task_function = _lambda.Function(
            self, "start-fargate-task",
            runtime=_lambda.Runtime.PYTHON_3_8,
            handler="index.lambda_handler",
            code=_lambda.Code.from_inline(
                f"""
import boto3

def lambda_handler(event, context):
    client = boto3.client('ecs')
    response = client.run_task(
        cluster='{cluster.cluster_name}',
        capacityProviderStrategy=[{{
            'capacityProvider': 'FARGATE_SPOT',
            'weight': 1
        }}],
        taskDefinition='{task_definition.task_definition_arn}',
        networkConfiguration={{
            'awsvpcConfiguration': {{
                'subnets': ['{vpc.public_subnets[0].subnet_id}'],
                'assignPublicIp': 'ENABLED'
            }}
        }}
    )
    print(response)
                """
            ),
            role=lambda_role
        )

        # Create a rule to trigger the Lambda function at 4 PM every day
        rule = events.Rule(
            self, "lambda-cron-rule",
            schedule=events.Schedule.cron(minute="35", hour="0")
        )
        rule.add_target(targets.LambdaFunction(start_task_function))

        role_arn = _get_secret_via_sm_arn("READ-SECRETS-FROM-EC2")
        # Reference the existing IAM Role
        secrets_role = iam.Role.from_role_arn(
            self, "ccb-existing-secrets-role",
            role_arn=role_arn,
            # Set mutable to False as the role is not defined within this stack
            mutable=False
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

        # Spot instance to host the site
        startup_script = """#!/bin/bash
        echo "Hello, World!" > /tmp/hello.txt
        """
        user_data = ec2.UserData.custom(startup_script)
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
