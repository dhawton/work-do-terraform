#!/bin/bash

. buildconfig.sh

if [[ $auto_deploy_downstream == "y" ]]; then
    echo "Destroying downstream"
    cd downstream
    terraform destroy
    cd ..
fi

echo "Destroying upstream"
terraform destroy