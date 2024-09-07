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

app:
	docker run --rm -it -p 3838:3838 -v `pwd`/secrets.txt:/root/.Renviron -v `pwd`/app:/home/biobuddy/app -v `pwd`/R:/home/biobuddy/R bb-app

py-venv-install:
	python3 -m venv .venv
	source .venv/bin/activate
	python3 -m pip install -r requirements.txt

aws-deploy:
	source .venv/bin/activate; cd aws; cdk destroy --force $(ENV_NAME); cdk deploy $(ENV_NAME) -e --require-approval never

aws-stage:
	$(MAKE) aws-deploy ENV_NAME=ec2-spot-staging

aws-prod:
	$(MAKE) aws-deploy ENV_NAME=ec2-spot-prod

clean:
	docker image prune

writedir:
	sudo chmod -R 777 /home/biobuddy/

ebuild:
	sudo cat /var/log/cloud-init-output.log

.PHONY: bup build img app clean writedir ebuild
