# Terraform Bootstrap Gitlab

In order to follow the guide you'll need a GitLab account and a personal access token that can create repositories.

Create the staging cluster using Kubernetes kind or set the kubectl context to an existing cluster:

You can set these in the terminal that you are running your terraform command by exporting variables.

```
export TF_VAR_gitlab_owner=<owner>
export TF_VAR_gitlab_token=<token>
```

By using the GitLab provider to create a repository you can commit the manifests given by the data sources flux_install and flux_sync. The cluster has been successfully provisioned after the same manifests are applied to it.
