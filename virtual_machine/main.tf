terraform {
  required_version = ">=1.5.0"

  required_providers {
    # https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.9.1"
    }

    # https://registry.terraform.io/providers/ansible/ansible/latest/docs
    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
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

    interfaces = local.vm_interfaces

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

    # qemu-guest-agent communicates with the host over a virtio-serial unix socket
    channels = [{
      source = {
        unix = {}
      }
      target = {
        virt_io = {
          name = "org.qemu.guest_agent.0"
        }
      }
    }]
  }
}

# Poll virsh domifaddr over SSH until the guest agent reports an IPv4 address or
# the 300s timeout expires. The data source depends on this so it only runs once
# the IP is confirmed available, avoiding an empty interfaces list on first apply.
resource "terraform_data" "wait_for_ip" {
  count = var.virtual_machine.ansible_host_override ? 1 : 0

  triggers_replace = [libvirt_domain.virtual_machine.uuid]

  provisioner "local-exec" {
    command = <<-EOF
      # Phase 1: wait for the target IPv4 address to appear via the guest agent.
      # Loopback (127.x.x.x) is always excluded. In dual-NIC mode the NAT prefix
      # ("${local.nat_addr_prefix}") is also excluded so we wait for the bridge IP.
      # An empty nat prefix means no NAT filtering (bridge-only or NAT-only mode).
      echo "Waiting for ${local.instance_name} to obtain an IP address..."
      elapsed=0
      until ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
          ${var.hypervisor.ssh_user}@${var.hypervisor.fqdn} \
          "virsh --connect qemu:///system domifaddr ${local.instance_name} --source agent 2>/dev/null \
           | awk -v nat='${local.nat_addr_prefix}' \
               '/ipv4/ && !/127\./ && (nat == \"\" || index(\$4, nat) != 1) {print \$4}' \
           | grep -q ."; do
        if [ "$elapsed" -ge 600 ]; then
          echo "Timed out after 600s waiting for ${local.instance_name} to get an IP address"
          exit 1
        fi
        sleep 10
        elapsed=$((elapsed + 10))
      done

      # Extract the target IPv4 address for use in phase 2 (same NAT filtering as above).
      IP=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
          ${var.hypervisor.ssh_user}@${var.hypervisor.fqdn} \
          "virsh --connect qemu:///system domifaddr ${local.instance_name} --source agent 2>/dev/null \
           | awk -v nat='${local.nat_addr_prefix}' \
               '/ipv4/ && !/127\./ && (nat == \"\" || index(\$4, nat) != 1) {print \$4}' \
           | head -1 | cut -d/ -f1")

      # Phase 2: wait for SSH port 22 to be reachable from the hypervisor.
      # This ensures the VM has survived any first-boot reboot (e.g. OpenSCAP remediation)
      # and is fully up before the data source reads the guest agent.
      echo "${local.instance_name} has IP $IP, waiting for SSH to become available..."
      elapsed=0
      until ssh -o BatchMode=yes -o StrictHostKeyChecking=no \
          ${var.hypervisor.ssh_user}@${var.hypervisor.fqdn} \
          "nc -z -w 5 $IP 22 2>/dev/null"; do
        if [ "$elapsed" -ge 600 ]; then
          echo "Timed out after 600s waiting for SSH on ${local.instance_name} ($IP)"
          exit 1
        fi
        sleep 10
        elapsed=$((elapsed + 10))
      done
      echo "${local.instance_name} ($IP) is ready"
    EOF
  }
}

# https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/data-sources/domain_interface_addresses
data "libvirt_domain_interface_addresses" "virtual_machine" {
  count  = var.virtual_machine.ansible_host_override ? 1 : 0
  domain = libvirt_domain.virtual_machine.uuid
  source = "agent"

  depends_on = [terraform_data.wait_for_ip]
}

# https://registry.terraform.io/providers/ansible/ansible/latest/docs/resources/host
resource "ansible_host" "virtual_machine" {
  count  = var.virtual_machine.enable_ansible_inventory ? 1 : 0
  name   = local.fqdn
  groups = length(coalesce(var.virtual_machine.groups, [])) > 0 ? var.virtual_machine.groups : ["terraform_managed"]
  variables = merge(
    {
      instance_name = local.instance_name
      hostname      = local.hostname
      domain        = local.domain
      description   = local.description
    },
    var.virtual_machine.ansible_host_override ? {
      # In dual-NIC mode, cidrcontains excludes the NAT interface's address so Ansible
      # connects via the bridge IP. In single-NIC mode the CIDR filter is not applied.
      ansible_host = one([
        for addr in flatten([
          for iface in data.libvirt_domain_interface_addresses.virtual_machine[0].interfaces
          : iface.addrs
        ])
        : addr.addr
        if addr.type == "ipv4"
        && !startswith(addr.addr, "127.")
        && (!local.dual_nic || !startswith(addr.addr, local.nat_addr_prefix))
      ])
    } : {},
    # In NAT-only mode the VM has no directly routable address; inject a ProxyJump so
    # Ansible tunnels through the hypervisor. In bridge or dual-NIC mode the bridge IP
    # is directly reachable, so no ProxyJump is needed. extra_vars can override if needed.
    local.nat_only && var.virtual_machine.ansible_host_override ? {
      ansible_ssh_common_args = "-o ProxyJump=${var.hypervisor.ssh_user}@${var.hypervisor.fqdn}"
    } : {},
    var.virtual_machine.extra_vars
  )
}
