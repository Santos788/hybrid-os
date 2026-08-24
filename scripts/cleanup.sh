#!/bin/bash
RED='\033[0;31m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
AMARELO='\033[1;33m'
NC='\033[0m'

# Caminhos padronizados de montagem
MOUNT_HYBRID="${MOUNT_HYBRID:-$HOME/hybrid-os}"
MOUNT_DRIVE="${MOUNT_DRIVE:-$HOME/meu_google_drive}"

echo -e "${CYAN}   [ TASK ] Encerrando processos e limpando o ecossistema...${NC}"

# 1. Encerra apenas os processos ligados ao projeto
pkill -f "hybrid_app.AppImage" 2>/dev/null || true
pkill -f "VSCode-linux-x64/code" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true
sleep 1

# 2. Desmonta o Google Drive
if mountpoint -q "$MOUNT_DRIVE" 2>/dev/null; then
    fusermount -uz "$MOUNT_DRIVE" 2>/dev/null || sudo umount -fl "$MOUNT_DRIVE" 2>/dev/null || true
fi

# 3. Desmonta o armazenamento do celular (SFTP)
if mountpoint -q "$MOUNT_HYBRID" 2>/dev/null; then
    fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || sudo umount -fl "$MOUNT_HYBRID" 2>/dev/null || true
fi

# 4. Remove diretórios vazios e resíduos locais da RAM
rm -rf "$MOUNT_HYBRID" "$MOUNT_DRIVE" 2>/dev/null || true
rm -f /tmp/hybrid_app.AppImage 2>/dev/null || true
rm -rf /tmp/vscode-user-data 2>/dev/null || true
rm -rf ~/.config/rclone 2>/dev/null || true

# 5. Destruição segura de chaves SSH e arquivos de hosts da sessão
if [ -f ~/.ssh/id_rsa ]; then
    shred -u ~/.ssh/id_rsa 2>/dev/null || rm -f ~/.ssh/id_rsa
fi
rm -f ~/.ssh/id_rsa.pub ~/.ssh/known_hosts_hybridos 2>/dev/null || true

echo -e "${LGREEN}   [  OK  ] Google Drive e Celular desconectados. Credenciais destruídas. RAM limpa!${NC}"
