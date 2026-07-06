#main.tf (El proveedor)
#Le dice a Terraform que se conecte a Google Cloud.

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" 
    }
  }
}

provider "google" {
  project = "mec-002-dev-crea" # ⚠️ REEMPLAZA CON EL ID REAL DE TU PROYECTO DE GCP
  region  = "us-east1"
}