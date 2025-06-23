#!/bin/bash

set -e
set -x

if [[ $@ =~ (.*(clean)){1} ]]; then
  docker stop $(docker ps -aq)
fi

docker_compose() {
  if docker-compose version >/dev/null 2>&1; then
    docker-compose $@
  else
    docker compose $@
  fi
}

if [[ $@ =~ (.*(pull)){1} ]]; then
  if [[ $@ =~ (.*(no-cache)){1} ]]; then
    docker_compose pull --no-cache
  else
    docker_compose pull
  fi
fi

if [[ $@ =~ (.*(dev)){1} ]]; then
  docker_compose up
else
  docker_compose up -d
fi
