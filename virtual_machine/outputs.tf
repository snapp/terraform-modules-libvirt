output "id" {
  description = "The unique id of the virtual machine."
  value       = libvirt_domain.virtual_machine.id
}

output "name" {
  description = "The name of the virtual machine instance when listed on the hypervisor."
  value       = local.instance_name
}

output "ipv4_address" {
  description = "The ipv4 address of the virtual machine."
  value       = libvirt_domain.virtual_machine.devices.interfaces[0].address
}
