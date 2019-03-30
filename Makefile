all: run

run: build
	bin/hekaya

build: build-ui build-server

build-ui:
	cd ui && make build

build-server:
	mkdir -p bin
	go build -o bin/hekaya

.PHONY = run build build-ui build-server
