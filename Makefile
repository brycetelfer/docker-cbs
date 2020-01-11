.PHONY: docker-image run docker-image-8.3.0.101 run-8.3.0.101

docker-image:
	docker build -t jeffre/cbs:latest .

docker-image-8.3.0.101:
	docker build -t jeffre/cbs:8.3.0.101 -f Dockerfile-8.3.0.101 .

run:
	docker run -d \
	  -p "80:80" \
	  -p "443:443" \
	  -v "cbs-conf:/cbs/conf" \
	  -v "cbs-download:/cbs/download" \
	  -v "cbs-logs:/cbs/logs" \
	  -v "cbs-system:/cbs/system" \
	  -v "cbs-user:/cbs/user" \
	  jeffre/cbs:latest

run-8.3.0.101:
	docker run -d \
	  -p "80:80" \
	  -p "443:443" \
	  -v "cbs-conf:/cbs/conf" \
	  -v "cbs-download:/cbs/download" \
	  -v "cbs-logs:/cbs/logs" \
	  -v "cbs-system:/cbs/system" \
	  -v "cbs-user:/cbs/user" \
	  jeffre/cbs:8.3.0.101