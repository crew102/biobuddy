# Local setup
# Note that renv environment should be bootstrapped automatically when project
# is opened in RStudio
################################################################################
py-venv-install:
	python3 -m venv .venv
	. .venv/bin/activate
	# Will pull in aws/requirements.txt as well, so all reqs will be available
	# on local:
	python3 -m pip install -r requirements.txt

# Local dev targets
################################################################################
local-deps-build:
	Rscript scripts/lockfile-write.R
	docker build -t ghcr.io/crew102/bb-deps:latest .

local-app-build:
	docker build -t ghcr.io/crew102/bb-app:latest --no-cache -f app/Dockerfile .

local-deploy: local-app-build
	docker compose build --no-cache
	docker compose down
	docker compose up -d

# Deploy stacks (either from local or from GH action)
# Reminder: You would want a fresh bb-app image in the GH CR and also code
# pushed to GH before triggering these locally:
################################################################################
_aws-deploy:
	. .venv/bin/activate; cd aws; cdk destroy --force $(ENV_NAME); cdk deploy $(ENV_NAME) -e --require-approval never

aws-stage:
	$(MAKE) _aws-deploy ENV_NAME=ec2-spot-staging

aws-prod:
	$(MAKE) _aws-deploy ENV_NAME=ec2-spot-prod

# GH actions. Note that the targets shown above are used for deployment-related
# tasks below.
################################################################################
gh-deps-build:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="build-deps-image.yml"

gh-app-build:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="build-app-image.yml"

gh-deploy-stage:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="deploy.yml" --environment="staging"

gh-deploy-prod:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="deploy.yml" --environment="prod"

# Misc. helpers
################################################################################
# Open up ports to EC2 from local if deployed from GH:
open-sg:
	.venv/bin/python aws/open_sg.py

dprune:
	docker system prune -a

clean:
	docker image prune

write-dir:
	sudo chmod -R 777 /home/biobuddy/

cat-log:
	sudo cat /var/log/cloud-init-output.log

# Kinda doubt I'll have directories named after any other of my targets except
# maybe these:
.PHONY: dprune clean
