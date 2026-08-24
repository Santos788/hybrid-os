#!/usr/bin/env bash
# ==============================================================================
# HYBRID-OS: BOOT SCRIPT (v2.0)
# ==============================================================================
set -euo pipefail

# Diretórios de trabalho e pontos de montagem
MOUNT_HYBRID="$HOME/hybrid-os-storage"
MOUNT_GDRIVE="$HOME/meu_google_drive"
SSH_KEY="$HOME/.ssh/id_rsa"
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts_hybridos"
PORT=8022
USER_TERMUX="com.termux"

# 1. Garante a existência dos diretórios locais
mkdir -p "$MOUNT_HYBRID" "$MOUNT_GDRIVE" ~/.ssh

echo "=================================================="
echo " [ HybridOS Host ] Inicializando blindagem anti-erros..."
echo "=================================================="

# 2. Desmonta montagens anteriores travadas para evitar 'Transport endpoint not connected'
fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || true
fusermount -uz "$MOUNT_GDRIVE" 2>/dev/null || true
pkill -9 -f rclone 2>/dev/null || true

# 3. Varredura automática do IP do Celular na sub-rede atual
echo "[ Buscando ] Procurando celular Termux na rede local..."
SUBNET=$(ip route show default | awk '/default/ {print $3}' | cut -d. -f1-3)

if [ -z "$SUBNET" ]; then
    echo "[ ERRO ] Conexão de rede não encontrada. Verifique o Wi-Fi."
    exit 1
fi

IP_CELULAR=""
# Varre a sub-rede na porta 8022 com timeout curto
for i in $(seq 1 254); do
    (nc -zw1 "$SUBNET.$i" $PORT 2>/dev/null && echo "$SUBNET.$i") &
done | head -n 1 > /tmp/target_ip.txt

IP_CELULAR=$(cat /tmp/target_ip.txt 2>/dev/null || true)

if [ -z "$IP_CELULAR" ]; then
    echo "[ ERRO ] Termux não encontrado na sub-rede $SUBNET.0/24 (Porta $PORT)."
    echo "Certifique-se de ter executado 'sshd' no celular."
    exit 1
fi

echo "[ OK ] Celular encontrado no IP: $IP_CELULAR"

# 4. Verificação de Chave SSH / Host Verification
echo "[ Autenticação ] Verificando chave do host..."
ssh-keyscan -p $PORT "$IP_CELULAR" > "$KNOWN_HOSTS_FILE" 2>/dev/null || true

# 5. Função para montagem do Rclone SFTP
mount_sftp() {
    echo "[+] Montando armazenamento do celular ($IP_CELULAR)..."
    rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" \
        --sftp-host="$IP_CELULAR" \
        --sftp-port="$PORT" \
        --sftp-user="$USER_TERMUX" \
        --sftp-key-file="$SSH_KEY" \
        --sftp-known-hosts-file="$KNOWN_HOSTS_FILE" \
        --vfs-cache-mode full \
        --daemon

    echo "[+] Aguardando ponto de montagem estabilizar..."
    sleep 3

    if mountpoint -q "$MOUNT_HYBRID"; then
        echo "[ OK ] Repositório do celular montado em $MOUNT_HYBRID"
    else
        echo "[ ERRO ] A montagem do celular falhou."
        exit 1
    fi
}

# 6. Exibição do Menu Principal
cat << "EOF"
 _   _       _            _     _  ___  ____  
| | | |_   _| |__  _ __  (_)___| |/ _ \/ ___| 
| |_| | | | | '_ \| '__| | / __| | | | \___ \ 
|  _  | |_| | |_) | |    | \__ \ | |_| |___) |
|_| |_|\__,_|_.__/|_|    |_|___/_|\___/|____/ 

VERSION:2.0  DISTRO:Android  MOUNT:rclone_sftp  STATUS:READY

+========================================================+
| OPTION |               DESCRIPTION                     |
+========================================================+
|   1    | - Montar ambiente completo + Iniciar VS Code  |
|   2    | - Montar apenas armazenamento do Celular        |
|   3    | - Desmontar e SALVAR EXTENSÕES com segurança   |
+========================================================+
EOF

read -rp "Escolha uma opção [1-3]: " OPCAO

case "$OPCAO" in
    1)
        mount_sftp
        echo "[+] Iniciando VS Code..."
        if command -v code &>/dev/null; then
            code "$MOUNT_HYBRID" --no-sandbox
        else
            echo "[ ALERTA ] Executável do VS Code não encontrado na PATH."
        fi
        ;;
    2)
        mount_sftp
        echo "[ OK ] Conexão mantida em segundo plano."
        ;;
    3)
        echo "[-] Executando procedimento de limpeza..."
        bash ./scripts/cleanup.sh
        ;;
    *)
        echo "[ ERRO ] Opção inválida."
        exit 1
        ;;
esac
