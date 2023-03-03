terraform {
  required_version = ">= 1.0.0"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 3.11.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.10.0"
    }    
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 2.22"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.7"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 0.11.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}