docker run --rm -it \
  --network host \
  -v $(pwd):/work/nerves_system_c2 \
  -v ~/.ssh:/home/dev/.ssh:ro \
  c2_dev
