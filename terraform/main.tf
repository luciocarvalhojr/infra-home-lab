# ─────────────────────────────────────────────
# K3s Control Plane
# ─────────────────────────────────────────────
module "controlplane" {
  source = "github.com/luciocarvalhojr/terraform-modules//modules/proxmox-vm?ref=v1.0.0"

  name           = "k3s-cp-01"
  vm_id          = 300
  proxmox_node   = var.proxmox_node
  template_id    = var.template_id
  cores          = var.controlplane_cores
  memory         = var.controlplane_memory
  disk           = var.controlplane_disk
  ip             = var.controlplane_ip
  gateway        = var.gateway
  dns_servers    = var.dns_servers
  ssh_public_key = var.ssh_public_key
  tags           = ["k3s", "controlplane"]
}

# ─────────────────────────────────────────────
# K3s Worker Nodes
# ─────────────────────────────────────────────
module "workers" {
  source = "github.com/luciocarvalhojr/terraform-modules//modules/proxmox-vm?ref=v1.0.0"
  count = var.worker_count
  name           = "k3s-wkr-${count.index + 1}"
  vm_id          = 301 + count.index
  proxmox_node   = var.proxmox_node
  template_id    = var.template_id
  cores          = var.worker_cores
  memory         = var.worker_memory
  disk           = var.worker_disk
  ip             = var.worker_ips[count.index]
  gateway        = var.gateway
  dns_servers    = var.dns_servers
  ssh_public_key = var.ssh_public_key
  tags           = ["worker", "k3s"]
}

# ─────────────────────────────────────────────
# Generate Ansible inventory from Terraform state
# ─────────────────────────────────────────────
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    controlplane_ip      = var.controlplane_ip
    worker_ips           = var.worker_ips
    ssh_user             = var.ansible_user
    ssh_private_key_file = var.ssh_private_key_file
  })
  filename        = "${path.module}/../ansible/inventory.yml"
  file_permission = "0644"
}

# ─────────────────────────────────────────────
# Run Ansible after VMs are provisioned
# ─────────────────────────────────────────────
resource "null_resource" "ansible" {
  depends_on = [
    module.controlplane,
    module.workers,
    local_file.ansible_inventory,
  ]

  triggers = {
    controlplane_id = module.controlplane.vm_id
    worker_ids      = join(",", module.workers[*].vm_id)
  }

  provisioner "local-exec" {
    command = <<-EOT
      ansible-playbook \
        -i ${path.module}/../ansible/inventory.yml \
        ${path.module}/../ansible/k3s.yml
    EOT
  }
}
