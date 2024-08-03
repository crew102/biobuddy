bup:
	docker compose down
	docker compose up -d

build:
	docker compose build --no-cache
	docker compose down
	docker compose up -d

img:
	Rscript scripts/lockfile-write.R
	docker build -t bb-app -f app/Dockerfile .

app:
	docker run --rm -it -p 3838:3838 -v `pwd`/secrets.txt:/root/.Renviron -v `pwd`/app:/home/biobuddy/app -v `pwd`/R:/home/biobuddy/R bb-app

py-venv-install:
	cd aws; source .venv/bin/activate; pip install -r requirements.txt

aws-downup:
	# To avoid issues where an existing resource is already associated with
	# an instance, destroy stack first...Will probably need to add
	# a DeletionPolicy for s3 bucket and whatnot. That, or use boto3 to destroy
	# associations at runtime
	cd aws; source .venv/bin/activate; cdk destroy --force; cdk deploy --require-approval never

aws-up:
	cd aws; source .venv/bin/activate; cdk deploy --require-approval never

clean:
	docker image prune

writedir:
	sudo chmod -R 777 /home/biobuddy/

.PHONY: bup build img app clean writedir
