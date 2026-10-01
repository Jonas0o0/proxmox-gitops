resource "proxmox_virtual_environment_vm" "this" {
  tags = var.tags
  vm_id     = var.vm_id
  name      = var.name
  node_name = var.node_name
  cpu {
    cores = var.cpu
    type  = "host"
  }

  memory {
    dedicated = var.memory
    floating  = 512
  }

  clone {
    vm_id = var.vm_template_id
    datastore_id = var.target_datastore_id
  }

  disk {
    datastore_id = var.target_datastore_id
    interface    = "scsi0"
    size         = var.disk_size
    iothread     = true
    discard      = "on"
  }

  agent {
    enabled = true
    timeout = "600s"
  }

  network_device {
    bridge  = var.bridge
    firewall = var.firewall
    vlan_id = var.vlan_id
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.vm_ip}/24"
        gateway = var.network_gateway
      }
    }
    datastore_id = var.target_datastore_id

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys     = [trimspace(file(pathexpand(var.ssh_public_key_path)))]
      username = var.username
    }
    user_data_file_id = proxmox_virtual_environment_file.boostrap_user_data.id
  }

  lifecycle {
    ignore_changes = [
      initialization[0].user_data_file_id,
      initialization[0].meta_data_file_id,
      initialization[0].network_data_file_id,
      initialization[0].vendor_data_file_id,
      network_device[0].mac_address,
      boot_order,
      vga,
    ]
  }
}

resource "proxmox_virtual_environment_firewall_options" "this" {
  count = var.firewall ? 1 : 0

  node_name = proxmox_virtual_environment_vm.this.node_name
  vm_id     = proxmox_virtual_environment_vm.this.vm_id

  enabled       = true
  input_policy  = "ACCEPT"
  output_policy = "ACCEPT"
}

resource "proxmox_virtual_environment_file" "boostrap_user_data" {
  content_type = "snippets"
  datastore_id = var.backup_datastore_id # encrypted-zfs ne peut pas supporter autre chose que des vm, ne pas changer ça. ca va stocker les fichiers de cloud init
  node_name    = var.node_name

  source_raw {
    file_name = "${var.name}-user-data.yaml"
    # On passe directement la string générée par le parent
    data      = var.user_data_raw
  }
}
