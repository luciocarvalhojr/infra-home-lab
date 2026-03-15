output "controlplane_ip" {
  description = "Control plane IP address"
  value       = var.controlplane_ip
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value       = var.worker_ips
}

output "ansible_inventory_path" {
  description = "Path to the generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}
