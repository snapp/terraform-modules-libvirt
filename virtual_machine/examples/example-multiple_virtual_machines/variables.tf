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
  description = <<-EOT
    hypervisor = {
      fqdn : "The fully qualified hostname of the hypervisor where virtual machine instances are run."
      storage_pool : "The hypervisor storage pool where virtual machine images are stored."
      ssh_user : "The username used to SSH to the hypervisor and manage instances."
      network_bridge : "Host bridge device name (e.g. 'br0'). Set to enable bridge networking."
      network_name : "Libvirt virtual network name (e.g. 'default'). Set to enable NAT networking."
      nat_cidr : "CIDR of the libvirt NAT network. Used in dual-NIC mode to identify NAT addresses."
    }
  EOT
}

variable "virtual_machine" {
  nullable = false
  type = object({
    contact       = string
    cpu_count     = number
    cpu_mode      = string
    disk_size     = number
    mac_address   = optional(string, null)
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
  })
  description = <<-EOT
    virtual_machine = {
      contact : "The primary contact for the resources."
      cpu_count : "The number of virtual CPUs allocated to the virtual machine (e.g. 2)."
      cpu_mode : "The virtual machine's CPU mode (e.g. 'host-passthrough')."
      disk_size : "The virtual machine disk size in GB (e.g. 20)."
      mac_address : "Optional MAC address for the primary network interface."
      os_image : "Operating System disk image for the instance (as named in the hypervisor storage pool)."
      ram_size : "The amount of memory allocated to the virtual machine in GB (e.g. 4)."
      root_password : "Password for the root user of the instance (hashed)."
      user = {
        username : "User used to access the instance."
        display_name : "Full name of the user."
        password : "Hashed password for the user."
        ssh_public_key : "SSH public key used to access the instance."
        sudo_rule : "Sudo rule applied to the user (e.g. 'ALL=(ALL) ALL')."
      }
    }
  EOT
}
