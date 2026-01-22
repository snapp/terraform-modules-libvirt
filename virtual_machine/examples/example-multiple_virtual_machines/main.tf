terraform {
  required_version = ">=1.5.0"
}

# Simple example with no `terraform.tfvars` overrides
module "test1" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=e7e4789"

  hypervisor      = var.hypervisor
  virtual_machine = var.virtual_machine
}

# Example that merges the `name`, `hostname`, `domain`, and description variables
module "test2" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=e7e4789"

  hypervisor = var.hypervisor

  virtual_machine = merge(var.virtual_machine, {
    name        = "test2"
    hostname    = "test2"
    domain      = "example.com"
    description = "This is an example of a description."
  })
}

# Example where no root password is set
module "test3" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=e7e4789"

  hypervisor = var.hypervisor

  virtual_machine = merge(var.virtual_machine, {
    root_password = null
  })
}

# Example where no user modifications are performed
module "test4" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=e7e4789"

  hypervisor = var.hypervisor

  virtual_machine = merge(var.virtual_machine, {
    root_password = null
    user          = null
  })
}
