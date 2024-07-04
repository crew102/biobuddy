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
	docker run --rm -it -p 3838:3838 -v `pwd`/secrets.txt:/root/.Renviron bb-app

clean:
	docker image prune

.PHONY: bup build img clean app
