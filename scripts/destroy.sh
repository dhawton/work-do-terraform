#!/bin/bash

. buildconfig.sh

if [[ $use_rke == "y" ]]; then
  cd rke
  rke remove
  cd ..
fi

terraform destroy