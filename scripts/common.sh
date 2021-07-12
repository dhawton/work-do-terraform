#!/bin/bash

function check_exists() {
    if ! command -v $1 &>/dev/null; then
      echo "Command $1 does not exist, please install."
      exit 1
    fi
}

function do_prompt() {
    read -p "$1 [$2] " ret
    if [[ $ret == "" ]]; then
      echo $2
    else
      echo $1
    fi
}