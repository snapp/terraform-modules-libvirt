output "virtual_machines" {
  description = <<-EOT
        id : "The unique id of the virtual machine."
        name : The name of the virtual machine instance when listed on the hypervisor.
        ipv4_address : "The ipv4 address of the virtual machine."
    EOT
  value = [
    {
      id           = module.test1.id
      name         = module.test1.name
      ipv4_address = module.test1.ipv4_address[0]
    },
    {
      id           = module.test2.id
      name         = module.test2.name
      ipv4_address = module.test2.ipv4_address[0]
    },
    {
      id           = module.test3.id
      name         = module.test3.name
      ipv4_address = module.test3.ipv4_address[0]
    },
    {
      id           = module.test4.id
      name         = module.test4.name
      ipv4_address = module.test4.ipv4_address[0]
    }
  ]
}
