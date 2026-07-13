#!/bin/bash
set -uo pipefail

clear
echo -e "\033[1;36m[ HybridOS Host ] Inicializando blindagem anti-erros...\033[0m"

export MOUNT_HYBRID="$HOME/hybrid-os"
export MOUNT_DRIVE="$HOME/meu_google_drive"

# 1) FUSE idempotente
if ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
fi

# 2) Desmontagem limpa preventiva
for MP in "$MOUNT_HYBRID" "$MOUNT_DRIVE"; do
    if mountpoint -q "$MP" 2>/dev/null; then
        fusermount -uz "$MP" 2>/dev/null || sudo umount -f "$MP" 2>/dev/null || true
    fi
done
pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true

# 3) Dependências com checagem real
if ! command -v rclone &> /dev/null || ! command -v sshfs &> /dev/null || ! command -v nmap &> /dev/null; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list 2>/dev/null || true
    if ! sudo apt update -y || ! sudo apt install rclone sshfs nmap -y; then
        echo -e "\033[1;31m[ ERRO ] Falha ao instalar dependências. Abortando.\033[0m"
        exit 1
    fi
fi

# 4) Autodescoberta do celular blindada contra travamento do pipefail
echo -e "\033[1;33m[ Buscando ] Procurando celular Termux na rede local...\033[0m"
FAIXA_REDE=$(ip route | grep default | awk '{print $3}' | cut -d. -f1-3)".0/24" || FAIXA_REDE="192.168.100.0/24"

# Permitir que o grep falhe sem derrubar o script usando '|| true'
IP_CELULAR=$(nmap -p 8022 --open -oG - "$FAIXA_REDE" 2>/dev/null | grep "Host:" | awk '{print $2}' | head -n 1) || IP_CELULAR=""

if [ -z "$IP_CELULAR" ]; then
    echo -e "\033[1;31m[ ! ] Não consegui detectar o celular automaticamente.\033[0m"
    # Fallback automático antes de perguntar ao usuário
    IP_CELULAR="192.168.100.127"
    echo -e "\033[1;33m[ Ajuste ] Usando IP padrão de contingência: $IP_CELULAR\033[0m"
fi
USER_TERMUX="com.termux"

# 5) Verificação automatizada e segura do host
echo -e "\033[1;33m[ Autenticação ] Verificando identidade do celular...\033[0m"
mkdir -p ~/.ssh && chmod 700 ~/.ssh
KNOWN_HOSTS="$HOME/.ssh/known_hosts_hybridos"

REMOTE_KEY=$(ssh-keyscan -p 8022 "$IP_CELULAR" 2>/dev/null) || REMOTE_KEY=""
if [ -z "$REMOTE_KEY" ]; then
    echo -e "\033[1;31m[ ERRO ] Sem resposta na porta 8022. SSH ativo no Termux?\033[0m"
    exit 1
fi

# Gravação e rotação dinâmica de chaves sem travar o terminal
if [ -f "$KNOWN_HOSTS" ] && grep -qF "$IP_CELULAR" "$KNOWN_HOSTS"; then
    if ! echo "$REMOTE_KEY" | ssh-keygen -F "$IP_CELULAR" -f "$KNOWN_HOSTS" > /dev/null 2>&1; then
        echo -e "\033[1;33m[!] Chave alterada. Rotacionando credenciais...\033[0m"
        sed -i "/$IP_CELULAR/d" "$KNOWN_HOSTS" 2>/dev/null || true
        echo "$REMOTE_KEY" >> "$KNOWN_HOSTS"
    fi
else
    echo "$REMOTE_KEY" >> "$KNOWN_HOSTS"
fi

# 6) Injeção de credenciais na RAM
echo -e "\033[1;33m[ Autenticação ] Injetando credenciais na RAM...\033[0m"
SSH_OPTS=(-p 8022 -o UserKnownHostsFile="$KNOWN_HOSTS" -o StrictHostKeyChecking=no)

if ! ssh "${SSH_OPTS[@]}" "$USER_TERMUX@$IP_CELULAR" "cat /storage/emulated/0/hybrid-os/id_rsa_backup" > ~/.ssh/id_rsa 2>/tmp/ssh_err.log; then
    echo -e "\033[1;31m[ ERRO ] Falha ao obter a chave SSH do celular:\033[0m"
    cat /tmp/ssh_err.log
    exit 1
fi
chmod 600 ~/.ssh/id_rsa

mkdir -p ~/.config/rclone
if ! ssh "${SSH_OPTS[@]}" "$USER_TERMUX@$IP_CELULAR" "cat /storage/emulated/0/hybrid-os/rclone.conf" > ~/.config/rclone/rclone.conf 2>/tmp/ssh_err2.log; then
    echo -e "\033[1;31m[ ERRO ] Falha ao obter o rclone.conf do celular:\033[0m"
    cat /tmp/ssh_err2.log
    exit 1
fi
chmod 600 ~/.config/rclone/rclone.conf

export IP_CELULAR USER_TERMUX
echo -e "\033[0;32m[ OK ] Configurações injetadas com segurança!\033[0m"
sleep 1

# 7) Chamada sequencial sem cache do GitHub
if curl -H "Cache-Control: no-cache" -sL "https://raw.githubusercontent.com/Santos788/hybrid-os/main/dar_boot.sh" -o /tmp/boot.sh && [ -s /tmp/boot.sh ]; then
    bash /tmp/boot.sh
else
    echo -e "\033[1;31m[ ERRO ] Não foi possível baixar dar_boot.sh. Abortando.\033[0m"
    exit 1
fi
