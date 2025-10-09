#!/bin/bash
set -e  # exit on error
set -x  # print commands as they run

# -----------------------------
# Set environment for C2 firmware
# -----------------------------
set_artifact_env() {
    export MIX_TARGET=c2
    export MIX_ENV=prod
    echo "Environment set: MIX_TARGET=$MIX_TARGET, MIX_ENV=$MIX_ENV"
    export CI_GITHUB_USER="${CI_GITHUB_USER}"
    export CI_GITHUB_TOKEN="${CI_GITHUB_TOKEN}"
    git config --global url."https://${CI_GITHUB_USER}:${CI_GITHUB_TOKEN}@github.com/".insteadOf "git@github.com:"
}

# -----------------------------
# Build firmware and artifacts
# -----------------------------
build() {
    set_artifact_env


    #check if asdf.sh is readable
    if [ -r /home/dev/.asdf/asdf.sh ]; then
        . /home/dev/.asdf/asdf.sh
    else
        echo "ERROR: /home/dev/.asdf/asdf.sh is not readable"
        ls -l /home/dev/.asdf/asdf.sh
        exit 1
    fi

    if [ -r /home/dev/.asdf/completions/asdf.bash ]; then
        . /home/dev/.asdf/completions/asdf.bash
    fi

    # Determine workspace from current folder
    WS=/work/nerves_system_c2
    echo "Workspace set to $WS"

    # Ensure artifacts folder exists
    mkdir -p "$WS/artifacts"


    # force a clean system rebuild
    echo "==> Cleaning & rebuilding nerves_system_c2"
    export NERVES_SYSTEM_CACHE=none        # ignore any cached system
    cd "$WS"
    mix deps.clean -all      # remove pre-built files

    # -------------------------
    # Install dependencies
    # -------------------------

    echo "==> Installing dependencies for main workspace"
    cd $WS
    mix deps.get

    echo "==> Installing dependencies for test_c2"
    cd $WS/test_c2
    mix deps.get

    # -------------------------
    # Build firmware
    # -------------------------
    echo "==> Building firmware"
    mix firmware

    # -------------------------
    # Generate Nerves artifacts
    # -------------------------
    echo "==> Generating artifacts"
    cd $WS
    mix nerves.artifact

    # -------------------------
    # Copy firmware to artifacts folder
    # -------------------------
    BUILD_FW_PATH="test_c2/_build/c2_prod/nerves/images"
    if [ -d "$BUILD_FW_PATH" ]; then
        echo "==> Copying firmware files to $WS/artifacts"
        cp "$BUILD_FW_PATH"/*.fw "$WS/artifacts/"
        echo "Firmware copied to $WS/artifacts"
    else
        echo "Error: firmware build folder not found: $BUILD_FW_PATH"
        exit 1
    fi

    # -------------------------
    # Copy system artifact tarball (based on VERSION)
    # -------------------------
    VERSION=$(cat VERSION | tr -d '[:space:]')
    ARTIFACT_DIR=".nerves/artifacts"
    LATEST_TAR=$(find "$ARTIFACT_DIR" -type f -name "nerves_system_c2-portable-${VERSION}-*.tar.gz" | sort | tail -n 1)

    if [ -f "$LATEST_TAR" ]; then
	    echo "==> Copying artifact tarball: $(basename "$LATEST_TAR")"
	    cp "$LATEST_TAR" "$WS/artifacts/"
    else
	    echo "Warning: No matching artifact tarball found for version $VERSION"
    fi

    echo "==> Firmware build complete. All artifacts in: $WS/artifacts"
}
