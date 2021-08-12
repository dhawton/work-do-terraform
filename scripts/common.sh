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

function do_prompt_choices() {
  local prompt=$1
  shift
  local default=$1
  shift
  local __resultvar=$1
  shift
  local __choices=("$@")

  echo ${__choices[@]}

  read -p "$prompt [$default] " ret
  local ret=$(echo "$ret" | tr '[:upper:]' '[:lower:]')
  if [[ $ret == "" ]]; then
    eval $__resultvar="$default"
  else
    haschoice=0
    for choice in "${__choices[@]}"; do
      if [[ $ret == $choice ]]; then
        haschoice=1
        break
      fi
    done
    if [[ $haschoice == 0 ]]; then
      echo "Invalid option"
      do_prompt_choices "$prompt" "$default" $__resultvar $__choices
    else
      eval $__resultvar="$ret"
    fi
  fi
}