bup:
	docker compose down
	docker compose up -d

build:
	docker compose build --no-cache
	docker compose down
	docker compose up -d

# Build main app image totally locally, with potentially new dependencies added
img-local:
	Rscript scripts/lockfile-write.R
	docker build -t bb-app -f app/Dockerfile .

# Build app on aws, using existing lockfile
img-deploy:
	docker build -t bb-app -f app/Dockerfile .

app:
	docker run --rm -it -p 3838:3838 -v `pwd`/secrets.txt:/root/.Renviron -v `pwd`/app:/home/biobuddy/app -v `pwd`/R:/home/biobuddy/R bb-app

py-venv-install:
	cd aws; source .venv/bin/activate; pip install -r requirements.txt

aws-stage:
	# To avoid issues where an existing resource is already associated with
	# an instance, destroy stack first...Will probably need to add
	# a DeletionPolicy for s3 bucket and whatnot. That, or use boto3 to destroy
	# associations at runtime
	cd aws; source .venv/bin/activate; cdk destroy --force; cdk deploy ec2-spot-staging -e --require-approval never

aws-prod:
	cd aws; source .venv/bin/activate; cdk destroy --force; cdk deploy ec2-spot-prod -e --require-approval never

clean:
	docker image prune

writedir:
	sudo chmod -R 777 /home/biobuddy/

.PHONY: bup build img app clean writedir
