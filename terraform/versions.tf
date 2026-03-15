terraform {
  required_version = ">= 1.9.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # Minio S3-compatible backend — production-ready, same API as AWS S3
  # Change endpoint to AWS S3 URL if you move to production
  backend "s3" {
    bucket = "terraform-state"
    key    = "infrastructure/k3s-home-lab/terraform.tfstate"
    region = "main"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true  # required for Minio
  }
}

provider "proxmox" {
  endpoint = var.proxmox_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true  # set to false if you have a valid cert on Proxmox
}
