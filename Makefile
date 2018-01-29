VERSION?=v0.0.1
IMAGE?=dotmeshio/docs
BUILDER_IMAGE=$(IMAGE)-builder

.PHONY: images
images:
	docker build -t $(BUILDER_IMAGE):$(VERSION) .
	docker tag $(BUILDER_IMAGE):$(VERSION) $(BUILDER_IMAGE):latest

.PHONY: design.build
design.build:
	docker run --rm \
		-v $(PWD)/design:/app/design \
		-v /app/design/node_modules \
		-w /app/design \
		$(BUILDER_IMAGE) gulp build

.PHONY: design.icons
design.icons:
	docker run -ti --rm \
		-v $(PWD)/design:/app/design \
		-v /app/design/node_modules \
		-w /app/design \
		$(BUILDER_IMAGE) gulp icons:build

.PHONY: design.watch
design.watch:
	docker run -ti --rm \
	  --name docs-design \
		-v $(PWD)/design:/app/design \
		-v /app/design/node_modules \
		-v /app/design/public \
		-p 3000:3000 \
		-w /app/design/public \
		$(BUILDER_IMAGE) gulp serve

.PHONY: design.stop
design.stop:
	docker rm -f docs-design

.PHONY: design.url
design.url:
	@bash scripts/geturl.sh

.PHONY: design.copy
design.copy:
	rm -rf hugo/static/{assets,css}
	mkdir -p hugo/static
	cp -r design/public/{assets,css} hugo/static

.PHONY: hugo.build
hugo.build: design.build design.copy
	docker run --rm \
		-v $(PWD)/hugo:/app/hugo \
		-e NAMESPACE \
		-w /app/hugo \
		$(BUILDER_IMAGE) hugo -v

.PHONY: hugo.watch
hugo.watch: design.build design.copy
	docker run -ti --rm \
		--name docs-hugo \
		-p 1313:1313 \
		-e NAMESPACE \
		-v $(PWD)/hugo:/app/hugo \
		-w /app/hugo \
		$(BUILDER_IMAGE) hugo \
			server \
			--buildDrafts \
			--bind=0.0.0.0 \
			-v

.PHONY: release.build
release.build:
	@echo "Running the hugo build"
	docker run \
		--name docs-builder-$(ENV_NAME)-$(VERSION) \
		-e NAMESPACE \
		-w /app/hugo \
		$(BUILDER_IMAGE):latest hugo -v
	@echo "Copy built folder"
	docker cp docs-builder-$(ENV_NAME)-$(VERSION):/app/hugo/public ./hugo/public
	@echo "Build nginx image"
	docker build -t $(IMAGE):$(VERSION) -f Dockerfile.nginx .
	docker tag $(IMAGE):$(VERSION) $(IMAGE):latest
	@echo "Remove built folder"
	rm -rf ./hugo/public
