terraform {
  required_version = ">=1.5.0"
}

# Bridge mode — VM gets a directly routable LAN IP.
# Ansible connects by FQDN; no ansible_host_override needed if DNS resolves the VM.
module "bridge" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=1462adf"

  hypervisor = merge(var.hypervisor, {
    network_bridge = var.hypervisor.network_bridge
    network_name   = null
  })

  virtual_machine = merge(var.virtual_machine, {
    name                     = "test-bridge"
    hostname                 = "bridge-vm"
    domain                   = "example.com"
    description              = "Bridge mode — routable LAN IP, Ansible connects by FQDN."
    groups                   = ["terraform_managed"]
    enable_ansible_inventory = true
    ansible_host_override    = false
  })
}

# Bridge mode with ansible_host_override — Ansible connects by IP instead of FQDN.
# Useful when DNS resolution of the VM hostname is unreliable or not yet propagated.
module "bridge_with_ip" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=1462adf"

  hypervisor = merge(var.hypervisor, {
    network_bridge = var.hypervisor.network_bridge
    network_name   = null
  })

  virtual_machine = merge(var.virtual_machine, {
    name                     = "test-bridge-with-ip"
    hostname                 = "bridge-ip-vm"
    domain                   = "example.com"
    description              = "Bridge mode — ansible_host set to the VM's LAN IP."
    groups                   = ["terraform_managed"]
    enable_ansible_inventory = true
    ansible_host_override    = true
  })
}

# NAT mode — VM has no directly routable address; all traffic routes through the
# hypervisor's network stack so the VM inherits the hypervisor's network access.
# ansible_ssh_common_args is automatically injected with a ProxyJump through the hypervisor.
module "nat" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=1462adf"

  hypervisor = merge(var.hypervisor, {
    network_bridge = null
    network_name   = "default"
  })

  virtual_machine = merge(var.virtual_machine, {
    name                     = "test-nat"
    hostname                 = "nat-vm"
    domain                   = "example.com"
    description              = "NAT mode — VM inherits hypervisor network access; ProxyJump injected."
    groups                   = ["terraform_managed"]
    enable_ansible_inventory = true
    ansible_host_override    = true
  })
}

# Dual-NIC mode — bridge NIC (eth0) provides a routable LAN IP for direct Ansible access;
# NAT NIC (eth1) gives the VM access to networks reachable from the hypervisor.
# Ansible connects directly via the bridge IP; no ProxyJump is injected.
module "dual_nic" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=1462adf"

  hypervisor = merge(var.hypervisor, {
    network_bridge = var.hypervisor.network_bridge
    network_name   = "default"
  })

  virtual_machine = merge(var.virtual_machine, {
    name                     = "test-dual-nic"
    hostname                 = "dual-nic-vm"
    domain                   = "example.com"
    description              = "Dual-NIC — routable LAN IP (eth0) + hypervisor network access via NAT (eth1)."
    groups                   = ["terraform_managed"]
    enable_ansible_inventory = true
    ansible_host_override    = true
  })
}
