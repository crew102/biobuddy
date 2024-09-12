import os
import subprocess
import json

import requests
import boto3

LOCAL_IP = os.environ.get("LOCAL_IP")


# The idea here is that in both scenarios where we want to deploy the stack
# (locally during dev and on a Github Action), we'll be running the deployment
# command inside the repo at the commit we want to deploy.
# Reminder that you have to push to Github though so that any recent local
# commit is available to be fetched in the EC2 startup script.
def get_latest_commit_sha(check_remote=True):
    if check_remote:
        if LOCAL_IP is not None:
            result = subprocess.run(
                ["git", "log", "origin/main..main"],
                capture_output=True, text=True
            )
            if result.stdout.strip() != "":
                raise RuntimeError("Origin is out of sync with local repo")
    result = subprocess.run(
        ["git", "rev-parse", "--short", "HEAD"],
        capture_output=True, text=True
    )
    return result.stdout.strip()


def trigger_github_action(workflow_file="build-app-image.yml", app_sha=None,
                          environment="staging"):
    if app_sha is None:
        app_sha = get_latest_commit_sha(check_remote=False)
        print(f"Using latest commit SHA as app_sha, which is {app_sha}")

    url = f"https://api.github.com/repos/crew102/biobuddy/actions/workflows/{workflow_file}/dispatches"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {os.environ.get('GITHUB_PAT')}",
    }
    if workflow_file=="build-app-image.yml":
        print(
            "Reminder that we are using latest version of the deps image for "
            "this app build"
        )
        data = {
            "ref": "main",
            "inputs": {"app_sha": app_sha, "deps_sha": "latest"}
        }
    else:
        data = {
            "ref": "main",
            "inputs": {"app_sha": app_sha, "environment": environment}
        }

    response = requests.post(url, json=data, headers=headers)
    if response.status_code == 204:
        print("GitHub Action triggered successfully.")
    else:
        print(f"Failed to trigger GitHub Action: {response.status_code}")
        raise RuntimeError(response.json())


def get_secret(secret_name):
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    ss = response["SecretString"]
    a_dict = json.loads(ss)
    return a_dict[secret_name]
