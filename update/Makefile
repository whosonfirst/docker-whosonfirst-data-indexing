GOMOD=$(shell test -f "go.work" && echo "readonly" || echo "vendor")
LDFLAGS=-s -w

cli:
	go build -mod $(GOMOD) -ldflags="$(LDFLAGS)" -o bin/update cmd/update/main.go

lambda:
	@make lambda-update

lambda-update:
	if test -f bootstrap; then rm -f bootstrap; fi
	if test -f update.zip; then rm -f update.zip; fi
	GOARCH=arm64 GOOS=linux go build -mod $(GOMOD) -ldflags="$(LDFLAGS)" -tags lambda.norpc -o bootstrap cmd/update/main.go
	zip update.zip bootstrap
	rm -f bootstrap
