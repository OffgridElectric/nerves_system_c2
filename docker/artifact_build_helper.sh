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
    [ -r /home/dev/.asdf/completions/asdf.bash ] && . /home/dev/.asdf/completions/asdf.bash

    if [ -r /home/dev/.asdf/completions/asdf.bash ]; then
        . /home/dev/.asdf/completions/asdf.bash
    fi

    # Determine workspace from current folder
    WS=/work/nerves_system_c2
    echo "Workspace set to $WS"

    # Ensure artifacts folder exists
    mkdir -p "$WS/artifacts"


    # ------------------------------------------------------------------
    # 2.  Install deps & build firmware
    # ------------------------------------------------------------------
    echo "==> Installing dependencies for main workspace"
    cd $WS
    mix deps.get

    VERSION=$(cat "$WS/VERSION" | tr -d '[:space:]')
    ARTIFACT_TARBALL=$(find "$WS/.nerves/artifacts" -type f \
	-name "nerves_system_c2-portable-${VERSION}-*.tar.gz" \
	| sort | tail -n 1)

    if [ ! -f "$ARTIFACT_TARBALL" ]; then
	echo "==> Artefact missing – building Buildroot/Linux system"
	export NERVES_SYSTEM_CACHE=none

	"$WS/deps/nerves_system_br/create-build.sh" \
		"$WS/nerves_defconfig" \
		"$WS/.nerves/artifacts/nerves_system_c2-portable-${VERSION}" \
		>/dev/null

	cd "$WS/.nerves/artifacts/nerves_system_c2-portable-${VERSION}"
	make -j"$(nproc)"
    else
	echo "==> Artefact already exists – skipping system build"
    fi

    ARTIFACT_TARBALL=$(find "$WS/.nerves/artifacts" -type f \
	-name "nerves_system_c2-portable-${VERSION}-*.tar.gz" \
	| sort | tail -n 1)

    # -------------------------
    # Build firmware
    # -------------------------
    echo "==> Building firmware"
    cd $WS/test_c2
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

    # system tarball
    if [ -f "$ARTIFACT_TARBALL" ]; then
        echo "==> Copying artefact tarball: $(basename "$ARTIFACT_TARBALL")"
        cp "$ARTIFACT_TARBALL" "$WS/artifacts/"
    else
        echo "Warning: No matching artefact tarball found for version $VERSION"
    fi

    echo "==> Build complete. All artefacts in: $WS/artifacts"
}
