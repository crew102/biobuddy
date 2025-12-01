import argparse
import os

import requests

from deploy_utils import get_latest_commit_sha


def _trigger_github_action(workflow_file="build-app-image.yml", app_sha=None,
                           environment="staging"):
    if app_sha is None:
        app_sha = get_latest_commit_sha(check_remote=False)
        print(f"\nUsing latest commit SHA as app_sha, which is {app_sha}\n")

    url = f"https://api.github.com/repos/crew102/biobuddy/actions/workflows/{workflow_file}/dispatches"
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Authorization": f"Bearer {os.environ.get('GITHUB_PAT')}",
    }
    data = {"ref": "main"}

    if workflow_file == "build-app-image.yml":
        print(
            "\n\nReminder that we are using latest version of the deps image "
            "for this app build\n\n"
        )
        data["inputs"] = {"app_sha": app_sha, "deps_sha": "latest"}
    elif workflow_file == "build-deps-image.yml":
        data["inputs"] = {"deps_sha": app_sha}
    elif workflow_file == "deploy.yml":
        if environment is None:
            raise ValueError(
                "An environment (staging|prod) must be provided for deploy.yml"
            )
        data["inputs"] = {"app_sha": app_sha, "environment": environment}
    else:
        data["inputs"] = {"app_sha": app_sha}

    response = requests.post(url, json=data, headers=headers)
    if response.status_code == 204:
        print("GitHub Action triggered successfully.")
    else:
        print(f"Failed to trigger GitHub Action: {response.status_code}")
        raise RuntimeError(response.json())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trigger a GitHub Action")
    parser.add_argument(
        "--workflow_file", default="build-app-image.yml",
        help="The name of the workflow YAML file, with .yml ending included"
    )
    parser.add_argument(
        "--app_sha", default=None,
        help="The SHA of the git commit to use for build or deployment. "
             "If none, use latest commit"
    )
    parser.add_argument(
        "--environment", default="staging",
        help="The environment to deploy to, prod or staging"
    )

    args = parser.parse_args()

    _trigger_github_action(args.workflow_file, args.app_sha, args.environment)
