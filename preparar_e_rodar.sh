#!/bin/bash
set -uo pipefail

clear
echo -e "\033[1;36m[ HybridOS Host ] Inicializando blindagem anti-erros...\033[0m"

# Caminhos usados por TODOS os scripts do projeto
export MOUNT_HYBRID="$HOME/hybrid-os"
export MOUNT_DRIVE="$HOME/meu_google_drive"

# ------------------------------------------------------------------
# 1) FUSE: idempotente, sem duplicar a linha a cada execução
# ------------------------------------------------------------------
if ! grep -q "^user_allow_other" /etc/fuse.conf 2>/dev/null; then
    echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null
fi

# ------------------------------------------------------------------
# 2) Desmonta só o que É deste projeto (não mata rclone do sistema)
# ------------------------------------------------------------------
for MP in "$MOUNT_HYBRID" "$MOUNT_DRIVE"; do
    if mountpoint -q "$MP" 2>/dev/null; then
        fusermount -uz "$MP" 2>/dev/null || sudo umount -f "$MP" 2>/dev/null || true
    fi
done
pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true

# ------------------------------------------------------------------
# 3) Dependências, com checagem de falha real
# ------------------------------------------------------------------
if ! command -v rclone &> /dev/null || ! command -v sshfs &> /dev/null || ! command -v nmap &> /dev/null; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list 2>/dev/null || true
    if ! sudo apt update -y || ! sudo apt install rclone sshfs nmap -y; then
        echo -e "\033[1;31m[ ERRO ] Falha ao instalar dependências. Abortando.\033[0m"
        exit 1
    fi
fi

# ------------------------------------------------------------------
# 4) Autodescoberta do celular (Versão Otimizada)
# ------------------------------------------------------------------
echo "[ Buscando ] Procurando celular Termux na rede local..."

IP_MAQUINA=$(hostname -I | awk '{print $1}')
IP_DESCOBERTO=""

if [ -n "$IP_MAQUINA" ]; then
    SUBREDE=$(echo "$IP_MAQUINA" | cut -d'.' -f1-3)".0/24"
    IP_DESCOBERTO=$(nmap -sn "$SUBREDE" 2>/dev/null | grep -B 2 "com.termux" | head -n 1 | awk '{print $5}')
fi

# Fallback inteligente: se o nmap não achar nada, assume o seu IP padrão
IP_CELULAR="${IP_DESCOBERTO:-"192.168.100.127"}"
USER_TERMUX="com.termux"

# ------------------------------------------------------------------
# 5) Verificação de identidade do host automatizada
# ------------------------------------------------------------------
echo -e "\033[1;33m[ Autenticação ] Verificando identidade do celular...\033[0m"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
KNOWN_HOSTS="$HOME/.ssh/known_hosts_hybridos"

# Coleta a chave pública do Termux
REMOTE_KEY=$(ssh-keyscan -p 8022 "$IP_CELULAR" 2>/dev/null)
if [ -z "$REMOTE_KEY" ]; then
    echo -e "\033[1;31m[ ERRO ] Não consegui obter a chave do host $IP_CELULAR. O SSH está ativo no Termux?\033[0m"
    exit 1
fi

# Salva a chave automaticamente eliminando a checagem manual interativa
if [ -f "$KNOWN_HOSTS" ] && grep -qF "$IP_CELULAR" "$KNOWN_HOSTS"; then
    if ! echo "$REMOTE_KEY" | ssh-keygen -F "$IP_CELULAR" -f "$KNOWN_HOSTS" > /dev/null 2>&1; then
        echo -e "\033[1;31m[ ALERTA ] A identidade do celular MUDOU desde a última vez!\033[0m"
        echo -e "\033[1;31m Isso pode indicar uma alteração de rede ou novo IP. Atualizando chaves...\033[0m"
        sed -i "/$IP_CELULAR/d" "$KNOWN_HOSTS" 2>/dev/null || true
        echo "$REMOTE_KEY" >> "$KNOWN_HOSTS"
    fi
else
    echo "$REMOTE_KEY" >> "$KNOWN_HOSTS"
fi

# ------------------------------------------------------------------
# 6) Puxa chave e rclone.conf usando o known_hosts verificado
# ------------------------------------------------------------------
echo -e "\033[1;33m[ Autenticação ] Injetando credenciais na RAM...\033[0m"
SSH_OPTS=(-p 8022 -o UserKnownHostsFile="$KNOWN_HOSTS" -o StrictHostKeyChecking=no)

if ! ssh "${SSH_OPTS[@]}" "$USER_TERMUX@$IP_CELULAR" \
    "cat /storage/emulated/0/hybrid-os/id_rsa_backup" > ~/.ssh/id_rsa 2>/tmp/ssh_err.log; then
    echo -e "\033[1;31m[ ERRO ] Falha ao obter a chave SSH do celular:\033[0m"
    cat /tmp/ssh_err.log
    exit 1
fi
chmod 600 ~/.ssh/id_rsa

mkdir -p ~/.config/rclone
if ! ssh "${SSH_OPTS[@]}" "$USER_TERMUX@$IP_CELULAR" \
    "cat /storage/emulated/0/hybrid-os/rclone.conf" > ~/.config/rclone/rclone.conf 2>/tmp/ssh_err2.log; then
    echo -e "\033[1;31m[ ERRO ] Falha ao obter o rclone.conf do celular:\033[0m"
    cat /tmp/ssh_err2.log
    exit 1
fi
chmod 600 ~/.config/rclone/rclone.conf

export IP_CELULAR
export USER_TERMUX

echo -e "\033[0;32m[ OK ] Configurações injetadas com segurança!\033[0m"
sleep 1

# ------------------------------------------------------------------
# 7) Baixa o próximo script e confere que não veio vazio/corrompido
# ------------------------------------------------------------------
if curl -sL "https://raw.githubusercontent.com/Santos788/hybrid-os/main/dar_boot.sh" -o /tmp/boot.sh \
    && [ -s /tmp/boot.sh ]; then
    bash /tmp/boot.sh
else
    echo -e "\033[1;31m[ ERRO ] Não foi possível baixar dar_boot.sh. Abortando.\033[0m"
    exit 1
fi
