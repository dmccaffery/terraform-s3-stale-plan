# S3 Backend - Stale Plan

This was an attempt at providing a proof for hashicorp/terraform#30670 but I have been unable to reproduce.

## Reproduce

You can inspect and run `proof.sh` or follow the steps below:

```sh
./proof.sh
```

OR

1. Iniitialise and create a bucket / dynamodb table to act as the backend

    ```sh
    terraform init
    terraform apply
    terraform init -migrate-state -force-copy
    ```

2. Generate a plan with a diff

    ```sh
    terraform plan -var='diff=true' -out terraform.plan
    ```

3. Attempt to apply the plan twice, per the issue the second attempt should cause corrupted state and not be detected
   as a stale plan:

    ```sh
    terraform apply -auto-approve -input=false terraform.plan
    terraform apply -auto-approve -input=false -backup=backup.tfstate terraform.plan
    ```

## Destroy

1. Remove the created backend, plan file, and migrate the state back to local:

    ```sh
    rm backend.tf terraform.plan
    terraform init -migrate-state -force-copy -input=false
    ```

2. Perform the destroy and remove the leftover state:

    ```sh
    terraform apply -destroy -lock=false -input=false -auto-approve
    rm -rf .terraform terraform.tfstate terraform.tfstate.backup
    ```
