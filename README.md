# EVerest dev environment

This subproject contains all utility files for setting up your development
environment.

All documentation and the issue tracking can be found in our main repository
here: https://github.com/EVerest/everest

## Everest Dependency Manager

The [edm - the Everest Dependency Manager](dependency_manager/README.md) helps
to orchestrate the dependencies between the different EVerest repositories.

You can install [edm](dependency_manager/README.md) very easily using pip.

## Workspace Initializer

The [init-workspace.sh](init-workspace.sh) script will use a Docker container to
initialize an EVerest workspace directory using `edm` without having to install
any of the dependencies locally. This is especially useful when the VS Code dev
container option is used, since all the development dependencies will be
containerized as well.

If the `init-workspace.sh` script is used with the `-c` option (to generate VS
Code dev container configs), use VS Code's `Dev Container: Open Workspace in
Container...` option to fire up your self-contained EVerest development
environment using the `*.code-workspace` file within the EVerest workspace
directory created by the script.
