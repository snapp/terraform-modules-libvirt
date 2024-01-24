resource "random_id" "virtual_machine" {
  keepers = {
    name = try(coalesce(var.virtual_machine.name, ""), "")
  }

  byte_length = 3
}

locals {
  instance_name = try(coalesce(var.virtual_machine.name, ""), "") != "" ? var.virtual_machine.name : "${var.virtual_machine.contact}-${lower(random_id.virtual_machine.hex)}"

  hostname = coalesce(var.virtual_machine.hostname, local.instance_name)

  fqdn = var.virtual_machine.domain != "" ? "${lower(local.hostname)}.${lower(var.virtual_machine.domain)}" : "${lower(local.hostname)}.local"

  description = try(coalesce(var.virtual_machine.description, ""), "") != "" ? var.virtual_machine.description : <<-EOT
    id: ${local.instance_name}
    fqdn: ${local.fqdn}
    contact: ${var.virtual_machine.contact}
  EOT

  libvirt_uri = "qemu+ssh://${var.hypervisor.ssh_user}@${var.hypervisor.fqdn}/system"

  vm_disk_size = ((var.virtual_machine.disk_size * 1024) * 1024) * 1024

  vm_ram_size = var.virtual_machine.ram_size * 1024
}
