import json
import os
import urllib.request

import boto3
from botocore.exceptions import ClientError


def trigger_redeployment(event, lambda_context):
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

    url = "https://api.github.com/repos/crew102/biobuddy/actions/workflows/deploy.yml/dispatches"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {secret}",
    }
    data = json.dumps({
        "ref": "main",
        "inputs": {"app_sha": "latest-prod", "environment": "prod"}
    }).encode("utf-8")

    req = urllib.request.Request(url, data=data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req) as response:
            response_body = response.read().decode("utf-8")
            status_code = response.getcode()
            response_json = json.loads(response_body)
    except urllib.error.HTTPError as e:
        print(e)
        raise e

    return {
        "statusCode": status_code,
        "body": response_json
    }
