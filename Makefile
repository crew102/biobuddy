################################################################################
# Local setup
# 	Note that renv environment should be bootstrapped automatically when project
# 	is opened in RStudio
################################################################################
py-venv-install:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements.txt
	.venv/bin/pip install ipython

################################################################################
# Build and deploy app locally
################################################################################
local-deps-build:
	Rscript dev/lockfile-write.R
	docker build -t ghcr.io/crew102/bb-deps:latest .

local-app-build:
	docker build -t ghcr.io/crew102/bb-app:latest --no-cache -f app/Dockerfile .

local-deploy: local-app-build
	docker compose build --no-cache
	docker compose down
	docker compose up -d

################################################################################
# Build and deploy app (stack) to AWS.
# 	Reminder: You would want a fresh bb-app image in the GH CR and also code
# 	pushed to GH before triggering these locally
################################################################################

######## Deploy app using local AWS CDK ########
_aws-deploy:
	. .venv/bin/activate; cd aws; cdk destroy --force $(STACK_ID); cdk deploy $(STACK_ID) -e --require-approval never

_destroy-prod-stacks:
	. .venv/bin/activate; cd aws; cdk destroy --force bb-app-prod; cdk destroy --force bb-app-prod-restart; cd ..

aws-stage:
	$(MAKE) _aws-deploy STACK_ID=bb-app-staging

aws-prod:
	$(MAKE) _aws-deploy STACK_ID=bb-app-prod

# aws-prod-restart is never meant to be called locally. Only called via the
# "latest-prod" as app_sha trigger in deploy.yml, which would have been
# triggered via lambda function (the _trigger_github_action() -> trigger_redeployment route)
aws-prod-restart: _destroy-prod-stacks
	. .venv/bin/activate; cd aws; cdk deploy bb-app-prod-restart -e --require-approval never

######## Deploy app using AWS CDK on GH action runner ########
gh-deps-build:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="build-deps-image.yml"

gh-app-build:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="build-app-image.yml"

gh-deploy-stage:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="deploy.yml" --environment="staging"

gh-deploy-prod: _destroy-prod-stacks
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="deploy.yml" --environment="prod"

################################################################################
# Misc. helpers
################################################################################
# Open up ports to EC2 from local if deployed from GH:
open-sg:
	.venv/bin/python aws/open_sg.py

test-shutdown:
	.venv/bin/python aws/shutdown/update_event_rule.py --switch_to="custom.ec2.simulation"
	aws/shutdown/simulate-ec2-shutdown.sh

reset-event-rule:
	.venv/bin/python aws/shutdown/update_event_rule --switch_to="aws.ec2"

write-dir:
	sudo chmod -R 777 /home/biobuddy/

cat-log:
	sudo cat /var/log/cloud-init-output.log
