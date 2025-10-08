#!/bin/bash

docker run --rm \
  --network host \
  -v $(pwd):/work/nerves_system_c2 \
  -v ~/.ssh:/home/dev/.ssh:ro \
  -u $(id -u):$(id -g) \
  -e CI_GITHUB_USER \
  -e CI_GITHUB_TOKEN \
  c2_dev \
  bash -lc "$1"
