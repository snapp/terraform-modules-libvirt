variable "hypervisor" {
  nullable = false
  type = object({
    fqdn           = string
    network_bridge = string
    storage_pool   = string
    ssh_user       = string
  })
  description = <<-EOT
    hypervisor = {
      fqdn : "The fully qualified hostname of the hypervisor where virtual machine instances are run."
      network_bridge : "The hypervisor network bridge used to connect to the virtual machine's primary network interface."
      storage_pool : "The hypervisor storage pool where virtual machine images are stored."
      ssh_user : "The username used to SSH to the hypervisor and manage instances."
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
    mac_address   = string
    domain        = string
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
  })
  description = <<-EOT
    virtual_machine = {
      name : "The name of the virtual machine instance when listed on the hypervisor."
      contact : "The primary contact for the resources, this should be the username and must be able to receive email by appending @redhat.com to it (this person can explain what/why)."
      cpu_count : "The number of virtual CPUs allocated to the virtual machine (e.g. 2)."
      cpu_mode : "The virtual machine's CPU mode (e.g. 'host-passthrough')."
      description: "The optional description of the virtual machine instance when listed on the hypervisor."
      disk_size : "The virtual machine disk size in GB (e.g. 20)."
      mac_address : "The optional MAC address of the virtual machine's primary network interface."
      domain : "The optional network domain used for constructing a fqdn for the virtual machine."
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
    }
  EOT
}
