# Proxmox
variable "proxmox_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.0.90:8006" # ← your Proxmox IP
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
  default     = "hyper01" # ← your Proxmox node name (check in UI)
}

# VM template
variable "template_id" {
  description = "Proxmox VM template ID (Ubuntu 24.04 cloud image)"
  type        = number
  default     = 9000 # ← ID you'll assign when creating the template
}

# SSH
variable "ssh_public_key" {
  description = "SSH public key injected into VMs via cloud-init"
  type        = string
}

variable "ssh_private_key_file" {
  description = "Path to SSH private key used by Ansible to connect to VMs"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ansible_user" {
  description = "OS user created by cloud-init on VMs"
  type        = string
  default     = "ubuntu"
}

# Network
variable "gateway" {
  description = "Network gateway"
  type        = string
  default     = "192.168.0.1"
}

variable "dns_servers" {
  description = "DNS servers"
  type        = list(string)
  default     = ["192.168.0.100", "192.168.0.110"]
}

# K3s control plane
variable "controlplane_ip" {
  description = "Static IP for the control plane VM"
  type        = string
  default     = "192.168.0.130"
}

variable "controlplane_cores" {
  description = "CPU cores for control plane"
  type        = number
  default     = 1
}

variable "controlplane_memory" {
  description = "RAM in MB for control plane"
  type        = number
  default     = 1024
}

variable "controlplane_disk" {
  description = "Disk size in GB for control plane"
  type        = number
  default     = 8
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
  default     = ["192.168.0.131", "192.168.0.132", "192.168.0.133"]
}

variable "worker_cores" {
  description = "CPU cores per worker"
  type        = number
  default     = 1
}

variable "worker_memory" {
  description = "RAM in MB per worker"
  type        = number
  default     = 1024
}

variable "worker_disk" {
  description = "Disk size in GB per worker"
  type        = number
  default     = 8
}

# Minio S3-compatible backend for Terraform state
variable "region" {
  description = "Region for S3 backend (ignored by Minio but required by Terraform)"
  type        = string
  default     = "main"
}

variable "access_key" {
  description = "Minio access key for S3 backend"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Minio secret key for S3 backend"
  type        = string
  sensitive   = true
}

variable "endpoint" {
  description = "Minio endpoint for S3 backend"
  type        = string
  default     = "http://192.168.0.95:9000"
}
