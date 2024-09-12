import argparse

from deploy_utils import trigger_github_action


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

    trigger_github_action(args.workflow_file, args.app_sha, args.environment)
