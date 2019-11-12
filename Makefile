.PHONY: docker-image

docker-image:
	docker build -t yoff/cbs:latest .