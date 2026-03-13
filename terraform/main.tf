# ─────────────────────────────────────────────
# K3s Control Plane
# ─────────────────────────────────────────────
resource "proxmox_virtual_environment_vm" "k3s_controlplane" {
  name      = "k8s-controlplane-01"
  node_name = var.proxmox_node
  vm_id     = 200

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true  # requires qemu-guest-agent in the template
  }

  cpu {
    cores = var.controlplane_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.controlplane_memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.controlplane_disk
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"  # Linux kernel 2.6+
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${var.controlplane_ip}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.dns_server]
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "controlplane"]
}

# ─────────────────────────────────────────────
# K3s Workers
# ─────────────────────────────────────────────
resource "proxmox_virtual_environment_vm" "k3s_workers" {
  count     = var.worker_count
  name      = "k8s-worker-0${count.index + 1}"
  node_name = var.proxmox_node
  vm_id     = 201 + count.index

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.worker_cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.worker_memory
  }

  disk {
    datastore_id = "local-lvm"
    size         = var.worker_disk
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "${var.worker_ips[count.index]}/24"
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.dns_server]
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }

  tags = ["k3s", "worker"]
}
