MACHINE=$(shell uname -m)
IMAGE=pi-k8s-fitches-speech-api
VERSION=0.2
TAG="$(VERSION)-$(MACHINE)"
ACCOUNT=gaf3
NAMESPACE=fitches
VOLUMES=-v ${PWD}/openapi/:/opt/pi-k8s/openapi/ -v ${PWD}/settings.json.example/:/etc/pi-k8s/settings.json -v ${PWD}/lib/:/opt/pi-k8s/lib/ -v ${PWD}/test/:/opt/pi-k8s/test/ -v ${PWD}/bin/:/opt/pi-k8s/bin/
PORT=6589

ifeq ($(MACHINE),armv7l)
BASE=resin/raspberry-pi-alpine-python:3.6.1
else
BASE=python:3.6-alpine3.8
endif

.PHONY: build shell test run push config create update delete config-dev create-dev update-dev delete-dev

build:
	docker build . --build-arg BASE=$(BASE) -t $(ACCOUNT)/$(IMAGE):$(TAG)

shell:
	docker run -it $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(TAG) sh

test:
	docker run -it $(VOLUMES) $(ACCOUNT)/$(IMAGE):$(TAG) sh -c "coverage run -m unittest discover -v test && coverage report -m --include lib/*.py"

run:
	docker run -it --rm -p $(PORT):$(PORT) -h $(IMAGE) $(ACCOUNT)/$(IMAGE):$(TAG)

push: build
	docker push $(ACCOUNT)/$(IMAGE):$(TAG)

config:
	kubectl create configmap -n fitches speech-api --dry-run --from-file=settings.json -o yaml | kubectl -n fitches --context=pi-k8s apply -f -

create:
	kubectl --context=pi-k8s create -f k8s/pi-k8s.yaml

update:
	kubectl --context=pi-k8s replace -f k8s/pi-k8s.yaml

delete:
	kubectl --context=pi-k8s delete -f k8s/pi-k8s.yaml

config-dev:
	kubectl create configmap -n fitches speech-api --dry-run --from-file=settings.json -o yaml | kubectl -n fitches --context=minikube apply -f -

create-dev:
	kubectl --context=minikube create -f k8s/minikube.yaml

update-dev:
	kubectl --context=minikube replace -f k8s/minikube.yaml

delete-dev:
	kubectl --context=minikube delete -f k8s/minikube.yaml