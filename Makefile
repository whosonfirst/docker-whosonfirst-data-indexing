# use --no-cache to force-rebuild Docker things
DOCKERARGS=--platform=linux/amd64 --no-cache

docker:
	@make docker-index

docker-index:
	docker buildx build $(DOCKERARGS) -t whosonfirst-data-indexing -f Dockerfile .
