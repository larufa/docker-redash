# docker-redash

.PHONY: help setup up clean
.DEFAULT_GOAL: help

help: # see the end of file


override POSTGRES_DATA_DIR := $(shell pwd)/postgres-data
override MYSQL_DATA_DIR    := $(shell pwd)/mysql-data

NGINX_VERSION  := latest
MYSQL_VERSION  := 5.7
REDASH_VERSION := latest

NGINX_CONTAINER_NAME         := nginx
MYSQL_CONTAINER_NAME         := mysql
POSTGRES_CONTAINER_NAME      := postgres
REDASH_CONTAINER_NAME        := redash
REDASH_WORKER_CONTAINER_NAME := worker
REDIS_CONTAINER_NAME         := redis

PORT := 8080

MYSQL_ROOT_PASSWORD := redash
MYSQL_DATABASE      := redash
MYSQL_USER          := redash
MYSQL_PASSWORD      := redash

REDASH_ADMIN_PASSWORD := redash
REDASH_ORG_NAME       := treasure
REDASH_COOKIE_SECRET  := $(shell pwgen 32 -1)
REDASH_WOKERS_COUNT   := 2

BIN_DIR                := $(shell pwd)/bin
DOCKER_COMPOSE_YAML    := docker-compose.yml
DOCKER_CMD             := $(shell which docker)
DOCKER_COMPOSE         := $(shell pwd)/bin/docker-compose
DOCKER_COMPOSE_CMD     := $(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_YAML)
DOCKER_COMPOSE_VERSION := 1.14.0

NO_OPTION_COMMANDS                := pull stop restart
DOCKER_COMPOSE_NO_OPTION_COMMANDS := $(addprefix docker/,$(NO_OPTION_COMMANDS))

COMMAND := ls -l
TARGET  :=


