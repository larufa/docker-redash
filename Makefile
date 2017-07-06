override POSTGRES_DATA_DIR := $(shell pwd)/postgres-data

DOCKER_COMPOSE := $(shell which docker-compose)
DOCKER_COMPOSE_YAML := docker-compose.yml

NO_OPTION_COMMANDS := pull stop restart
DOCKER_COMPOSE_NO_OPTION_COMMANDS := $(addprefix docker/,$(NO_OPTION_COMMANDS))



help:
	-echo "nothing"

setup : clean clean_redash_database docker/pull setup_redash_database

up: docker/up

clean: docker/stop docker/rm


.PHONY: docker/*

docker/rm:
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_YAML) rm -f
	
docker/up:
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_YAML) up


$(DOCKER_COMPOSE_NO_OPTION_COMMANDS):
	$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_YAML) $(notdir $@)

$(POSTGRES_DATA_DIR):
	mkdir $@

clean_redash_database:
	rm -rf $(POSTGRES_DATA_DIR)

setup_redash_database: $(POSTGRES_DATA_DIR)
	-$(DOCKER_COMPOSE) -f $(DOCKER_COMPOSE_YAML) run --rm server create_db
	@echo "\033[0;32mEven if setup_redash_database target print stacktrace, it's nomally."
	@echo "Please check to see if some files are exist in postgres-data dir.\033[0m"
	ls $(POSTGRES_DATA_DIR)
