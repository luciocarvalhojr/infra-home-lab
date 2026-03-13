# Minio Setup — Proxmox LXC

Minio runs as a privileged LXC container on Proxmox, independent of the K3s cluster.
This ensures Terraform state is always available even when the cluster is down.

## Container Specs

| Field | Value |
|---|---|
| Hostname | `minio` |
| Template | Alpine 3.21 |
| IP | `192.168.0.200/24` |
| CPU | 1 core |
| RAM | 512MB |
| Disk | 20GB `local-lvm` |
| Ports | `9000` (API) · `9001` (Console) |

## Installation

```bash
apk update && apk upgrade
wget https://dl.min.io/server/minio/release/linux-amd64/minio -O /usr/local/bin/minio
chmod +x /usr/local/bin/minio
```

## Configuration

```bash
mkdir -p /data/minio
# edit /etc/minio.env with your credentials
# create /etc/init.d/minio OpenRC service
rc-update add minio default
rc-service minio start
```

## Buckets

| Bucket | Used by |
|---|---|
| `terraform-state` | Terraform remote backend |

## Access

- Console → http://192.168.0.200:9001
- API → http://192.168.0.200:9000

## Terraform Backend

```hcl
backend "s3" {
  bucket   = "terraform-state"
  key      = "infrastructure/k3s-home-lab/terraform.tfstate"
  region   = "main"
  endpoint = "http://192.168.0.200:9000"

  access_key = "minioadmin"
  secret_key = "changeme123!"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  force_path_style            = true
}
```

## Service Management

```bash
rc-service minio start|stop|restart|status
tail -f /var/log/minio.log
```
