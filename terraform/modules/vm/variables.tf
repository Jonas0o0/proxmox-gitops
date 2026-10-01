variable "name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "vm_template_id" {
  type = number
}

variable "vm_ip" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "user_data_raw" {
  description = "Le contenu brut du fichier cloud-init généré par le parent"
  type        = string
}

variable "target_datastore_id" {
  type=string
  default= "encrypted-zfs"
}

# variable "hostname" {
#   type = string 
#   default = "hostname-a-remplacer-alloy-en-a-besoin"
# }

variable "network_gateway" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
}

variable "username" {
  type    = string
  default = "debian"
}

variable "cpu" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 2048
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "bridge" {
  type = string
}

variable "vlan_id" {
  type    = number
  default = null
}

variable "firewall" {
  description = "Active le pare-feu Proxmox sur l'interface réseau de la VM"
  type        = bool
  default     = false
}


variable "tags" {
  type = list(string)
  default = ["untagged"]
}

variable "dns_servers" {
  type = list(string)
  default = ["192.168.10.12", "1.1.1.1", "8.8.8.8"]
}

variable "backup_datastore_id" {
  type    = string
  default = "local"
}
