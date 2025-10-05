#!/bin/bash

docker run --rm \
  --network host \
  -v $(pwd):/work/nerves_system_c2 \
  -v ~/.ssh:/home/dev/.ssh:ro \
  -u $(id -u):$(id -g) \
  c2_dev \
  bash -l -c "$1"
