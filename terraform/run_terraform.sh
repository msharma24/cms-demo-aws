#!/usr/bin/env sh
#set -xe

export TF_IN_AUTOMATION=${CI}  # variable to flag CI build
export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"

# TF does not create the plugin directory if it does not exist
mkdir -p ${TF_PLUGIN_CACHE_DIR}

ENV=${1}
DEPLOY=${2}
DIRTY=${3}

: ${ENV:?"environment needs to be passed as the 1st parameter"}
if [ ! -d "./env/${ENV}" ]; then
  echo "Environment directory - ${ENV} - not found"
  exit 2
fi

ENV_PATH=./env/${ENV}/terraform.tfvars
BACKEND_PATH=./env/${ENV}/backend.conf
echo "Automated: ${TF_IN_AUTOMATION}."

# Only remove .terraform if DIRTY flag is not set
if [ "$DIRTY" != "dirty" ]; then
    echo "[INFO] Cleaning .terraform directory"
    rm -rf .terraform
fi

echo "[INFO] terraform init and plan"
terraform init  -backend-config=$BACKEND_PATH #-input=false 
terraform plan -var-file=$ENV_PATH -compact-warnings   -lock=true  -parallelism=100 -input=false 

# Kill the job if the TF PLAN fails.
STATUS=${?}
if [ ${STATUS} -ne 0 ]; then
    exit ${STATUS};
fi

if [ "$DEPLOY" = "deploy" ]; then
    echo "[INFO] Running Terraform Apply..."
    terraform apply  -var-file=$ENV_PATH  -auto-approve -compact-warnings
fi

if [ "$DEPLOY" = "destroy" ]; then
    echo "Running Terraform Apply..."
    terraform destroy  -var-file=$ENV_PATH   -compact-warnings
fi
