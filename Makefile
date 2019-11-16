.PHONY: docker-image run

docker-image:
	docker build -t jeffre/cbs:latest .

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
