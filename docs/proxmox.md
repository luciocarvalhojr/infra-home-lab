# Proxmox Home Lab Runbook

Operational notes for the Proxmox VE host (`hyper01` — `192.168.0.90`). Covers initial setup, repo configuration, template creation, and maintenance tasks.

---

## Table of Contents

- [Repository Setup](#repository-setup)
- [Subscription Nag](#subscription-nag)
- [Ubuntu 24.04 Template](#ubuntu-2404-template)
- [Template Verification](#template-verification)
- [Maintenance Notes](#maintenance-notes)

---

## Repository Setup

Proxmox VE ships with enterprise repos enabled by default. On a community install, disable them and switch to the no-subscription repo.

```bash
# Disable enterprise repos (DEB822 format used in PVE 8+)
echo "" > /etc/apt/sources.list.d/pve-enterprise.sources
echo "" > /etc/apt/sources.list.d/ceph.sources

# Add community repo
echo "deb http://download.proxmox.com/debian/pve trixie pve-no-subscription" \
  > /etc/apt/sources.list.d/pve-community.list

apt-get update
```

> **Note:** Replace `trixie` if your Proxmox is on a different Debian base (check with `cat /etc/debian_version`).

---

## Subscription Nag

Suppress the "No valid subscription" popup in the web UI:

```bash
sed -i "s/res === null || res === undefined || \!res || res.data.status.toLowerCase() !== 'active'/false/" \
  /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

systemctl restart pveproxy
```

Then hard-refresh your browser (`Ctrl+Shift+R`).

> **Note:** This patch is overwritten on `proxmox-widget-toolkit` upgrades. Re-run after `apt upgrade` if the nag returns.

---

## Ubuntu 24.04 Template

Creates a reusable VM template from the official Ubuntu 24.04 cloud image with:

- `qemu-guest-agent` installed and enabled
- `cloud-init` fully configured
- Swap permanently disabled (required for K3s)
- Root partition auto-resize on first boot
- `machine-id` cleared (unique ID per clone)

### Prerequisites

```bash
apt-get install -y libguestfs-tools
export LIBGUESTFS_BACKEND=direct
```

> `LIBGUESTFS_BACKEND=direct` is required on Proxmox — the default supermin backend fails in the Proxmox kernel environment.

### Configuration

Edit these variables at the top of the script before running:

| Variable | Default | Description |
|---|---|---|
| `TEMPLATE_ID` | `9000` | Proxmox VM ID |
| `TEMPLATE_NAME` | `ubuntu-2404-cloud` | VM name |
| `STORAGE` | `local-lvm` | Proxmox storage |
| `MEMORY` | `2048` | Default RAM in MB (overridden per clone) |
| `CORES` | `2` | Default CPU cores (overridden per clone) |

### Steps

```bash
# 1 — Download Ubuntu 24.04 cloud image
wget -O /tmp/noble-server-cloudimg-amd64.img \
  https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

# 2 — Inject packages and configuration into the image
virt-customize \
  -a /tmp/noble-server-cloudimg-amd64.img \
  --install qemu-guest-agent,cloud-init \
  --run-command "systemctl enable qemu-guest-agent" \
  --run-command "systemctl enable cloud-init cloud-init-local cloud-config cloud-final" \
  --run-command "sed -i '/\sswap\s/d' /etc/fstab" \
  --run-command "systemctl mask swap.target || true" \
  --run-command "cloud-init clean --logs" \
  --run-command "truncate -s 0 /etc/machine-id" \
  --run-command "rm -f /var/lib/dbus/machine-id" \
  --quiet

# 3 — Create VM
qm create 9000 \
  --name ubuntu-2404-cloud \
  --memory 2048 \
  --cores 2 \
  --net0 virtio,bridge=vmbr0 \
  --ostype l26 \
  --agent enabled=1 \
  --serial0 socket \
  --vga serial0

# 4 — Import and attach disk
qm importdisk 9000 /tmp/noble-server-cloudimg-amd64.img local-lvm --format qcow2

qm set 9000 \
  --scsihw virtio-scsi-pci \
  --scsi0 "local-lvm:vm-9000-disk-0,discard=on,ssd=1" \
  --boot c \
  --bootdisk scsi0 \
  --ide2 "local-lvm:cloudinit" \
  --ipconfig0 ip=dhcp

# 5 — Drop vendor cloud-init config for auto-resize
mkdir -p /var/lib/vz/snippets
cat > /var/lib/vz/snippets/vendor-cloud-init.yml << 'EOF'
#cloud-config
growpart:
  mode: auto
  devices: ["/"]
  ignore_growroot_disabled: false
resize_rootfs: true
bootcmd:
  - swapoff -a
runcmd:
  - [ systemctl, disable, --now, swap.target ]
EOF

qm set 9000 --cicustom "vendor=local:snippets/vendor-cloud-init.yml"

# 6 — Convert to template
qm template 9000
```

### Terraform usage after template is ready

```hcl
template_id   = 9000
agent_enabled = true   # agent is baked in
```

---

## Template Verification

After cloning the template and booting the first VM:

```bash
# Agent is responding
qm agent <vm_id> ping
# Expected: {}

# SSH into the VM and verify
ssh ubuntu@<ip> 'systemctl status qemu-guest-agent'   # active (running)
ssh ubuntu@<ip> 'free -h'                             # no swap line
ssh ubuntu@<ip> 'df -h /'                             # full disk size
```

---

## Maintenance Notes

**Re-run after every `apt upgrade` that touches `proxmox-widget-toolkit`:**
```bash
# Check if nag is back after upgrade
systemctl restart pveproxy
```

**Locale warnings during apt** (`Cannot set LC_CTYPE`) are harmless but can be fixed:
```bash
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
```

**Template re-creation** — if the cloud image is already downloaded, step 1 can be skipped.
The image is cached at `/tmp/noble-server-cloudimg-amd64.img`.
To force a fresh download, delete it first:
```bash
rm /tmp/noble-server-cloudimg-amd64.img
```

**Destroy and recreate the template:**
```bash
qm destroy 9000 --destroy-unreferenced-disks 1
# then re-run steps 3–6
```
