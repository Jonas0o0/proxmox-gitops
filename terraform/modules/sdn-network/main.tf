# repris de https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/sdn_vnet

resource "proxmox_sdn_vnet" "prvvnet1" {
  id            = var.vnet_id
  zone          = var.zone_id
  alias         = "VNET"
  isolate_ports = false
  vlan_aware    = false
}

resource "proxmox_virtual_environment_sdn_subnet" "sub_prvvnet1" {
  cidr    = var.subnet_cidr
  vnet = proxmox_sdn_vnet.prvvnet1.id
  gateway = var.subnet_gateway
  snat = true
}

# = restart le network
resource "proxmox_sdn_applier" "vnet_applier" {
  depends_on = [
    proxmox_sdn_vnet.prvvnet1,
    proxmox_virtual_environment_sdn_subnet.sub_prvvnet1
  ]
}
