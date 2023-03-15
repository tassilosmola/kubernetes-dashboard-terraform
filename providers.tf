terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.18.1"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.1"
    }
  }
}

provider "kubernetes" {
  # adjust the config settings based on your k8s setup
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

provider "docker" {}