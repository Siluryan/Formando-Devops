```
# Flux configuration registry (don´t use this notes)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bash_profile
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.profile

brew install fluxcd/tap/flux/fluxctl

export GITLAB_TOKEN="nops"
export GITLAB_USER_ID="nops"

flux check --pre

kind create cluster --name fluxcd

kubectl get pod -n flux-system

flux bootstrap gitlab \
  --owner=siluryan1 \
  --repository=gitlab-kind \
  --branch=master \
  --path=clusters/my-cluster \
  --token-auth \
  --personal

helm repo add fluxcd https://charts.fluxcd.io

kubectl create namespace flux

helm upgrade -i flux fluxcd/flux \
--set git.url=git@github.com:siluryan-group1/gitlab-kind \
--namespace flux

fluxctl identity --k8s-fwd-ns flux

In order to sync your cluster state with GitLab you need to copy the public key and create a deploy key with access on your GitLab repository

export GIT_AUTHUSER=Siluryan1
export GIT_AUTHKEY=nops

kubectl create secret generic flux-git-auth --namespace flux --from-literal=GIT_AUTHUSER=<username> --from-literal=GIT_AUTHKEY=<token>

helm upgrade -i flux fluxcd/flux \
--set git.url='https://$(GIT_AUTHUSER):$(GIT_AUTHKEY)@github.com/siluryan-group1/gitlab-kind' \
--set env.secretName=flux-git-auth \
--namespace flux

cat << EOF | kind create cluster --name fluxcd --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
EOF
