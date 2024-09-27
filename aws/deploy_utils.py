import os
import subprocess

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
