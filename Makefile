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
	 	--entrypoint bash \
		$(IMAGE)
