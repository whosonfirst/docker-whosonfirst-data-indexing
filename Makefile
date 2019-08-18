docker:
	docker build -t whosonfirst-data-indexing .

docker-force:
	docker build --no-cache -t whosonfirst-data-indexing .
