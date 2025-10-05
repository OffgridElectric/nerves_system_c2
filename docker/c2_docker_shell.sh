#!/bin/bash
docker run --rm \
  --network host \
  -v $(pwd):/work/nerves_system_c2 \
  -v ~/.ssh:/home/dev/.ssh:ro \
  c2_dev \
  bash -c "$1"
