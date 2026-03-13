# infrastructure

Terraform + Ansible to provision and configure the K3s home lab cluster on Proxmox.

## Stack

| Tool | Role |
|---|---|
| Proxmox | Hypervisor |
| Terraform (`bpg/proxmox`) | VM provisioning |
| Minio | Terraform remote state (S3-compatible) |
| cloud-init | First-boot OS config (injected by Terraform) |
| Ansible | K3s install + cluster config |

## Topology

```
Proxmox (single node)
├── k8s-controlplane-01  192.168.0.150  4 vCPU  8GB RAM  50GB
├── k8s-worker-01        192.168.0.151  4 vCPU  8GB RAM  100GB
├── k8s-worker-02        192.168.0.152  4 vCPU  8GB RAM  100GB
└── k8s-worker-03        192.168.0.153  4 vCPU  8GB RAM  100GB
```

## Prerequisites

### 1. Ubuntu 24.04 cloud image template in Proxmox

```bash
# On your Proxmox host
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

qm create 9000 --name ubuntu-24.04-template --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 noble-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

### 2. Terraform API user in Proxmox

```bash
# On your Proxmox host
pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"
pveum user add terraform@pve --password your-password
pveum aclmod / -user terraform@pve -role TerraformRole
```

### 3. Minio bucket for Terraform state

Create a bucket named `terraform-state` in your Minio instance and update `versions.tf` with your Minio IP and credentials.

### 4. Local tools

```bash
brew install terraform ansible
```

## Usage

### Provision VMs

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

### Install K3s

```bash
cd ansible
ansible-playbook -i inventory.yml playbooks/k3s.yml
```

Kubeconfig will be saved to `kubeconfig.yml` in the repo root (gitignored).

```bash
export KUBECONFIG=./kubeconfig.yml
kubectl get nodes
```

### Upgrade K3s

```bash
ansible-playbook -i inventory.yml playbooks/upgrade.yml -e k3s_version=v1.35.0+k3s1
```

## Future — HA control plane

When ready to move to 3 control planes, add two more VM resources in `main.tf` and update the Ansible inventory. The `--cluster-init` flag in the server role already sets up etcd for HA.
