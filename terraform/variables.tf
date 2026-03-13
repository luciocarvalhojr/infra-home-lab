# Proxmox
variable "proxmox_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.0.XXX:8006"  # ← your Proxmox IP
}

variable "proxmox_user" {
  description = "Proxmox API user (format: user@realm)"
  type        = string
  default     = "terraform@pve"
}

variable "proxmox_password" {
  description = "Proxmox API password"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"  # ← your Proxmox node name (check in UI)
}

# VM template
variable "template_id" {
  description = "Proxmox VM template ID (Ubuntu 24.04 cloud image)"
  type        = number
  default     = 9000  # ← ID you'll assign when creating the template
}

# SSH
variable "ssh_public_key" {
  description = "SSH public key injected into VMs via cloud-init"
  type        = string
}

# Network
variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.0.1"
}

variable "dns_server" {
  description = "DNS server"
  type        = string
  default     = "192.168.0.1"
}

# K3s control plane
variable "controlplane_ip" {
  description = "Static IP for the control plane VM"
  type        = string
  default     = "192.168.0.150"
}

variable "controlplane_cores" {
  description = "CPU cores for control plane"
  type        = number
  default     = 4
}

variable "controlplane_memory" {
  description = "RAM in MB for control plane"
  type        = number
  default     = 8192
}

variable "controlplane_disk" {
  description = "Disk size in GB for control plane"
  type        = number
  default     = 50
}

# K3s workers
variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "worker_ips" {
  description = "Static IPs for worker nodes"
  type        = list(string)
  default     = ["192.168.0.151", "192.168.0.152", "192.168.0.153"]
}

variable "worker_cores" {
  description = "CPU cores per worker"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "RAM in MB per worker"
  type        = number
  default     = 8192
}

variable "worker_disk" {
  description = "Disk size in GB per worker"
  type        = number
  default     = 100
}
