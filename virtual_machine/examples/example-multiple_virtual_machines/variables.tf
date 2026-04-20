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
    contact   = string
    disk_size = number
    os_image  = string

    # Compute — optional with defaults (cpu_count=2, cpu_mode=host-passthrough, ram_size=4)
    cpu_count = optional(number, 2)
    cpu_mode  = optional(string, "host-passthrough")
    ram_size  = optional(number, 4)

    # Network
    mac_address = optional(string, null)

    # User management
    root_password = optional(string)
    user = optional(object({
      username       = string
      display_name   = string
      password       = optional(string)
      homedir        = optional(string)
      ssh_public_key = string
      sudo_rule      = optional(string)
      uid            = optional(number)
    }))

    # First-boot commands
    runcmd = optional(list(string), [])
  })
  description = <<-EOT
    virtual_machine = {
      contact : "The primary contact for the resources."
      disk_size : "The virtual machine OS disk size in GB (e.g. 20)."
      os_image : "Operating System disk image for the instance (as named in the hypervisor storage pool)."
      cpu_count : "The number of virtual CPUs allocated to the virtual machine (default: 2)."
      cpu_mode : "The virtual machine's CPU mode (default: host-passthrough)."
      ram_size : "The amount of memory allocated to the virtual machine in GB (default: 4)."
      mac_address : "Optional MAC address for the primary network interface."
      root_password : "The optional hashed password for the root user."
      user = {
        username : "User used to access the instance."
        display_name : "Full name of the user."
        password : "The optional hashed password for the user."
        homedir : "The optional home directory for the user."
        ssh_public_key : "SSH public key used to access the instance."
        sudo_rule : "The optional sudo rule applied to the user (e.g. 'ALL=(ALL) NOPASSWD:ALL')."
        uid : "The optional user ID of the user."
      }
      runcmd : "An optional list of shell commands to run on first boot."
    }
  EOT
}
