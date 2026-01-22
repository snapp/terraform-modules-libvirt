terraform {
  required_version = ">=1.5.0"

  required_providers {
    # https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.9.1"
    }

    # https://registry.terraform.io/providers/hashicorp/random/latest/docs
    random = {
      source  = "hashicorp/random"
      version = ">=3.8.0"
    }
  }
}

provider "libvirt" {
  uri = local.libvirt_uri
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name = "${local.fqdn}-cloudinit.iso"

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

resource "libvirt_volume" "cloudinit" {
  name = "${local.fqdn}-cloudinit.iso"
  pool = var.hypervisor.storage_pool

  create = {
    content = {
      url = libvirt_cloudinit_disk.cloudinit.path
    }
  }
}

resource "libvirt_volume" "virtual_machine" {
  name          = "${local.fqdn}-disk1.qcow2"
  pool          = var.hypervisor.storage_pool
  capacity      = local.vm_disk_size
  capacity_unit = "bytes"
  backing_store = {
    path = var.virtual_machine.os_image
    format = {
      type = "qcow2"
    }
  }
  target = {
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_domain" "virtual_machine" {
  name        = local.instance_name
  description = local.description
  vcpu        = var.virtual_machine.cpu_count
  memory      = local.vm_ram_size
  memory_unit = "MiB"
  type        = "kvm"

  autostart = true
  running   = true

  os = {
    type      = "hvm"
    type_arch = "x86_64"
  }

  cpu = {
    mode = var.virtual_machine.cpu_mode
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }

        source = {
          volume = {
            pool   = var.hypervisor.storage_pool
            volume = libvirt_volume.virtual_machine.name
          }
        }

        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        device    = "cdrom"
        read_only = true
        serial    = "cloudinit"

        driver = {
          name = "qemu"
          type = "raw"
        }

        source = {
          volume = {
            pool   = var.hypervisor.storage_pool
            volume = libvirt_cloudinit_disk.cloudinit.name
          }
        }

        target = {
          dev = "hdd"
          bus = "ide"
        }
      }
    ]

    interfaces = [
      {
        mac = {
          address = var.virtual_machine.mac_address
        }

        source = {
          bridge = {
            bridge = var.hypervisor.network_bridge
          }
        }
      }
    ]

    consoles = [{
      target = {
        type = "serial"
      }
    }]

    graphics = [{
      vnc = {
        auto_port = true
      }
    }]
  }
}
