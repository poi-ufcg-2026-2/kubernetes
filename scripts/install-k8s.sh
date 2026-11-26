
#!/bin/bash

set -e

# Versoes e recursos utilizados na atividade
MINIKUBE_VERSION="v1.39.0"
KUBERNETES_VERSION="v1.37.0"
CPUS=4
MEMORY=6144

# Verificar se o script esta sendo executado como usuario comum
if [ "$(id -u)" -eq 0 ]; then
    echo "Execute este script sem sudo."
    exit 1
fi

# Atualizar a lista de pacotes
sudo apt update

# Instalar as dependencias
sudo apt install -y docker.io socat curl git

# Habilitar e iniciar o Docker
sudo systemctl enable --now docker

# Adicionar o usuario atual ao grupo Docker
sudo usermod -aG docker "$USER"

# Instalar o kubectl
sudo snap install kubectl --classic

# Baixar e instalar o Minikube
curl -fLO "https://storage.googleapis.com/minikube/releases/${MINIKUBE_VERSION}/minikube-linux-amd64"

sudo install minikube-linux-amd64 /usr/local/bin/minikube

rm minikube-linux-amd64

# Verificar as dependencias instaladas
dpkg-query -W docker.io socat curl git
minikube version

# Criar o cluster com as permissoes do grupo Docker
sg docker -c "minikube start \
    --driver=docker \
    --cpus=${CPUS} \
    --memory=${MEMORY} \
    --kubernetes-version=${KUBERNETES_VERSION}"

# Utilizar o kubectl compativel com a versao do cluster
ALIAS='alias kubectl="minikube kubectl --"'

if ! grep -Fxq "$ALIAS" "$HOME/.bashrc"; then
    echo "$ALIAS" >> "$HOME/.bashrc"
fi

# Validar o ambiente Kubernetes
sg docker -c 'minikube kubectl -- version'
sg docker -c 'minikube status'
sg docker -c 'minikube kubectl -- get nodes'
sg docker -c 'minikube kubectl -- get pods -A'
sg docker -c 'minikube ip'

echo "Instalacao e configuracao do Kubernetes concluidas."
echo "Abra uma nova sessao para aplicar as permissoes e o alias."
