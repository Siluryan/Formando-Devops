provider "flux" {}

provider "gitlab" {
  token = var.gitlab_token
}

provider "kind" {
}

provider "kubectl" {
  config_path = data.local_file.kube_config.filename
}

provider "kubernetes" {
  config_path = data.local_file.kube_config.filename
}

provider "helm" {
  kubernetes {
    #Kind Cluster
    host                   = module.kind_cluster.endpoint
    client_certificate     = module.kind_cluster.client_certificate
    client_key             = module.kind_cluster.client_key
    cluster_ca_certificate = module.kind_cluster.cluster_ca_certificate
    #General
    config_path = data.local_file.kube_config.filename
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}