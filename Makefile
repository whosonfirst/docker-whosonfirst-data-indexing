# use --no-cache to force-rebuild Docker things
DOCKERARGS=--platform=linux/amd

docker:
	@make docker-index

docker-index:
	docker buildx build $(DOCKERAGRS) -t whosonfirst-data-indexing -f Dockerfile.index .
