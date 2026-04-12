---
marp: true
theme: gaia
paginate: true
style: |
  :root {
    --color-background: #FFFFFF;
    --color-foreground: #151515;
    --color-highlight: #EE0000;
  }

  header {
    color: #EE0000;
    font-size: 18px;
  }

  section {
    font-size: 28px;
  }

  section::after {
    font-size: 18px;
  }

  h1 {
    color: #EE0000;
  }

  h2 {
    color: #A60000;
  }

  table {
    font-size: 22px;
    width: 100%;
  }

  table thead tr th {
    background-color: #F56E6E;
    color: #FFFFFF;
  }

  table tbody tr:nth-child(even) {
    background-color: #F5F5F5;
  }

  pre {
    background-color: #E0E0E0;
    font-size: 18px;
  }

  code {
    background-color: #E0E0E0;
    color: #151515;
    font-family: monospace;
  }

  ul li {
    margin-bottom: 6px;
  }

  .columns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }

---
<!--
_class: lead
_paginate: false
-->

# Terraform Libvirt Module
## `virtual_machine`

Declarative KVM virtual machine provisioning with cloud-init and Ansible inventory integration

---
<!--
header: "Terraform Libvirt — virtual_machine module"
-->

## Agenda

1. What the module does
2. Providers and resources
3. First-boot: cloud-init
4. Networking modes
5. Ansible inventory integration
6. `ansible_host` and ProxyJump
7. Key variables reference
8. Usage examples
9. Networking mode comparison

---

## What the Module Does

A single Terraform module that provisions a **fully configured KVM virtual machine** on a remote libvirt hypervisor — from a QCOW2 backing image to a live, Ansible-reachable host.

**One `module` block gives you:**
- A KVM domain (CPU, RAM, disk, NIC) via the `dmacvicar/libvirt` provider
- A cloud-init ISO injected at first boot (hostname, users, SSH keys, passwords)
- An Ansible inventory host entry via the `ansible/ansible` provider
- Automatic IP detection — waits for SSH readiness before declaring success

---

## Providers and Resources

```
dmacvicar/libvirt  ─── libvirt_cloudinit_disk   cloud-init ISO content
                   ─── libvirt_volume (×2)       cloudinit ISO + OS disk
                   └── libvirt_domain            KVM domain (the VM itself)

hashicorp/random   └── random_id                 unique suffix when name omitted

hashicorp/terraform └── terraform_data           wait_for_ip provisioner

ansible/ansible    └── ansible_host              inventory host + variables
```

The libvirt provider connects to the hypervisor over **`qemu+ssh`** — no agent or API server required on the hypervisor.

---

## First Boot: cloud-init

The module builds a **cloud-init ISO** and attaches it as a virtual CD-ROM. On first boot the guest reads it and configures itself.

**What cloud-init sets:**

- Hostname and FQDN (`prefer_fqdn_over_hostname: true`)
- Optional named user — username, display name, hashed password, SSH public key, sudo rule
- Optional root password (hashed)
- `instance-id` in meta-data for idempotent re-runs

No SSH access to the hypervisor or guest is required during the cloudinit phase — the ISO is injected as a device before the domain boots.

---

## Networking Modes

The module supports three NIC configurations via two optional `hypervisor` attributes:

| Mode | `network_bridge` | `network_name` | Use case |
|---|---|---|---|
| **Bridge** | set | — | VM gets a routable LAN IP |
| **NAT only** | — | set | VM routes through host; inherits host network access |
| **Dual-NIC** | set | set | Routable IP + host-routed egress on second NIC |

At least one must be set. The validation block enforces this at `terraform plan` time.

---

## Bridge Mode

```
┌──────────────────────────────────┐
│  Hypervisor                      │
│                                  │
│   VM ──── br0 ──── LAN ──── you  │
│           (bridge)               │
│                                  │
│   VM IP: 10.0.1.50 (DHCP/static) │
└──────────────────────────────────┘
```

- VM gets a **directly routable** IP on the physical network
- `ansible_host` is set to that IP — Ansible connects directly
- Specify `network_bridge = "br0"` (or your bridge device name)

---

## NAT Mode

```
┌──────────────────────────────────────────────────┐
│  Hypervisor                                      │
│                                                  │
│   VM ── virbr0 ── host routing ── hypervisor     │
│          NAT     (inherits host network access)  │
│                                                  │
│   VM IP: 192.168.122.50 (private)                │
│   Ansible: ProxyJump → hypervisor → VM           │
└──────────────────────────────────────────────────┘
```

