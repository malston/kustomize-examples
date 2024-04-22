MYGOBIN = $(shell go env GOBIN)
ifeq ($(MYGOBIN),)
MYGOBIN = $(shell go env GOPATH)/bin
endif
export PATH := $(MYGOBIN):$(PATH)

.PHONY: lint test fix fmt tidy vet build

lint: $(MYGOBIN)/golangci-lint
	$(MYGOBIN)/golangci-lint cache clean # Workaround for https://github.com/golangci/golangci-lint/issues/3228
	$(MYGOBIN)/golangci-lint \
	  -c $$KUSTOMIZE_ROOT/.golangci.yml \
	  --path-prefix $(shell pwd | sed -E 's|(.*\/kustomize)/(.*)|\2|') \
	  run ./...

test:
	go test -v -timeout 45m -cover ./...

fix:
	go fix ./...

fmt:
	go fmt ./...

tidy:
	go mod tidy

vet:
	go vet ./...

build:
	go build -buildmode plugin -o SecretsFromDatabase.so
