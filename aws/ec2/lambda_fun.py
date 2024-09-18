import os

import requests
import boto3
from botocore.exceptions import ClientError


def trigger_redeployment():
    # Get the secret ARN from environment variable
    secret_arn = os.environ["GITHUB_TOKEN_SECRET_ARN"]
    secret_name = secret_arn.split(":")[-1]

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager")

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        print(e)
        raise e

    # Decrypts secret using the associated KMS key.
    if "SecretString" in get_secret_value_response:
        secret = get_secret_value_response["SecretString"]
    else:
        secret = get_secret_value_response["SecretBinary"]

    url = f"https://api.github.com/repos/crew102/biobuddy/actions/workflows/deploy.yml/dispatches"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {secret}",
    }
    data = {
        "ref": "main",
        "inputs": {"app_sha": "latest-prod", "environment": "prod"}
    }

    response = requests.post(url, json=data, headers=headers)

    return {
        'statusCode': response.status_code,
        'body': response.json()
    }
