
#!/bin/bash

set -e

# Obter o IP interno do Minikube
MK=$(minikube ip)

echo "IP do Minikube: $MK"

# Configurar o encaminhamento das portas
for m in "8080 30080 cpu" "8081 30081 memory" "8082 30082 io"; do

    set -- $m

    sudo tee "/etc/systemd/system/k8s-forward-$3.service" > /dev/null <<EOF
[Unit]
Description=Encaminha porta $1 para NodePort $2 ($3-bound)
After=network.target docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:$1,fork,reuseaddr TCP:$MK:$2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

done

# Recarregar as configuracoes do systemd
sudo systemctl daemon-reload

# Habilitar e iniciar os servicos
sudo systemctl enable --now \
    k8s-forward-cpu \
    k8s-forward-memory \
    k8s-forward-io

# Reiniciar os servicos para aplicar eventuais alteracoes
sudo systemctl restart \
    k8s-forward-cpu \
    k8s-forward-memory \
    k8s-forward-io

# Verificar as portas
sudo ss -ltnp | grep -E "808[012]"

# Testar a aplicacao IO-bound
curl -sS --fail --max-time 10 http://127.0.0.1:8082/health
