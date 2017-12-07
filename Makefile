VERSION=v0.0.1
IMAGE=datameshio/docs

.PHONY: images
images:
	docker build -t $(IMAGE):$(VERSION) .
	docker tag $(IMAGE):$(VERSION) $(IMAGE):latest

.PHONY: design.build
design.build:
	docker run -ti --rm \
		-v $(PWD)/design:/app/design \
		-v /app/design/node_modules \
		-w /app/design \
		$(IMAGE) gulp build

.PHONY: design.copy
design.copy:
	rm -rf hugo/static/{assets,css}
	cp -r design/public/{assets,css} hugo/static

.PHONY: hugo.build
hugo.build: design.build design.copy
	docker run -ti --rm \
		-p 1313:1313 \
		-v $(PWD)/hugo:/app/hugo \
		-w /app/hugo \
		$(IMAGE) hugo -v

.PHONY: hugo.watch
hugo.watch: design.build design.copy
	docker run -ti --rm \
		-p 1313:1313 \
		-v $(PWD)/hugo:/app/hugo \
		-w /app/hugo \
		$(IMAGE) hugo \
			server \
			--buildDrafts \
			--bind=0.0.0.0 \
			-v

