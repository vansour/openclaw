include versions/openclaw.env

IMAGE_NAME ?= ghcr.io/vansour/openclaw
IMAGE_TAG ?= $(OPENCLAW_VERSION)-$(OPENCLAW_IMAGE_REVISION)
IMAGE_REF ?= $(IMAGE_NAME):$(IMAGE_TAG)
EXTRA_TAGS ?=
PLATFORMS ?= linux/amd64,linux/arm64
CONTEXT_DIR := .cache/contexts/openclaw-$(OPENCLAW_VERSION)
TAG_ARGS := -t $(IMAGE_REF) $(foreach tag,$(EXTRA_TAGS),-t $(IMAGE_NAME):$(tag))

BUILD_ARGS := \
	--build-arg OPENCLAW_NODE_IMAGE=$(OPENCLAW_NODE_IMAGE) \
	--build-arg OPENCLAW_NODE_SLIM_IMAGE=$(OPENCLAW_NODE_SLIM_IMAGE) \
	--build-arg OPENCLAW_PACKAGE_MANAGER=$(OPENCLAW_PACKAGE_MANAGER) \
	--build-arg OPENCLAW_BUILD_UI=$(OPENCLAW_BUILD_UI) \
	--build-arg OPENCLAW_INSTALL_BROWSER=$(OPENCLAW_INSTALL_BROWSER) \
	--build-arg OPENCLAW_INSTALL_DOCKER_CLI=$(OPENCLAW_INSTALL_DOCKER_CLI) \
	--build-arg OPENCLAW_DOCKER_APT_UPGRADE=$(OPENCLAW_DOCKER_APT_UPGRADE) \
	--build-arg OPENCLAW_DOCKER_APT_PACKAGES=$(OPENCLAW_DOCKER_APT_PACKAGES)

.PHONY: prepare build smoke publish print-version

print-version:
	@printf '%s\n' $(OPENCLAW_VERSION)

prepare:
	@./scripts/prepare-context.sh

build: prepare
	docker buildx build --load $(TAG_ARGS) -f docker/Dockerfile $(BUILD_ARGS) $(CONTEXT_DIR)

smoke:
	./scripts/smoke-test.sh $(IMAGE_REF)

publish: prepare
	docker buildx build --platform $(PLATFORMS) --push $(TAG_ARGS) -f docker/Dockerfile $(BUILD_ARGS) $(CONTEXT_DIR)
