NAME = byteworks/phalcon4-php73-nginx
TAG = ubuntu-18.04
SHELL = /bin/bash
PHP_VERSION= 7.3
PHALCON_BUILD=mainline # mainline , stable and nightly builds available
ARTIFACTS_IMAGE = byteworks/mkimage:$(TAG)-php-$(PHP_VERSION)

.PHONY: docker-build post-build clean build release push do-push post-push

build:  docker-build post-build

# pre-build:
#	tar -cvf installers.tar installers

post-build: clean

docker-build:
	docker pull $(ARTIFACTS_IMAGE)
	docker create --name extract $(ARTIFACTS_IMAGE)
	docker cp extract:/artifacts ./artifacts
	docker rm -f extract
	docker build \
	    -t $(NAME):$(TAG) \
	    --build-arg PHALCON_BUILD=$(PHALCON_BUILD) \
	    --build-arg PHP_VERSION=$(PHP_VERSION) .

release: build push

push: do-push post-push

do-push:
	docker push $(NAME):$(TAG)

post-push:

clean:
	rm -rf ./artifacts

# vim:ft=make:noet:ci:pi:sts=0:sw=4:ts=4:tw=78:fenc=utf-8:et