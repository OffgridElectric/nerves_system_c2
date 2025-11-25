#!/bin/bash
set -euo pipefail

COMMON_OPTS="--rm --network host \
  -v $(pwd):/work/nerves_system_c2 \
  -v ${HOME}/.ssh:/home/dev/.ssh:ro \
  -u $(id -u):$(id -g)"

CMD="${*:-bash}"

require_ci_vars() 
{
  if [[ -z "${CI_GITHUB_USER:-}" || -z "${CI_GITHUB_TOKEN:-}" ]]; then
    echo "Error: CI_GITHUB_USER and CI_GITHUB_TOKEN must be set in CI mode." >&2
    exit 2
  fi
}

require_ci_vars

docker run ${COMMON_OPTS} \
  -e CI_GITHUB_USER="${CI_GITHUB_USER}" \
  -e CI_GITHUB_TOKEN="${CI_GITHUB_TOKEN}" \
  c2_dev \
  bash -lc "${CMD}" || { echo "Error: Docker run command failed."; exit 3; }

