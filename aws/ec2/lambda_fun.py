import json
import urllib.request

from deploy_utils import get_secret


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
    # Trying to have no python package deps in my lambda function, hence use of
    # urllib instead of requests:
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
