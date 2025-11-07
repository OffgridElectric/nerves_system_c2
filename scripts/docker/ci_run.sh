#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 [ci|local] [command]"
  echo "  ci:    Run in CI mode (requires CI_GITHUB_USER, CI_GITHUB_TOKEN)"
  echo "  local: Run in local mode"
  echo "Optional: command to execute in the container"
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

COMMON_OPTS="--rm --network host \
  -v $(pwd):/work/nerves_system_c2 \
  -v ${HOME}/.ssh:/home/dev/.ssh:ro \
  -u $(id -u):$(id -g)"

MODE="$1"
shift
CMD="${*:-bash}"

if [[ "${MODE}" == "ci" ]]; then
  if [[ -z "${CI_GITHUB_USER:-}" || -z "${CI_GITHUB_TOKEN:-}" ]]; then
    echo "Error: CI_GITHUB_USER and CI_GITHUB_TOKEN must be set in CI mode."
    exit 2
  fi
  docker run ${COMMON_OPTS} \
    -e CI_GITHUB_USER \
    -e CI_GITHUB_TOKEN \
    c2_dev \
    bash -lc "${CMD}"
elif [[ "${MODE}" == "local" ]]; then
  docker run ${COMMON_OPTS} \
    c2_dev \
    bash -c "bash /work/nerves_system_c2/scripts/c2_build_local.sh"
else
  echo "Error: Unknown mode '${MODE}'. Use 'ci' or 'local'."
  usage
fi

