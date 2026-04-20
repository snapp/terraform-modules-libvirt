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
    # Identity
    name        = optional(string)
    contact     = string
    description = optional(string)
    hostname    = optional(string)
    domain      = optional(string)

    # Compute
    cpu_count = optional(number, 2)
    cpu_mode  = optional(string, "host-passthrough")
    ram_size  = optional(number, 4)
    disk_size = number

    # Storage
    os_image = string

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

    # Ansible inventory
    groups                   = optional(list(string), [])
    enable_ansible_inventory = optional(bool, true)
    ansible_host_override    = optional(bool, false)
    extra_vars               = optional(map(string), {})
  })
  description = <<-EOT
    virtual_machine = {
      name : "The optional name of the virtual machine instance. Defaults to a generated name based on contact."
      contact : "The primary contact for the resources, this should be the username and must be able to receive email by appending your domain to it (e.g. \$\{contact}@example.com)."
      description : "The optional description of the virtual machine instance."
      hostname : "The optional short (unqualified) hostname of the instance. Defaults to the instance name."
      domain : "The optional network domain used for constructing a fqdn for the virtual machine (default: local)."
      cpu_count : "The number of virtual CPUs allocated to the virtual machine (default: 2)."
      cpu_mode : "The virtual machine's CPU mode (default: host-passthrough)."
      ram_size : "The amount of memory allocated to the virtual machine in GB (default: 4)."
      disk_size : "The virtual machine OS disk size in GB (e.g. 20)."
      os_image : "Operating System disk image for the instance (as named in the hypervisor.storage_pool)."
      mac_address : "The optional MAC address of the virtual machine's primary network interface."
      root_password : "The optional hashed password for the root user."
      user = {
        username : "User used to access the instance."
        display_name : "Full name of the user used to access the instance."
        password : "The optional hashed password for the user."
        homedir : "The optional home directory for the user (defaults to /home/<username>)."
        ssh_public_key : "SSH public key used to access the instance."
        sudo_rule : "The optional sudo rule applied to the user (e.g. 'ALL=(ALL) NOPASSWD:ALL')."
        uid : "The optional user ID of the user."
      }
      runcmd : "An optional list of shell commands to run on first boot via cloud-init runcmd (e.g. [\"ipa-client-install --unattended ...\"])."
      groups : "An optional list of Ansible inventory group names for the virtual machine (default: [])."
      enable_ansible_inventory : "Whether to create an Ansible inventory host entry for the virtual machine (default: true)."
      ansible_host_override : "When true, injects ansible_host=<VM IPv4> into the inventory host vars so Ansible connects by IP instead of resolving the FQDN (default: false)."
      extra_vars : "An optional map of additional Ansible inventory host variables to merge into the host entry."
    }
  EOT
}
