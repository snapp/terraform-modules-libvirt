# Example using Libvirt to deploy multiple virtual machines

This folder contains a set of Terraform configuration files (sometimes informally referred to as a "manifest") that serve as examples for how you can use this module to define multiple Libvirt virtual machines.

This example follows the [Standard Module Structure as defined by Hashicorp](https://developer.hashicorp.com/terraform/language/modules/develop/structure) and uses the recommended filenames of:

* `main.tf` - primary entrypoint containing several `virtual_machine` module definitions
* `variables.tf` - defines the `virtual_machine` object used to configure the module
* `terraform.tfvars` - defines the default values for the `virtual_machine` object used to configure the module
* `outputs.tf` - optional file that can be used to output useful information about the managed virtual machines.

## Quick start

To deploy multiple Libvirt virtual machines:

1. Copy this example directory to a new location
2. Modify `terraform.tfvars` to contain the values common to all virtual machines you'd like to create.
    > **NOTE**
    > The `virtual_machine` configuration object requires all attributes to be defined. As such, you will need to use a `null` value for attributes you do not want to set.
3. Modify `main.tf` to contain module definitions for each virtual machine you'd like to create.
    > **TIP**
    > By using the [merge function](https://developer.hashicorp.com/terraform/language/functions/merge) you can override any value defined in the `terraform.tfvars` file for a specific virtual machine instance.
4. Run [`terraform init`](https://developer.hashicorp.com/terraform/cli/commands/init).
    > This command initializes a working directory containing Terraform configuration files and ensures the working directory is up to date with changes in your configuration files should you run it multiple times.
5. Run [`terraform plan`]https://developer.hashicorp.com/terraform/cli/commands/plan).
    > This command creates an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.
6. Run [`terraform apply`](https://developer.hashicorp.com/terraform/cli/commands/apply).
    > This command executes the actions proposed in the `terraform plan`
7. `ssh` into one of the virtual machines to validate connectivity
8. Run [`terraform destroy`](https://developer.hashicorp.com/terraform/cli/commands/destroy).
    >This command destroys all remote virtual machines managed by the Terraform configuration.
