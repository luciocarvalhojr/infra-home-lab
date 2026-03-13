terraform {
  required_version = ">= 1.9.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }

  # Minio S3-compatible backend — production-ready, same API as AWS S3
  # Change endpoint to AWS S3 URL if you move to production
  backend "s3" {
    bucket = "terraform-state"
    key    = "infrastructure/k3s-home-lab/terraform.tfstate"

    region   = "main"  # Minio ignores this but Terraform requires it
    endpoint = "http://192.168.0.XXX:9000"  # ← your Minio IP

    access_key = "your-minio-access-key"  # use env var TF_VAR_ or tfvars
    secret_key = "your-minio-secret-key"

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true  # required for Minio
  }
}

provider "proxmox" {
  endpoint = var.proxmox_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true  # set to false if you have a valid cert on Proxmox
}
