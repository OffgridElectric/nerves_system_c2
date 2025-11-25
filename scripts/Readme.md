
# Building Nerves System C2 with Docker

Steps to build the `nerves_system_c2` using a dedicated Docker environment.

-----

## Initial Docker Environment Setup

Ensure you have **Docker** installed and running. Before performing any build, you must set up the Docker environment and image.

1.  **Navigate to the System Directory**

    ```
    cd nerves_system_c2
    ```

2.  **Setup the Docker Environment**
    This script builds the necessary Docker image and prepares the build environment.

    ```
    ./script/docker/setup.sh
    ```

-----

## Build Workflow (Interactive)

This workflow is best for **debugging** or running multiple commands inside the container's shell.

1.  **Start the Interactive Docker Shell**
    This command drops you into a shell *inside* the Docker container.
    ```
    ./script/docker/shell.sh
    ```
2.  **Execute the Build Script**
    Once inside the container (you should already be in the `/work/nerves_system_c2` directory), run the local build script.
    ```
    ./scripts/c2_build_local.sh
    ```

-----

## Build Workflow (Non-Interactive)

This workflow executes the commands in an automated sequence without requiring a persistent shell session.

1.  **Run Docker Environment Script**
    Execute the Docker run script. This launches the container and executes any pre-defined entrypoint/setup logic.

    ```
    ./script/docker/run.sh
    ```
-----

