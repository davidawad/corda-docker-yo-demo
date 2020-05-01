
PWD ?= pwd_unknown
PROJECT_NAME = $(notdir $(PWD))

IMAGE_NAME=PWD

# run the basic corda docker image
run: clean
	docker build -t ${PROJECT_NAME} .
	docker run ${PROJECT_NAME}

# takes a port number as an argument
CORDANODEPORT=10001

ssh:
	# ssh into the running image
	# docker exec -it (docker ps -q -f ancestor=(basename (pwd))) bash
	# ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no user@localhost -p $(CORDANODEPORT)

stop:
	# docker kill (docker ps -q -f ancestor=(basename (pwd)))

cluster:
	# TODO generate the docker-compose file
	# run the docker cluster
	docker-compose up

	# display command to ssh into one of the nodes


rebuild: clean
	# force a rebuild by passing --no-cache
	docker-compose build --no-cache $(SERVICE_TARGET)

service:
	# run as a (background) service
	docker-compose -p $(PROJECT_NAME)_$(HOST_UID) up -d $(SERVICE_TARGET)

login: service
	# run as a service and attach to it
	docker exec -it $(PROJECT_NAME)_$(HOST_UID) sh

build:
	# build the nodes and generate the files within this project's folders
	./gradlew deployNodes
	# only build the container. Note, docker does this also if you apply other targets.
	docker-compose build $(SERVICE_TARGET)

clean:
	# remove created images
	@docker-compose -p $(PROJECT_NAME)_$(HOST_UID) down --remove-orphans --rmi all 2>/dev/null \
	&& echo 'Image(s) for "$(PROJECT_NAME):$(HOST_USER)" removed.' \
	|| echo 'Image(s) for "$(PROJECT_NAME):$(HOST_USER)" already removed.'

prune:
	# clean all that is not actively used
	docker system prune -af



# Inspired by the makefile shared here : https://itnext.io/docker-makefile-x-ops-sharing-infra-as-code-parts-ea6fa0d22946
