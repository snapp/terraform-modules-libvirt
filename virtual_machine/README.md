# Terraform Libvirt virtual_machine Module

This terraform module provides a convenience for instantiating a virtual machine on a Libvirt hypervisor.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.5.0 |
| <a name="requirement_ansible"></a> [ansible](#requirement\_ansible) | ~> 1.3.0 |
| <a name="requirement_libvirt"></a> [libvirt](#requirement\_libvirt) | >=0.9.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.8.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_ansible"></a> [ansible](#provider\_ansible) | 1.3.0 |
| <a name="provider_libvirt"></a> [libvirt](#provider\_libvirt) | 0.9.1 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [ansible_host.virtual_machine](https://registry.terraform.io/providers/ansible/ansible/latest/docs/resources/host) | resource |
| [libvirt_cloudinit_disk.cloudinit](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/resources/cloudinit_disk) | resource |
| [libvirt_domain.virtual_machine](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/resources/domain) | resource |
| [libvirt_volume.cloudinit](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/resources/volume) | resource |
| [libvirt_volume.virtual_machine](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/resources/volume) | resource |
| [random_id.virtual_machine](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hypervisor"></a> [hypervisor](#input\_hypervisor) | hypervisor = {<br/>  fqdn : "The fully qualified hostname of the hypervisor where virtual machine instances are run."<br/>  network\_bridge : "The hypervisor network bridge used to connect to the virtual machine's primary network interface."<br/>  storage\_pool : "The hypervisor storage pool where virtual machine images are stored."<br/>  ssh\_user : "The username used to SSH to the hypervisor and manage instances."<br/>} | <pre>object({<br/>    fqdn           = string<br/>    network_bridge = string<br/>    storage_pool   = string<br/>    ssh_user       = string<br/>  })</pre> | n/a | yes |
| <a name="input_virtual_machine"></a> [virtual\_machine](#input\_virtual\_machine) | virtual\_machine = {<br/>  name : "The name of the virtual machine instance when listed on the hypervisor."<br/>  contact : "The primary contact for the resources, this should be the username and must be able to receive email by appending your domain to it (e.g. \$\{contact}@example.com) (this person can explain what/why)."<br/>  cpu\_count : "The number of virtual CPUs allocated to the virtual machine (e.g. 2)."<br/>  cpu\_mode : "The virtual machine's CPU mode (e.g. 'host-passthrough')."<br/>  description: "The optional description of the virtual machine instance when listed on the hypervisor."<br/>  disk\_size : "The virtual machine disk size in GB (e.g. 20)."<br/>  mac\_address : "The optional MAC address of the virtual machine's primary network interface."<br/>  domain : "The optional network domain used for constructing a fqdn for the virtual machine."<br/>  groups : "An array of Ansible inventory group names that the virtual machine should be associated with."<br/>  hostname : "The optional short (unqualified) hostname of the instance to be created."<br/>  os\_image : "Operating System disk image for the instance to be created (as named in the hypervisor.storage\_pool)."<br/>  ram\_size : "The amount of memory allocated to the virtual machine in GB (e.g. 4)."<br/>  root\_password : "Password for the root user of the instance (plain-text or hashed)."<br/>  user = {<br/>    username : "User used to access the instance."<br/>    display\_name : "Full name of the user used to access the instance."<br/>    password : "Password for user used to access the instance (plain-text or hashed)."<br/>    ssh\_public\_key : "SSH public key used to access the instance."<br/>    sudo\_rule : "Sudo rule applied to the user used to access the instance (e.g. 'ALL=(ALL) ALL')."<br/>  }<br/>  enable\_ansible\_inventory : "Whether to create an Ansible inventory host entry for the virtual machine."<br/>} | <pre>object({<br/>    name          = string<br/>    contact       = string<br/>    cpu_count     = number<br/>    cpu_mode      = string<br/>    description   = string<br/>    disk_size     = number<br/>    mac_address   = string<br/>    domain        = string<br/>    groups        = list(string)<br/>    hostname      = string<br/>    os_image      = string<br/>    ram_size      = number<br/>    root_password = string<br/>    user = object({<br/>      username       = string<br/>      display_name   = string<br/>      password       = string<br/>      ssh_public_key = string<br/>      sudo_rule      = string<br/>    })<br/>    enable_ansible_inventory = bool<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The unique id of the virtual machine. |
| <a name="output_ipv4_address"></a> [ipv4\_address](#output\_ipv4\_address) | The ipv4 address of the virtual machine. |
| <a name="output_name"></a> [name](#output\_name) | The name of the virtual machine instance when listed on the hypervisor. |
<!-- END_TF_DOCS -->

## Examples
- [multiple_virtual_machines](examples/example-multiple_virtual_machines/README.md)

## Licensing

GNU General Public License v3.0 or later

See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.txt) to see the full text.
