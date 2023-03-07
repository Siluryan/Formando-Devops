provider "flux" {}

provider "gitlab" {
  token = var.gitlab_token
}

provider "kubectl" {
  config_path = data.local_file.kube_config.filename
}

provider "kubernetes" {
  config_path = data.local_file.kube_config.filename
}

provider "helm" {
  kubernetes {    
    config_path = data.local_file.kube_config.filename
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}