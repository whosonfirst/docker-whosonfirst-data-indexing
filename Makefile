geo:
	docker build -f Dockerfile.geo -t whosonfirst-data-geo .

tools:
	docker build -f Dockerfile.tools -t whosonfirst-data-indexing-tools .

docker:
	@make geo
	@make tools
	docker build -t whosonfirst-data-indexing .
