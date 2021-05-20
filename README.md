# Rancher Terraform

This terraform is to spin up a single node Rancher VM on Linode with a Let's Encrypt certificate and configures a Linode Domain Record as well.

## Requirements
- terraform 0.13 or newer

## Usage
1. Clone the repo
```bash
git clone git@github.com:dhawton/rancher-terraform.git
cd rancher-terraform
```
2. Create the variables_override.tf
```bash
cp variables_override.tf.example variables_override.tf
```
3. Create the terraform.tfvars with your Linode token (you can skip this step, terraform will prompt for it if this file is not populated)
```bash
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```
4. Configure the variables_override.tf
```bash
vi variables_override.tf
```
5. Terraform init, plan and apply like normal