IMAGE=pi-k8s-fitches-speech-api
VERSION=0.2
ACCOUNT=gaf3
NAMESPACE=fitches
VOLUMES=-v ${PWD}/openapi/:/opt/pi-k8s/openapi/ -v ${PWD}/settings.json.example/:/etc/pi-k8s/settings.json -v ${PWD}/lib/:/opt/pi-k8s/lib/ -v ${PWD}/test/:/opt/pi-k8s/test/ -v ${PWD}/bin/:/opt/pi-k8s/bin/
PORT=6589

.PHONY: pull build shell test run push create update delete

pull:
	docker pull $(ACCOUNT)/$(IMAGE)

build:
	docker build . -t $(ACCOUNT)/$(IMAGE):$(VERSION)

shell:
	docker run -it $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) sh

test:
	docker run -it $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(VERSION) sh -c "coverage run -m unittest discover -v test && coverage report -m --include lib/*.py"

run:
	docker run -it --rm -p $(PORT):$(PORT) -h $(IMAGE) $(ACCOUNT)/$(IMAGE):$(VERSION)

push: build
	docker push $(ACCOUNT)/$(IMAGE):$(VERSION)

config:
	kubectl create configmap -n fitches speech-api --dry-run --from-file=settings.json -o yaml | kubectl apply -f -

create:
	kubectl create -f k8s/pi-k8s.yaml

update:
	kubectl replace -f k8s/pi-k8s.yaml

delete:
	kubectl delete -f k8s/pi-k8s.yaml