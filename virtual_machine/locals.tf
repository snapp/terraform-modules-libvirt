resource "random_id" "virtual_machine" {
  keepers = {
    name = try(coalesce(var.virtual_machine.name, ""), "")
  }

  byte_length = 3
}

locals {
  instance_name = try(coalesce(var.virtual_machine.name, ""), "") != "" ? var.virtual_machine.name : "${var.virtual_machine.contact}-${lower(random_id.virtual_machine.hex)}"

  hostname = coalesce(var.virtual_machine.hostname, local.instance_name)

  domain = try(coalesce(var.virtual_machine.domain, ""), "") != "" ? var.virtual_machine.domain : "local"

  fqdn = "${lower(local.hostname)}.${lower(local.domain)}"

  description = try(coalesce(var.virtual_machine.description, ""), "") != "" ? var.virtual_machine.description : <<-EOT
    id: ${local.instance_name}
    fqdn: ${local.fqdn}
    contact: ${var.virtual_machine.contact}
  EOT

  libvirt_uri = "qemu+ssh://${var.hypervisor.ssh_user}@${var.hypervisor.fqdn}/system"

  # Network mode flags.
  nat_network    = var.hypervisor.network_name != null
  bridge_network = var.hypervisor.network_bridge != null
  # VM has two NICs: a routable bridge IP and a NAT egress NIC for VPN access.
  dual_nic = local.nat_network && local.bridge_network
  # VM has no directly routable address; Ansible must tunnel through the hypervisor.
  nat_only = local.nat_network && !local.bridge_network

  # NAT network address prefix with a trailing dot, used in dual-NIC mode to exclude
  # NAT-assigned IPs when selecting the bridge IP for ansible_host.
  # Example: "192.168.122.0/24" → "192.168.122."
  # NOTE|2026-04-12| Computed at octet boundaries; accurate for /8, /16, /24 CIDRs.
  nat_addr_prefix = local.dual_nic ? "${join(".", slice(
    split(".", split("/", var.hypervisor.nat_cidr)[0]),
    0,
    floor(tonumber(split("/", var.hypervisor.nat_cidr)[1]) / 8)
  ))}." : ""

  # VM network interface list. Bridge is always first so the guest OS assigns the
  # directly routable address to the primary NIC (eth0/ens3). The NAT interface
  # is added second when network_name is configured, giving the VM VPN egress.
  #
  # Bare `null` literals become cty.DynamicPseudoType and cause concat() to panic
  # on type unification. The pattern `false ? { key = "" } : null` always evaluates
  # to null at runtime but lets Terraform infer a concrete object type from the
  # non-null branch, keeping element types consistent across both list arguments.
  vm_interfaces = concat(
    var.hypervisor.network_bridge != null ? [
      {
        mac = var.virtual_machine.mac_address != null ? {
          address = var.virtual_machine.mac_address
        } : false ? { address = "" } : null # typed null: object({address=string})
        source = {
          bridge  = { bridge = var.hypervisor.network_bridge }
          network = false ? { network = "" } : null # typed null: object({network=string})
        }
      }
    ] : [],
    var.hypervisor.network_name != null ? [
      {
        mac = false ? { address = "" } : null # typed null: object({address=string})
        source = {
          bridge  = false ? { bridge = "" } : null # typed null: object({bridge=string})
          network = { network = var.hypervisor.network_name }
        }
      }
    ] : []
  )

  vm_disk_size = ((var.virtual_machine.disk_size * 1024) * 1024) * 1024

  vm_ram_size = var.virtual_machine.ram_size * 1024
}
