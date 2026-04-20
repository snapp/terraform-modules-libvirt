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
| <a name="provider_libvirt"></a> [libvirt](#provider\_libvirt) | 0.9.7 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.8.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

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
| [terraform_data.wait_for_ip](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [libvirt_domain_interface_addresses.virtual_machine](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/data-sources/domain_interface_addresses) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hypervisor"></a> [hypervisor](#input\_hypervisor) | hypervisor = {<br/>  fqdn : "The fully qualified hostname of the hypervisor where virtual machine instances are run."<br/>  storage\_pool : "The hypervisor storage pool where virtual machine images are stored."<br/>  ssh\_user : "The username used to SSH to the hypervisor and manage instances."<br/>  network\_bridge : "Host bridge device for the VM's primary NIC (bridge mode). Can be combined with network\_name for a dual-NIC VM."<br/>  network\_name : "Libvirt virtual network name for NAT/routed mode. When set without network\_bridge, ansible\_ssh\_common\_args is automatically injected with a ProxyJump through the hypervisor."<br/>  nat\_cidr : "CIDR of the libvirt NAT network (default: 192.168.122.0/24). Used in dual-NIC mode to exclude NAT-assigned IPs when selecting the bridge IP for ansible\_host."<br/>} | <pre>object({<br/>    fqdn           = string<br/>    storage_pool   = string<br/>    ssh_user       = string<br/>    network_bridge = optional(string, null)<br/>    network_name   = optional(string, null)<br/>    nat_cidr       = optional(string, "192.168.122.0/24")<br/>  })</pre> | n/a | yes |
| <a name="input_virtual_machine"></a> [virtual\_machine](#input\_virtual\_machine) | virtual\_machine = {<br/>  name : "The optional name of the virtual machine instance. Defaults to a generated name based on contact."<br/>  contact : "The primary contact for the resources, this should be the username and must be able to receive email by appending your domain to it (e.g. \$\{contact}@example.com)."<br/>  description : "The optional description of the virtual machine instance."<br/>  hostname : "The optional short (unqualified) hostname of the instance. Defaults to the instance name."<br/>  domain : "The optional network domain used for constructing a fqdn for the virtual machine (default: local)."<br/>  cpu\_count : "The number of virtual CPUs allocated to the virtual machine (default: 2)."<br/>  cpu\_mode : "The virtual machine's CPU mode (default: host-passthrough)."<br/>  ram\_size : "The amount of memory allocated to the virtual machine in GB (default: 4)."<br/>  disk\_size : "The virtual machine OS disk size in GB (e.g. 20)."<br/>  os\_image : "Operating System disk image for the instance (as named in the hypervisor.storage\_pool)."<br/>  mac\_address : "The optional MAC address of the virtual machine's primary network interface."<br/>  root\_password : "The optional hashed password for the root user."<br/>  user = {<br/>    username : "User used to access the instance."<br/>    display\_name : "Full name of the user used to access the instance."<br/>    password : "The optional hashed password for the user."<br/>    homedir : "The optional home directory for the user (defaults to /home/<username>)."<br/>    ssh\_public\_key : "SSH public key used to access the instance."<br/>    sudo\_rule : "The optional sudo rule applied to the user (e.g. 'ALL=(ALL) NOPASSWD:ALL')."<br/>    uid : "The optional user ID of the user."<br/>  }<br/>  runcmd : "An optional list of shell commands to run on first boot via cloud-init runcmd (e.g. [\"ipa-client-install --unattended ...\"])."<br/>  groups : "An optional list of Ansible inventory group names for the virtual machine (default: [])."<br/>  enable\_ansible\_inventory : "Whether to create an Ansible inventory host entry for the virtual machine (default: true)."<br/>  ansible\_host\_override : "When true, injects ansible\_host=<VM IPv4> into the inventory host vars so Ansible connects by IP instead of resolving the FQDN (default: false)."<br/>  extra\_vars : "An optional map of additional Ansible inventory host variables to merge into the host entry."<br/>} | <pre>object({<br/>    # Identity<br/>    name        = optional(string)<br/>    contact     = string<br/>    description = optional(string)<br/>    hostname    = optional(string)<br/>    domain      = optional(string)<br/><br/>    # Compute<br/>    cpu_count = optional(number, 2)<br/>    cpu_mode  = optional(string, "host-passthrough")<br/>    ram_size  = optional(number, 4)<br/>    disk_size = number<br/><br/>    # Storage<br/>    os_image = string<br/><br/>    # Network<br/>    mac_address = optional(string, null)<br/><br/>    # User management<br/>    root_password = optional(string)<br/>    user = optional(object({<br/>      username       = string<br/>      display_name   = string<br/>      password       = optional(string)<br/>      homedir        = optional(string)<br/>      ssh_public_key = string<br/>      sudo_rule      = optional(string)<br/>      uid            = optional(number)<br/>    }))<br/><br/>    # First-boot commands<br/>    runcmd = optional(list(string), [])<br/><br/>    # Ansible inventory<br/>    groups                   = optional(list(string), [])<br/>    enable_ansible_inventory = optional(bool, true)<br/>    ansible_host_override    = optional(bool, false)<br/>    extra_vars               = optional(map(string), {})<br/>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ansible_host"></a> [ansible\_host](#output\_ansible\_host) | The Ansible inventory host resource, or null if enable\_ansible\_inventory is false. |
| <a name="output_id"></a> [id](#output\_id) | The unique id of the virtual machine. |
| <a name="output_name"></a> [name](#output\_name) | The name of the virtual machine instance when listed on the hypervisor. |
| <a name="output_virtual_machine"></a> [virtual\_machine](#output\_virtual\_machine) | The libvirt domain resource representing the virtual machine. |
<!-- END_TF_DOCS -->

## Examples
- [multiple_virtual_machines](examples/example-multiple_virtual_machines/README.md)

## Licensing

GNU General Public License v3.0 or later

See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.txt) to see the full text.