.PHONY: install setup up clean stop rm clean reset reset/* debug/*

install: $(DOCKER_COMPOSE) $(DOCKER_COMPOSE_YAML) docker/pull ##@prepare install docker-compose and generate docker-compose.yml
setup : clean redash_database/restore ##@prepare setup redash_database(postgres)

up: $(DOCKER_COMPOSE_YAML) docker/up ##@basic up redash and mysql containers
stop: docker/stop ##@basic stop containers
rm: docker/rm ##@basic remove containers
clean: stop rm ##@basic stop + rm

reset/redash: redash_database/clean redash_database/restore ##@reset reset redash_database(postgres) data
reset/mysql: mysql/clean ##@reset reset mysql data
	$(MAKE) docker/restart TARGET=$(MYSQL_CONTAINER_NAME)
reset: redash_database/clean mysql/clean setup ##@reset reset_redash + reset_mysql

debug/%: ##@debug debug containers ( make debug/[CONTAINER_NAME] )
	-$(DOCKER_COMPOSE_CMD) exec $* bash

exec/%: ##@debug debug containers ( make exec/[CONTAINER_NAME] COMMAND="command" )
	-$(DOCKER_COMPOSE_CMD) exec $* $(COMMAND)

.PHONY: docker/*

docker/rm:
	$(DOCKER_COMPOSE_CMD) rm -f
	
docker/up:
	$(DOCKER_COMPOSE_CMD) up $(TARGET)

$(DOCKER_COMPOSE_NO_OPTION_COMMANDS):
	$(DOCKER_COMPOSE_CMD) $(notdir $@) $(TARGET)

$(DOCKER_COMPOSE_YAML): $(DOCKER_COMPOSE_YAML).erb Makefile $(DOCKER_COMPOSE)
	NGINX_VERSION=$(NGINX_VERSION) MYSQL_VERSION=$(MYSQL_VERSION) REDASH_VERSION=$(REDASH_VERSION) \
	NGINX_CONTAINER_NAME=$(NGINX_CONTAINER_NAME) MYSQL_CONTAINER_NAME=$(MYSQL_CONTAINER_NAME) POSTGRES_CONTAINER_NAME=$(POSTGRES_CONTAINER_NAME) \
	REDASH_CONTAINER_NAME=$(REDASH_CONTAINER_NAME) REDASH_WORKER_CONTAINER_NAME=$(REDASH_WORKER_CONTAINER_NAME) REDIS_CONTAINER_NAME=$(REDIS_CONTAINER_NAME) \
	MYSQL_ROOT_PASSWORD=$(MYSQL_ROOT_PASSWORD) MYSQL_DATABASE=$(MYSQL_DATABASE) MYSQL_USER=$(MYSQL_USER) MYSQL_PASSWORD=$(MYSQL_PASSWORD) \
	REDASH_COOKIE_SECRET=$(REDASH_COOKIE_SECRET) REDASH_WOKERS_COUNT=$(REDASH_WOKERS_COUNT) PORT=$(PORT) \
	erb $< >$@

$(DOCKER_COMPOSE): $(BIN_DIR)
	curl -L https://github.com/docker/compose/releases/download/1.14.0/docker-compose-$(shell uname -s)-$(shell uname -m) > $@
	chmod +x $@
	$@ version

$(BIN_DIR):
	mkdir $@
	

.PHONY: redash_database/*

redash_database/clean:
	rm -rf $(POSTGRES_DATA_DIR)

redash_database/setup: redash_database/up # If you wanted to initialize redash (unused target)
	$(DOCKER_COMPOSE_CMD) run --rm $(REDASH_CONTAINER_NAME) create_db
	ls $(POSTGRES_DATA_DIR)

redash_database/restore: redash_database/up $(POSTGRES_DATA_DIR)/redash_base.dump
	$(DOCKER_COMPOSE_CMD) exec $(POSTGRES_CONTAINER_NAME) su -l postgres -c "psql -f /var/lib/postgresql/data/redash_base.dump"

redash_database/up:
	$(DOCKER_COMPOSE_CMD) up -d $(POSTGRES_CONTAINER_NAME) && until ($(DOCKER_CMD) ps | grep $(POSTGRES_CONTAINER_NAME) | grep healthy) do sleep 1; done

$(POSTGRES_DATA_DIR)/redash_base.dump: $(POSTGRES_DATA_DIR)
	cp $(notdir $@) $<

$(POSTGRES_DATA_DIR):
	mkdir $@


.PHONY: mysql/*

mysql/clean:
	rm -rf $(MYSQL_DATA_DIR)

$(MYSQL_DATA_DIR):
	mkdir $@


# And add help text after each target name starting with '##'
# A category can be added with @category
help: green       = $(shell tput -Txterm setaf 2)
help: white       = $(shell tput -Txterm setaf 7)
help: yellow      = $(shell tput -Txterm setaf 3)
help: color_reset = $(shell tput -Txterm sgr0)
help: help_fun = \
	%help; \
	while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-zA-Z\-\_\.\%\/]+)\s*:.*\#\#(?:@([0-9a-zA-Z\-\_\.]+))?\s(.*)$$/ }; \
	print "usage: make [target]\n\n"; \
	for (sort keys %help) { \
	print "${white}$$_:${color_reset}\n"; \
	for (@{$$help{$$_}}) { \
	$$sep = " " x (22 - length $$_->[0]); \
	print "  ${yellow}$$_->[0]${color_reset}$$sep${green}$$_->[1]${color_reset}\n"; \
}; \
	print "\n"; }
help:
	@perl -e '$(help_fun)' $(MAKEFILE_LIST)

# Override help target
# http://savannah.gnu.org/bugs/?36106
ifeq ("$(shell make -v | head -n1 | awk '{print $$3}')", "3.82")
$(warning "You are using GNU Make 3.82, this version has bugs.")

help:
	@grep "##@" $(MAKEFILE_LIST) | grep -v grep
endif
