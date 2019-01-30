# Most up-to-date version & useage instructions can be found at:
# https://github.com/AaronNBrock/docker-makefile


# ==== CONFIG ====

# Leave empty for docker hub
DOCKER_REGISTRY :=

# Username used in the docker tag & to log into registry if USERNAME isn't defined below.
DOCKER_USERNAME := aaronnbrock

# Name used in docker tags.
PROJECT_NAME := hello-graphql

# ==== RECIPES ====

run: build start-db
	docker run --rm --network host $(PROJECT_NAME)

run-it: build start-db
	docker run --rm --network host --entrypoint /bin/sh -it $(PROJECT_NAME) 

start-db:
	./testdb.sh --start

stop-db:
	./testdb.sh --stop

reset-db:
	./startdb.sh --reset


# ==== REGISTRY LOGIN CONFIG ====

# Username used to login to the registry.
# (default: DOCKER_USERNAME defined above)
# USERNAME := 

# Password used to login to the registry.  
# (**WARNING**: It's illadviced to store password here as plaintext. Instead, set this environment variable at runtime.)
# PASSWORD := 


# ****************************************
# Edit below this line at your own risk
# ****************************************


# ==== VERSION ====

VERSION := $(shell git describe --always --dirty --match "v[0-9]*")
VERSION := $(VERSION:v%=%) # Remove the 'v' at the beginning

# ==== DOCKER TAGS ====

REGISTRY_NO_SLASH := $(DOCKER_REGISTRY:%/=%) # Remove trailing '/' if it's there
TAG := $(REGISTRY_NO_SLASH:%=%/)$(DOCKER_USERNAME:%=%/)$(PROJECT_NAME)
TAG_VERSION := $(TAG):$(VERSION)

# if version doesn't have a '-'
ifeq ($(findstring -,$(VERSION)),)
TAG_LATEST := $(TAG):latest # tag docker with "latest"
else
TAG_LATEST := $(TAG):edge # tag docker with "edge"
endif


# ==== MESSAGES ====
define LOGIN_FAILED_MESSAGE
*****************************************************************
Unable to login to docker registry, you can login manually via:

    docker login $(REGISTRY)

or by setting USERNAME & PASSWORD and trying again.
*****************************************************************
endef
export LOGIN_FAILED_MESSAGE

define DIRTY_WORKING_DIR_MESSAGE
*************************************************
Error: Can't push with a dirty working directory.
*************************************************
endef
export DIRTY_WORKING_DIR_MESSAGE

define VERSION_MESSAGE
Version: $(VERSION)

Docker tags: 
$(PROJECT_NAME)
$(TAG_VERSION)
$(TAG_LATEST)


endef
export VERSION_MESSAGE

# ==== VARIABLE MANAGEMENT ====

REAL_REGISTRY := $(DOCKER_REGISTRY)
ifndef DOCKER_REGISTRY
REAL_REGISTRY := index.docker.io
endif

ifndef USERNAME
ifdef DOCKER_USERNAME
USERNAME := $(DOCKER_USERNAME)
endif
endif

# ==== PRE-BUILT RECIPES ====

check-deploy:
ifneq ($(findstring -dirty,$(VERSION)),)
	@echo "$$DIRTY_WORKING_DIR_MESSAGE"
	@exit 1
else
	@echo "Ready for deployment"
endif

login:

# Check if auth exists in docker config
ifneq ($(findstring $(REAL_REGISTRY),$(shell cat ~/.docker/config.json | jq '.auths')),)
	@echo "Already Logged in!"
else
	@echo "Logging into docker registry..."
# Check if username exists
ifndef USERNAME
	@echo "$$LOGIN_FAILED_MESSAGE" 
	@exit 1
endif
# Check if password exists
ifndef PASSWORD
	@echo "$$LOGIN_FAILED_MESSAGE" 
	@exit 1
endif
# Login to docker
	@echo $(DOCKER_PASSWORD) | docker login --username $(DOCKER_USERNAME) --password-stdin $(DOCKER_REGISTRY)
endif

build:
	docker build -t $(TAG_VERSION) -t $(TAG_LATEST) -t $(PROJECT_NAME)  .

push: check-deploy login build
	docker push $(TAG_LATEST)
	docker push $(TAG_VERSION)

version:
	@printf "$$VERSION_MESSAGE"