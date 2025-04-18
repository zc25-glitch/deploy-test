terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.0"
    }
    kestra = {
      source = "kestra-io/kestra"
      version = "0.22.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  # Configuration options
  project = var.project_id
  region  = var.region
}

provider "kestra" {
  # Configuration options
}