#! /usr/bin/env sh

set -e

# initialise some state with the default local backend
terraform init -input=false

# create the bucket (this does require an aws account with an authenticated role)
terraform apply -auto-approve -input=false

# migrate the state to the newly created bucket
terraform init -migrate-state -force-copy -input=false

# generate a plan with a diff
terraform plan -var='diff=true' -out terraform.plan

# attempt to apply twice using the same plan (it works -- if it doesn't this script will error out for inspection)
terraform apply -auto-approve -input=false terraform.plan || true
terraform apply -auto-approve -input=false -backup=backup.tfstate terraform.plan && return 1

# should include the success resource
terraform state list | grep "null_resource.resource"

# remove the generated backend
rm -f backend.tf terraform.plan

# migrate the state to the newly created bucket
terraform init -migrate-state -force-copy -input=false

# destroy everything
terraform apply -destroy -lock=false -input=false -auto-approve

# remove the state and backup state
rm -rf .terraform terraform.tfstate terraform.tfstate.backup
