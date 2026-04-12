output "virtual_machines" {
  description = <<-EOT
    A list of objects summarizing each provisioned virtual machine example.
      id : "The unique libvirt domain id of the virtual machine."
      name : "The name of the virtual machine instance when listed on the hypervisor."
      ansible_host : "The Ansible inventory host resource (groups, variables including ansible_host IP and ansible_ssh_common_args where applicable), or null if enable_ansible_inventory is false."
  EOT
  value = [
    {
      id           = module.bridge.id
      name         = module.bridge.name
      ansible_host = module.bridge.ansible_host
    },
    {
      id           = module.bridge_with_ip.id
      name         = module.bridge_with_ip.name
      ansible_host = module.bridge_with_ip.ansible_host
    },
    {
      id           = module.nat.id
      name         = module.nat.name
      ansible_host = module.nat.ansible_host
    },
    {
      id           = module.dual_nic.id
      name         = module.dual_nic.name
      ansible_host = module.dual_nic.ansible_host
    },
  ]
}
