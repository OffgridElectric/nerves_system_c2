docker run --rm -it \
  -v $(pwd):/work/nerves_system_c2 \
  -v ~/.ssh:/root/.ssh:ro \
  c2_dev