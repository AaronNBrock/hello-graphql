# Most up-to-date version can be found at:
# https://github.com/AaronNBrock/docker-makefile


# ==== CONFIG ====
# Docker registry or dockerhub username
DOCKER_REGISTRY := aaronnbrock

PROJECT_NAME := hello-graphql


# ==== CONFIG (advanced) ====

VERSION := $(shell git describe --always --dirty --match "v[0-9]*")
VERSION := $(VERSION:v%=%) # Remove the 'v' at the beginning

DOCKER_TAG := $(DOCKER_REGISTRY)/$(PROJECT_NAME)
DOCKER_TAG_VERSION := $(DOCKER_TAG):$(VERSION) 


# ==== VERSION ====

# if version doesn't have a '-'
ifeq ($(findstring -,$(VERSION)),)
# tag docker with "latest"
DOCKER_TAG_LATEST := $(DOCKER_TAG):latest
# else
else
# tag docker with "edge"
DOCKER_TAG_LATEST := $(DOCKER_TAG):edge
endif


# ==== REGISTRY ====

# Check if DOCKER_REGISTRY is curl-able
# (removes everything after ':' first)
ifeq ($(shell curl -i --silent ${DOCKER_REGISTRY} &> /dev/null ; echo $$?),0)
# DOCKER_REGISTRY is pingable, treat as registry
define LOGIN_FAILED_MESSAGE
*****************************************************************
Unable to login to docker registry, you can login manually via:

    docker login $(DOCKER_REGISTRY)

or by setting DOCKER_USERNAME & DOCKER_PASSWORD and trying again.
*****************************************************************
endef
export LOGIN_FAILED_MESSAGE
else
# DOCKER_REGISTRY is a username, so use docker hub
DOCKER_USERNAME := $(DOCKER_REGISTRY)
DOCKER_REGISTRY := https://index.docker.io/v1/

define LOGIN_FAILED_MESSAGE
*****************************************************************
Unable to login to docker hub, you can login manually via:

    docker login --username $(DOCKER_USERNAME)

or by setting DOCKER_PASSWORD and trying again.
*****************************************************************
endef
export LOGIN_FAILED_MESSAGE
endif


# ==== MESSAGES ====

define DIRTY_WORKING_DIR_MESSAGE
***************************************************
Error: Can't deploy with a dirty working directory.
***************************************************
endef
export DIRTY_WORKING_DIR_MESSAGE

define VERSION_MESSAGE
Version: $(VERSION)

Docker tags: 
$(PROJECT_NAME)
$(DOCKER_TAG_VERSION)
$(DOCKER_TAG_LATEST)


endef
export VERSION_MESSAGE


# ==== RECIPES THAT AREN'T TO BE TOUCHED ====

check-deploy:
ifneq ($(findstring -dirty,$(VERSION)),)
	@echo "$$DIRTY_WORKING_DIR_MESSAGE"
	@exit 1
else
	@echo "Ready for deployment"
endif

login:

# Check if auth exists in docker config
ifneq ($(findstring auth,$(shell cat ~/.docker/config.json | jq '.auths["$(DOCKER_REGISTRY)"]')),)
	@echo "Already Logged in!"
else
	@echo "Logging into docker registry..."
# Check if username exists
ifndef DOCKER_USERNAME
	@echo "$$LOGIN_FAILED_MESSAGE" 
	@exit 1
endif
# Check if password exists
ifndef DOCKER_PASSWORD
	@echo "$$LOGIN_FAILED_MESSAGE" 
	@exit 1
endif
# Login to docker
	@echo $(DOCKER_PASSWORD) | docker login --username $(DOCKER_USERNAME) --password-stdin $(DOCKER_REGISTRY)
endif

build:
	docker build -t $(DOCKER_TAG_VERSION) -t $(DOCKER_TAG_LATEST) -t $(PROJECT_NAME)  .

push: check-deploy login build
	docker push $(DOCKER_TAG_LATEST)
	docker push $(DOCKER_TAG_VERSION)

version:
	@printf "$$VERSION_MESSAGE"


# ==== RECIPES ====

run: build
	docker run --rm -p 8080:8080 --network host $(PROJECT_NAME)

run-it: build
	docker run --rm -p 8080:8080 --network host --entrypoint /bin/sh -it $(PROJECT_NAME) 
