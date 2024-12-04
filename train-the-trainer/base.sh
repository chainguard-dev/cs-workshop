#!/usr/bin/env bash
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
export DOCKER_CLI_HINTS=false
export BATCAT="cat"
if [ -x "$(command -v bat)" ]; then
  export BATCAT="bat --map-syntax Dockerfile.*:Dockerfile"
fi

function banner() {
  # get the length of $1 string
  length=${#1}
  echo
  echo " ╔═$(printf '═%.0s' $(seq 1 $length))═╗"
  echo " ║ ${1} ║"
  echo " ╚═$(printf '═%.0s' $(seq 1 $length))═╝"
}

. ${SCRIPT_DIR}/demo-magic.sh
TYPE_SPEED=60
