#!/bin/bash
set -euo pipefail
set -x

# -----------------------
# Usage Help
# -----------------------
usage() {
  echo "Usage: $0 [ci|local] [additional command]"
  echo "  ci:    Run in CI mode (requires CI_GITHUB_USER, CI_GITHUB_TOKEN)"
  echo "  local: Run in local mode"
  echo "Optional: pass command to execute after build"
  exit 1
}

if [[ $# -lt 1 || ($1 != "ci" && $1 != "local") ]]; then
  usage
fi

MODE="$1"
shift
EXTRA_CMD="${*:-}"

# -----------------------------
# Set environment for C2 firmware
# -----------------------------
set_artifact_env() {
    export MIX_TARGET=c2
    export MIX_ENV=prod
    echo "Environment set: MIX_TARGET=$MIX_TARGET, MIX_ENV=$MIX_ENV"

    if [[ "$MODE" == "ci" ]]; then
      if [[ -z "${CI_GITHUB_USER:-}" || -z "${CI_GITHUB_TOKEN:-}" ]]; then
        echo "Error: CI_GITHUB_USER and CI_GITHUB_TOKEN required for CI mode."
        exit 2
      fi
      export CI_GITHUB_USER="${CI_GITHUB_USER}"
      export CI_GITHUB_TOKEN="${CI_GITHUB_TOKEN}"
      git config --global url."https://${CI_GITHUB_USER}:${CI_GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
    fi
}

# -----------------------------
# Build firmware and artifacts
# -----------------------------
build() {
    set_artifact_env

    # Determine workspace from current folder
    WS=/work/nerves_system_c2

    if [[ ! -d "$WS" ]]; then
      echo "Error: Workspace $WS does not exist"
      exit 1
    fi
    #check if asdf.sh is readable
  # CI: source toolchains if needed
    if [[ "$MODE" == "ci" ]]; then
      if [ -r $HOME/.asdf/asdf.sh ]; then
        . $HOME/.asdf/asdf.sh
      else
         echo "ERROR: $HOME/.asdf/asdf.sh is not readable"
         ls -l $HOME/.asdf/asdf.sh
         exit 1
      fi
      [ -r $HOME/.asdf/completions/asdf.bash ] && . $HOME/.asdf/completions/asdf.bash
    fi

    # ------------------------------------------------------------------
    # 2.  Install deps & build firmware
    # ------------------------------------------------------------------
    echo "==> Installing dependencies for main workspace"
    cd $WS
    mix deps.get
    
    # -------------------------
    # Build firmware
    # -------------------------
    echo "==> Building firmware"
    cd $WS/test_c2
    mix deps.get
    mix firmware


    VERSION=$(cat "$WS/VERSION" | tr -d '[:space:]')

    # Handle Buildroot/system artifact for CI only
    if [[ "$MODE" == "ci" ]]; then
      ARTIFACT_TARBALL=$(find "$HOME/.nerves/artifacts" -type f \
        -name "nerves_system_c2-portable-${VERSION}-*.tar.gz" \
	| sort | tail -n 1)

      if [ ! -d "$ARTIFACT_TARBALL" ]; then
        echo "==> Artifact missing – building Buildroot/Linux system"
	export NERVES_SYSTEM_CACHE=none

	"$WS/test_c2/deps/nerves_system_br/create-build.sh" \
		"$WS/test_c2/deps/nerves_system_bbb/nerves_defconfig" \
		"$WS/.nerves/artifacts/nerves_system_c2-portable-${VERSION}" \
		>/dev/null

	cd "$WS/.nerves/artifacts/nerves_system_c2-portable-${VERSION}"
	make -j"$(nproc)"
      else
        echo "==> Artifact already exists – skipping system build"
      fi
    fi

        
    # -------------------------
    # Generate Nerves artifacts
    # -------------------------
    echo "==> Generating artifacts"
    cd $WS
    mix nerves.artifact
    
    ARTIFACT_TARBALL=$(find ".nerves/artifacts" -type f \
	-name "nerves_system_c2-portable-${VERSION}-*.tar.gz" \
	| sort | tail -n 1)

    # -------------------------
    # Copy firmware to artifacts folder
    # -------------------------
    BUILD_FW_PATH="test_c2/_build/c2_prod/nerves/images"
    ARTIFACTS_DIR="$WS/artifacts"
    mkdir -p "$ARTIFACTS_DIR"

    if [ -d "$BUILD_FW_PATH" ]; then
        echo "==> Copying firmware files to $WS/artifacts"
        cp "$BUILD_FW_PATH"/*.fw "$ARTIFACTS_DIR/"
        echo "Firmware copied to $WS/artifacts"
    else
        echo "Error: firmware build folder not found: $BUILD_FW_PATH"
        exit 1
    fi

    # system tarball
    if [ -f "$ARTIFACT_TARBALL" ]; then
        echo "==> Copying artefact tarball: $(basename "$ARTIFACT_TARBALL")"
        cp "$ARTIFACT_TARBALL" "$ARTIFACTS_DIR/"
    else
        echo "Warning: No matching artefact tarball found for version $VERSION"
    fi

    echo "==> Build complete. All artefacts in: $ARTIFACTS_DIR"
}

# -----------------------
# Main
# -----------------------
build

if [[ -n "$EXTRA_CMD" ]]; then
  echo "Executing additional command: $EXTRA_CMD"
  eval "$EXTRA_CMD"
fi
