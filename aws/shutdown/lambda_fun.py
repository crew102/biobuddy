import json
import urllib.request

import boto3


def get_secret(secret_name):
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    ss = response["SecretString"]
    a_dict = json.loads(ss)
    return a_dict[secret_name]


def trigger_redeployment(event, lambda_context):
    secret = get_secret("GITHUB_PAT")

    url = "https://api.github.com/repos/crew102/biobuddy/actions/workflows/deploy.yml/dispatches"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {secret}",
    }
    data = json.dumps({
        "ref": "main",
        "inputs": {"app_sha": "latest-prod", "environment": "prod"}
    })
    data = data.encode()
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")

    try:
        with urllib.request.urlopen(req) as response:
            response_body = response.read().decode("utf-8")
            status_code = response.getcode()
            response_json = json.loads(response_body)
    except urllib.error.HTTPError as e:
        print(f"HTTPError: {e}")
        raise e

    return {
        "statusCode": status_code,
        "body": response_json
    }
