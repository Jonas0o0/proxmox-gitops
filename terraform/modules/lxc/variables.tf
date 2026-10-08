variable "name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "lxc_id" {
  type = number
}

variable "lxc_ip" {
  type = string
}

variable "network_gateway" {
  type = string
}

variable "ssh_public_key_path" {
  type = string
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

variable "target_datastore_id" {
  type    = string
  default = "encrypted-zfs"
}

variable "template_file_id" {
  type    = string
  default = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
}

variable "os_type" {
  type    = string
  default = "debian"
}

variable "bridge" {
  type = string
}

variable "vlan_id" {
  type    = number
  default = null
}

variable "firewall" {
  description = "Active le pare-feu Proxmox sur l'interface réseau du conteneur"
  type        = bool
  default     = false
}

variable "nesting" {
  type    = bool
  default = true
}

variable "tags" {
  type = list(string)
  default = ["untagged"]
}