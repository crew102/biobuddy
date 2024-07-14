from aws_cdk import (
    Stack,
    aws_ec2 as ec2,
    aws_ecs as ecs,
    aws_iam as iam,
    aws_lambda as _lambda,
    aws_events as events,
    aws_events_targets as targets,
    RemovalPolicy,
)
from constructs import Construct


class EcsOnFargate(Stack):

    def __init__(self, scope: Construct, id: str, **kwargs) -> None:
        super().__init__(scope, id, **kwargs)

        # Create a VPC
        vpc = ec2.Vpc(self, "ccb-vpc", max_azs=2)

        # Create an ECS Cluster
        cluster = ecs.Cluster(
            self, "ccb-ecs-cluster", vpc=vpc,
            enable_fargate_capacity_providers=True
        )
        cluster.apply_removal_policy(RemovalPolicy.DESTROY)

        # Define the Task Definition
        task_definition = ecs.FargateTaskDefinition(
            self, "ccb-fargate-task",
            memory_limit_mib=512,
            cpu=256,
        )

        # Add container to the Task Definition
        task_definition.add_container(
            "HelloWorldContainer",
            image=ecs.ContainerImage.from_registry("hello-world"),
            logging=ecs.LogDriver.aws_logs(stream_prefix="HelloWorld")
        )

        # IAM Role for Lambda
        lambda_role = iam.Role(
            self,
            "LambdaExecutionRole",
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
            self, "StartFargateTaskFunction",
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
                'subnets': ['{vpc.private_subnets[0].subnet_id}'],
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
            self, "Rule",
            schedule=events.Schedule.cron(minute="35", hour="0")
        )
        rule.add_target(targets.LambdaFunction(start_task_function))
