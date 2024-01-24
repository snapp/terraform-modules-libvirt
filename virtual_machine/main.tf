# https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs

terraform {
  required_version = ">=1.0.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.7.6"
    }

    random = {
      source  = "hashicorp/random"
      version = ">=3.6.0"
    }
  }
}

provider "libvirt" {
  uri = local.libvirt_uri
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name = "${local.fqdn}-cloudinit.iso"

  pool = var.hypervisor.storage_pool

  meta_data = <<-EOT
  #cloud-config
  instance-id: ${local.instance_name}
  local-hostname: ${local.hostname}
  EOT

  user_data = <<-EOF
  #cloud-config
  hostname: ${local.hostname}
  fqdn: ${local.fqdn}
  prefer_fqdn_over_hostname: true
  ${var.virtual_machine.user != null || try(coalesce(var.virtual_machine.root_password, ""), "") != "" ? "users:" : ""}
  ${var.virtual_machine.user != null ? <<-EOT
      - name: ${var.virtual_machine.user.username}
        gecos: ${var.virtual_machine.user.display_name}
        hashed_passwd: ${var.virtual_machine.user.password}
        lock-passwd: false
        sudo: ${var.virtual_machine.user.sudo_rule}
        ssh_authorized_keys:
          - ${var.virtual_machine.user.ssh_public_key}
    EOT
  : ""}
  ${try(coalesce(var.virtual_machine.root_password, ""), "") != "" ? <<-EOT
      - name: root
        hashed_passwd: ${var.virtual_machine.root_password}
        lock-passwd: false
    EOT
: ""}
  EOF
}

resource "libvirt_volume" "virtual_machine" {
  name             = "${local.fqdn}-disk1.qcow2"
  base_volume_name = var.virtual_machine.os_image
  pool             = var.hypervisor.storage_pool
  size             = local.vm_disk_size
}

resource "libvirt_domain" "virtual_machine" {
  name        = local.instance_name
  description = local.description
  vcpu        = var.virtual_machine.cpu_count
  memory      = local.vm_ram_size

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  autostart = true

  qemu_agent = true

  network_interface {
    bridge         = var.hypervisor.network_bridge
    mac            = var.virtual_machine.mac_address
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  cpu {
    mode = var.virtual_machine.cpu_mode
  }

  disk {
    volume_id = libvirt_volume.virtual_machine.id
  }

  graphics {
    type = "vnc"
  }
}
