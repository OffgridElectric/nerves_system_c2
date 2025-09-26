docker run --rm -it \
  --network host \
  --cpus="4.0" \
  --memory="5g" \
  -v $(pwd):/work/nerves_system_c2 \
  -v ~/.ssh:/home/dev/.ssh:ro \
  c2_dev
