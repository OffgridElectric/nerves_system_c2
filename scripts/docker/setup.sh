docker build --network=host  --build-arg USER_UID=$(id -u) --build-arg\
    USER_GID=$(id -g) -t "c2_dev"\
    -f ./scripts/docker/Dockerfile.c2 ./scripts/docker
