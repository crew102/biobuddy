bup:
	docker-compose down
	docker-compose up -d

build:
	docker-compose build --no-cache
	docker-compose down
	docker-compose up -d

img:
	cd app; docker build -t bb-app . ; cd ..

clean:
	docker image prune

.PHONY: bup build img
