GOMOD=vendor

cli:
	go build -mod $(GOMOD) -ldflags="-s -w" -o bin/update cmd/update/main.go

lambda:
	if test -f main; then rm -f main; fi
	if test -f update.zip; then rm -f update.zip; fi
	GOOS=linux go build -mod $(GOMOD) -ldflags="-s -w" -o main cmd/update/main.go
	zip update.zip main
	rm -f main
