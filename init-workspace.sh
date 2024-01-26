#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

WS_DIR="${ROOT_DIR}/workspace"
DEV_CFG=false
WS_CFG=false


usage="usage: $(basename "$0") [-c] [-d] [-h] [-w]

This script will initialize a workspace environment for EVerest using a Docker
container running the EVerest dependency manager (edm).

The '-d' specifies the directory to create for the workspace environment. If not
provided, it will default to 'workspace' within the current directory.

The '-w' flag will instruct edm to create a VS Code workspace config file within
the workspace directory.

The '-c' flag will instruct edm to create a VS Code dev container config within
the workspace directory. This flag also implies the '-w' flag.

where:
    -c      create VS Code dev container config
    -d      workspace directory to create (default: $WS_DIR)
    -h      show this help text
    -w      create VS Code workspace config"


# loop through positional options/arguments
while getopts ':cd:hw' option; do
    case "$option" in
        c)  DEV_CFG=true           ;;
        d)  WS_DIR="$OPTARG"       ;;
        h)  echo -e "$usage"; exit ;;
        w)  WS_CFG=true            ;;
        \?) echo -e "illegal option: -$OPTARG\n" >$2
            echo -e "$usage" >&2
            exit 1 ;;
    esac
done


# test if workspace directory is absolute
if [[ "$WS_DIR" != /* ]]; then
  WS_DIR="${ROOT_DIR}/${WS_DIR}"
elif [[ $WS_DIR/ != ${ROOT_DIR}/* ]]; then
  echo "workspace directory must be within current directory"
  exit 1
fi


echo    "workspace directory:                 $WS_DIR"
echo    "create VS Code workspace config:     $WS_CFG"
echo -e "create VS Code dev container config: $DEV_CFG\n"


which docker &> /dev/null

if (( $? )); then
  echo "Docker must be installed (and in your PATH) to use this build script. Exiting."
  exit 1
fi


_args=()


if [[ "$DEV_CFG" = true ]]; then
  _args+=(--create-vscode-workspace --create-vscode-dev-container)
elif [[ "$WS_CFG" = true ]]; then
  _args+=(--create-vscode-workspace)
fi


USER_UID=$(id -u)
USERNAME=builder


if (( $USER_UID == 0 )); then
  USERNAME=root
fi


docker build -t everest-workspace:builder -f - . <<EOF
FROM ubuntu:22.04

RUN ["/bin/bash", "-c", "if (( $USER_UID != 0 )); then \
  groupadd --gid $USER_UID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_UID -m $USERNAME; fi"]

RUN apt update \
  && apt install -y git python3-pip \
  && python3 -m pip install --upgrade pip setuptools wheel jstyleson jsonschema

ADD ./dependency_manager /tmp/edm
WORKDIR /tmp/edm

RUN python3 -m pip install .

ADD ./everest-complete-readonly.yaml /workspace-config.yaml

ENV CPM_SOURCE_CACHE=/root/.cache/CPM
EOF


echo BUILDING EVEREST WORKSPACE...

mkdir -p $WS_DIR

docker run -it --rm \
  -v $WS_DIR:/workspace \
  -w /workspace \
  -u $USERNAME \
  everest-workspace:builder edm "${_args[@]}" init --config /workspace-config.yaml --workspace /workspace

echo DONE BUILDING EVEREST WORKSPACE
