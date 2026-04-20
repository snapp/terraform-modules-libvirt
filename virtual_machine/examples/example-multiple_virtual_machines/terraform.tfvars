
hypervisor = {
  fqdn           = "vhost.example.com"
  network_bridge = "br0"
  storage_pool   = "default"
  ssh_user       = "example_user"
}

virtual_machine = {
  contact       = "example_user"
  disk_size     = 20
  os_image      = "rhel-9.2-x86_64-kvm.qcow2"
  root_password = "$6$jTp9SaGn$Au:$BPw0knTDB.nDTfv2iWV/Xrgg/bWcdUp4xQL25HvIg23/YKMQ/YFP3MrwdeF/taqx3VYeORyhjMIrERSNZMNhx0"
  user = {
    username       = "example_user"
    display_name   = "Example User"
    password       = "$6$z0wV@xKa9We7nG)4$TDvRlr7akpcqwUMxYaND./MmMSIaRgtN2jDKnUYo5L0CvqMiQCdk3fxru422TEs.Qa3HC/uhoR4C6JaKBFpon."
    ssh_public_key = "ssh-rsa AAAABBBCCC..."
    sudo_rule      = "ALL=(ALL) NOPASSWD:ALL"
  }
}
