bup:
	docker compose down
	docker compose up -d

build:
	docker compose build --no-cache
	docker compose down
	docker compose up -d

# Build main app image totally locally, with potentially new dependencies added
img-deps-local:
	Rscript scripts/lockfile-write.R
	docker build -t ghcr.io/crew102/bb-deps:latest .

img-app-local:
	docker build -t ghcr.io/crew102/bb-app:latest --no-cache -f app/Dockerfile .

dprune:
	docker system prune -a

py-venv-install:
	python3 -m venv .venv
	. .venv/bin/activate
	python3 -m pip install -r requirements.txt

aws-deploy:
	. .venv/bin/activate; cd aws; cdk destroy --force $(ENV_NAME); cdk deploy $(ENV_NAME) -e --require-approval never

aws-stage:
	$(MAKE) aws-deploy ENV_NAME=ec2-spot-staging

aws-prod:
	$(MAKE) aws-deploy ENV_NAME=ec2-spot-prod

open-sg:
	.venv/bin/python aws/open_sg.py

# Locally triggered Github action-based jobs
gh-app-build:
	.venv/bin/python aws/trigger_gh_action_job.py

gh-stage-deploy:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="deploy.yml" --environment="staging"

gh-prod-deploy:
	.venv/bin/python aws/trigger_gh_action_job.py --workflow_file="deploy.yml" --environment="prod"

clean:
	docker image prune

writedir:
	sudo chmod -R 777 /home/biobuddy/

ebuild:
	sudo cat /var/log/cloud-init-output.log

.PHONY: bup build img app clean writedir ebuild
