VERSION=v0.0.1
IMAGE=dotmeshio/docs
ADDRESS=$(ifconfig en0 | grep inet | grep broadcast | awk '{print $$2}')

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

.PHONY: design.icons
design.icons:
	docker run -ti --rm \
		-v $(PWD)/design:/app/design \
		-v /app/design/node_modules \
		-w /app/design \
		$(IMAGE) gulp icons:build

.PHONY: design.watch
design.watch:
	docker run -ti --rm \
	  --name docs-design \
		-v $(PWD)/design:/app/design \
		-v /app/design/node_modules \
		-v /app/design/public \
		-p 3000:3000 \
		-w /app/design/public \
		$(IMAGE) gulp serve

.PHONY: design.stop
design.stop:
	docker rm -f docs-design

.PHONY: design.url
design.url:
	@bash scripts/geturl.sh

.PHONY: design.copy
design.copy:
	rm -rf hugo/static/{assets,css}
	cp -r design/public/{assets,css} hugo/static

.PHONY: hugo.build
hugo.build: design.build design.copy
	docker run -ti --rm \
		-v $(PWD)/hugo:/app/hugo \
		-w /app/hugo \
		$(IMAGE) hugo -v

.PHONY: hugo.watch
hugo.watch: design.build design.copy
	docker run -ti --rm \
		--name docs-hugo \
		-p 1313:1313 \
		-v $(PWD)/hugo:/app/hugo \
		-w /app/hugo \
		$(IMAGE) hugo \
			server \
			--buildDrafts \
			--bind=0.0.0.0 \
			-v
