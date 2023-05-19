# use --no-cache to force-rebuild Docker things
DOCKERARGS=

docker:
	@make docker-index
	@make docker-updates

docker-index:
	docker build $(DOCKERAGRS) -t whosonfirst-data-indexing -f Dockerfile.index .

docker-updates:
	docker build $(DOCKERARGS) -t whosonfirst-data-indexing-updates -f Dockerfile.updates .
