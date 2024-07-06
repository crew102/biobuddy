bup:
	docker compose down
	docker compose up -d

build:
	docker compose build --no-cache
	docker compose down
	docker compose up -d

img-local:
	Rscript scripts/lockfile-write.R
	docker build -t bb-app -f app/Dockerfile .

img-deploy:
	docker build -t bb-app -f app/Dockerfile .

app:
	docker run --rm -it -p 3838:3838 -v `pwd`/secrets.txt:/root/.Renviron -v `pwd`/app:/home/biobuddy/app -v `pwd`/R:/home/biobuddy/R bb-app

clean:
	docker image prune

.PHONY: bup build img-local img-deploy app clean