- VM inherits the **hypervisor's routing table** — it can reach what the hypervisor can reach
- VM has no directly routable address
- `ansible_ssh_common_args` is **automatically injected** with a ProxyJump
- Specify `network_name = "default"` (libvirt's built-in NAT network)

---

## Dual-NIC Mode

```
┌────────────────────────────────────────────────┐
│  Hypervisor                                    │
│                                                │
│   VM ─┬─ br0 ──── LAN ──────── you            │
│        │  (eth0 — routable, 10.0.1.50)         │
│        │                                       │
│        └─ virbr0 ── host routing               │
│           (eth1 — NAT, inherits host access)   │
│                                                │
│   Ansible connects directly via eth0 IP        │
└────────────────────────────────────────────────┘
```

- Bridge NIC is always **first** → guest OS assigns it as `eth0`/`ens3`
- `ansible_host` is the bridge IP — NAT IPs are excluded via `nat_cidr`
- No ProxyJump needed; bridge IP is directly reachable

---

## Ansible Inventory Integration

When `enable_ansible_inventory = true`, the module creates an `ansible_host` resource that writes a host entry into the **Ansible provider's dynamic inventory**.

**Always-present host variables:**

| Variable | Value |
|---|---|
| `instance_name` | Libvirt domain name |
| `hostname` | Short hostname |
| `domain` | Network domain |
| `description` | Human-readable description |

Groups default to `["terraform_managed"]` unless `groups` is specified.

---

## `ansible_host` and ProxyJump

**`ansible_host_override = true`** triggers IP detection and sets `ansible_host` to the VM's IPv4 address. The module also injects connection arguments automatically:

| Mode | `ansible_host` | `ansible_ssh_common_args` |
|---|---|---|
| Bridge | Bridge IP | *(not set)* |
| NAT only | NAT IP | `-o ProxyJump=user@hypervisor` |
| Dual-NIC | Bridge IP (NAT CIDR excluded) | *(not set)* |

The **IP readiness probe** (`wait_for_ip`) polls `virsh domifaddr` over SSH until the guest agent reports the target IP and port 22 is reachable — surviving any first-boot reboot.

---

## Key `hypervisor` Variables

| Attribute | Type | Default | Description |
|---|---|---|---|
| `fqdn` | `string` | required | Hypervisor hostname |
| `ssh_user` | `string` | required | SSH user for `qemu+ssh` |
| `storage_pool` | `string` | required | Libvirt storage pool name |
| `network_bridge` | `string` | `null` | Host bridge device (bridge mode) |
| `network_name` | `string` | `null` | Libvirt network name (NAT mode) |
| `nat_cidr` | `string` | `192.168.122.0/24` | NAT network CIDR (dual-NIC IP filtering) |

---

## Key `virtual_machine` Variables

| Attribute | Type | Default | Description |
|---|---|---|---|
| `hostname` | `string` | required | Short hostname |
| `domain` | `string` | `"local"` | Network domain |
| `cpu_count` | `number` | required | vCPU count |
| `ram_size` | `number` | required | RAM in GB |
| `disk_size` | `number` | required | Disk in GB |
| `os_image` | `string` | required | Backing QCOW2 name in storage pool |
| `mac_address` | `string` | `null` | Optional — libvirt auto-generates if omitted |
| `ansible_host_override` | `bool` | `false` | Enable IP detection + `ansible_host` injection |
| `extra_vars` | `map(string)` | `{}` | Additional Ansible host variables |

---

## Usage: Bridge Mode

```hcl
module "webserver" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=main"

  hypervisor = {
    fqdn           = "kvm1.example.com"
    ssh_user       = "admin"
    storage_pool   = "default"
    network_bridge = "br0"
  }

  virtual_machine = {
    hostname              = "webserver"
    domain                = "example.com"
    contact               = "alice"
    cpu_count             = 2
    cpu_mode              = "host-passthrough"
    ram_size              = 4
    disk_size             = 20
    os_image              = "rhel10-base.qcow2"
    enable_ansible_inventory = true
    ansible_host_override    = true
    # ...
  }
}
```

---

## Usage: NAT Mode

```hcl
module "nat_host" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=main"

  hypervisor = {
    fqdn         = "kvm2.example.com"
    ssh_user     = "admin"
    storage_pool = "default"
    network_name = "default"          # libvirt NAT network
  }

  virtual_machine = {
    hostname                 = "nat-host"
    domain                   = "example.com"
    contact                  = "bob"
    cpu_count                = 2
    cpu_mode                 = "host-passthrough"
    ram_size                 = 4
    disk_size                = 20
    os_image                 = "rhel10-base.qcow2"
    enable_ansible_inventory = true
    ansible_host_override    = true   # ProxyJump injected automatically
    # ...
  }
}
```

---

## Usage: Dual-NIC Mode

```hcl
module "service_host" {
  source = "git::https://github.com/snapp/terraform-modules-libvirt.git//virtual_machine?ref=main"

  hypervisor = {
    fqdn           = "kvm2.example.com"
    ssh_user       = "admin"
    storage_pool   = "default"
    network_bridge = "br0"            # eth0 — routable LAN IP
    network_name   = "default"        # eth1 — NAT (inherits host network access)
    # nat_cidr = "192.168.122.0/24"   # default; override if needed
  }

  virtual_machine = {
    hostname                 = "service-host"
    domain                   = "example.com"
    contact                  = "carol"
    cpu_count                = 4
    cpu_mode                 = "host-passthrough"
    ram_size                 = 8
    disk_size                = 40
    os_image                 = "rhel10-base.qcow2"
    enable_ansible_inventory = true
    ansible_host_override    = true   # bridge IP selected; no ProxyJump
    # ...
  }
}
```

---

## Networking Mode Comparison

| | Bridge | NAT only | Dual-NIC |
|---|---|---|---|
| **Routable LAN IP** | ✅ Yes | ❌ No | ✅ Yes (eth0) |
| **Inherits host network access** | ❌ No | ✅ Yes | ✅ Yes (eth1) |
| **Ansible connects via** | Direct | ProxyJump | Direct |
| **ProxyJump injected** | No | ✅ Auto | No |
| **`nat_cidr` used** | No | No | ✅ IP filtering |
| **MAC address supported** | ✅ Optional | N/A | ✅ Bridge NIC only |
| **`network_bridge`** | Set | Omit | Set |
| **`network_name`** | Omit | Set | Set |

---

## Resources

**dmacvicar/libvirt Terraform provider**
- [Registry: dmacvicar/libvirt](https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs)

**Ansible Terraform provider**
- [Registry: ansible/ansible](https://registry.terraform.io/providers/ansible/ansible/latest/docs)

**libvirt networking**
- [libvirt: Virtual Networking](https://wiki.libvirt.org/VirtualNetworking.html)

**cloud-init**
- [cloud-init documentation](https://cloudinit.readthedocs.io/en/latest/)
