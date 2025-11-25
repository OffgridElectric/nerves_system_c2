#!/bin/bash

set -e  # Exit on any error

set_artifact_env()
{
    echo "Setting artifact environment..."
    export MIX_TARGET=c2
    export MIX_ENV=prod
    echo "MIX_TARGET=$MIX_TARGET"
    echo "MIX_ENV=$MIX_ENV"
}

build()
{
    echo "Starting build process..."
    set_artifact_env

    WS=/work/nerves_system_c2
    echo "Working directory: $WS"

    # Check if working directory exists
    if [ ! -d "$WS" ]; then
        echo "Error: Working directory $WS does not exist"
        exit 1
    fi

    # Get dependencies for main project
    echo "Getting dependencies for main project..."
    cd $WS
    mix deps.get

    # Get dependencies for test_c2 project
    echo "Getting dependencies for test_c2 project..."
    cd $WS/test_c2
    mix deps.get

    # Build firmware
    echo "Building firmware..."
    mix firmware

    # Create artifact
    echo "Creating artifact..."
    cd $WS
    mix nerves.artifact

    echo "Build completed successfully!"
}

# Run the build function
build