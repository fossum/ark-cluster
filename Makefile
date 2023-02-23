build:
	docker build -f base.Dockerfile . -t r15ch13/arkcluster-base
	docker build -f Dockerfile . -t r15ch13/arkcluster

clean:
	docker image rm r15ch13/arkcluster-base ||:
	docker image rm r15ch13/arkcluster ||:

push:
	docker image push r15ch13/arkcluster-base
	docker image push r15ch13/arkcluster

all: clean build push
