#!/bin/bash

function check_exists() {
  if ! command -v $1 &>/dev/null; then
    echo "Command $1 does not exist, please install."
    exit 1
  fi
}

function do_prompt() {
  local __resultvar=$3
  read -p "$1 [$2] " ret
  if [[ $ret == "" ]]; then
    eval $__resultvar="$2"
  else
    eval $__resultvar="$ret"
  fi
}

function do_promptyn() {
  local __resultvar=$3
  read -p "$1 [$2] " ret
  local ret=$(echo "$ret" | tr '[:upper:]' '[:lower:]')
  if [[ $ret == "" ]]; then
    eval $__resultvar="$2"
  else
    case $ret in
      y|yes)
        eval $__resultvar="y"
        ;;
      n|no)
        eval $__resultvar="n"
        ;;
      *)
        echo "Invalid option"
        do_promptyn $1 $2 $3
    esac
  fi
}