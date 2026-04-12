variable "hypervisor" {
  nullable = false
  type = object({
    fqdn           = string
    storage_pool   = string
    ssh_user       = string
    network_bridge = optional(string, null)
    network_name   = optional(string, null)
    nat_cidr       = optional(string, "192.168.122.0/24")
  })
  validation {
    condition = (
      var.hypervisor.network_bridge != null ||
      var.hypervisor.network_name != null
    )
    error_message = "At least one of network_bridge or network_name must be set."
  }
  description = <<-EOT
    hypervisor = {
      fqdn : "The fully qualified hostname of the hypervisor where virtual machine instances are run."
      storage_pool : "The hypervisor storage pool where virtual machine images are stored."
      ssh_user : "The username used to SSH to the hypervisor and manage instances."
      network_bridge : "Host bridge device for the VM's primary NIC (bridge mode). Can be combined with network_name for a dual-NIC VM."
      network_name : "Libvirt virtual network name for NAT/routed mode. When set without network_bridge, ansible_ssh_common_args is automatically injected with a ProxyJump through the hypervisor."
      nat_cidr : "CIDR of the libvirt NAT network (default: 192.168.122.0/24). Used in dual-NIC mode to exclude NAT-assigned IPs when selecting the bridge IP for ansible_host."
    }
  EOT
}

variable "virtual_machine" {
  nullable = false
  type = object({
    name          = string
    contact       = string
    cpu_count     = number
    cpu_mode      = string
    description   = string
    disk_size     = number
    mac_address   = optional(string, null)
    domain        = string
    groups        = list(string)
    hostname      = string
    os_image      = string
    ram_size      = number
    root_password = string
    user = object({
      username       = string
      display_name   = string
      password       = string
      ssh_public_key = string
      sudo_rule      = string
    })
    enable_ansible_inventory = bool
    ansible_host_override    = optional(bool, false)
    extra_vars               = optional(map(string), {})
  })
  description = <<-EOT
    virtual_machine = {
      name : "The name of the virtual machine instance when listed on the hypervisor."
      contact : "The primary contact for the resources, this should be the username and must be able to receive email by appending your domain to it (e.g. \$\{contact}@example.com) (this person can explain what/why)."
      cpu_count : "The number of virtual CPUs allocated to the virtual machine (e.g. 2)."
      cpu_mode : "The virtual machine's CPU mode (e.g. 'host-passthrough')."
      description: "The optional description of the virtual machine instance when listed on the hypervisor."
      disk_size : "The virtual machine disk size in GB (e.g. 20)."
      mac_address : "The optional MAC address of the virtual machine's primary network interface."
      domain : "The optional network domain used for constructing a fqdn for the virtual machine."
      groups : "An array of Ansible inventory group names that the virtual machine should be associated with."
      hostname : "The optional short (unqualified) hostname of the instance to be created."
      os_image : "Operating System disk image for the instance to be created (as named in the hypervisor.storage_pool)."
      ram_size : "The amount of memory allocated to the virtual machine in GB (e.g. 4)."
      root_password : "Password for the root user of the instance (plain-text or hashed)."
      user = {
        username : "User used to access the instance."
        display_name : "Full name of the user used to access the instance."
        password : "Password for user used to access the instance (plain-text or hashed)."
        ssh_public_key : "SSH public key used to access the instance."
        sudo_rule : "Sudo rule applied to the user used to access the instance (e.g. 'ALL=(ALL) ALL')."
      }
      enable_ansible_inventory : "Whether to create an Ansible inventory host entry for the virtual machine."
      ansible_host_override : "When true, injects ansible_host=<VM IPv4> into the inventory host vars so Ansible connects by IP instead of resolving the FQDN (default: false)."
      extra_vars : "An optional map of additional Ansible inventory host variables to merge into the host entry (e.g. { ansible_user = \"myuser\", my_custom_var = \"value\" })."
    }
  EOT
}
