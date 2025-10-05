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
}

# -----------------------------
# Build firmware and artifacts
# -----------------------------
build() {
    set_artifact_env

    # Determine workspace from current folder
    WS=/work/nerves_system_c2
    echo "Workspace set to $WS"

    # Ensure artifacts folder exists
    mkdir -p "$WS/artifacts"

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
