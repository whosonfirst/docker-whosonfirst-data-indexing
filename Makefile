docker:
	docker build -t whosonfirst-data-indexing .

docker-force:
	docker build --no-cache -t whosonfirst-data-indexing .

docker-updates:
	docker build -t whosonfirst-data-indexing-updates -f Dockerfile.updates .
