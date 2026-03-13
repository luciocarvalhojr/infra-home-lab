output "controlplane_ip" {
  description = "Control plane IP address"
  value       = var.controlplane_ip
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value       = var.worker_ips
}

output "ansible_inventory" {
  description = "Ready-to-use Ansible inventory"
  value = templatefile("${path.module}/../ansible/inventory.yml.tpl", {
    controlplane_ip = var.controlplane_ip
    worker_ips      = var.worker_ips
  })
}
