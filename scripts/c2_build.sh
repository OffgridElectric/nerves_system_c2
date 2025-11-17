#!/bin/bash
set -euo pipefail
set -x

MODE="$1"
shift
EXTRA_CMD="${*:-}"

# -----------------------------
# Set environment for C2 firmware
# -----------------------------
set_artifact_env()
{
    export MIX_TARGET=c2
    export MIX_ENV=prod
    echo "Environment set: MIX_TARGET=$MIX_TARGET, MIX_ENV=$MIX_ENV"

    if [[ -z "${CI_GITHUB_USER:-}" || -z "${CI_GITHUB_TOKEN:-}" ]]; then
	    echo "Error: CI_GITHUB_USER and CI_GITHUB_TOKEN required for CI mode."
	    exit 2
    fi
    export CI_GITHUB_USER="${CI_GITHUB_USER}"
    export CI_GITHUB_TOKEN="${CI_GITHUB_TOKEN}"
    git config --global url."https://${CI_GITHUB_USER}:${CI_GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
}

# -----------------------------
# Build firmware and artifacts
# -----------------------------
build()
{
    set_artifact_env

    # Determine workspace from current folder
    WS=/work/nerves_system_c2

    if [[ ! -d "$WS" ]]; then
      echo "Error: Workspace $WS does not exist"
      exit 1
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
