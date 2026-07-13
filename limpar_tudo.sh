#!/bin/bash
RED='\033[0;31m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
AMARELO='\033[1;33m'
NC='\033[0m'

MOUNT_HYBRID="${MOUNT_HYBRID:-$HOME/hybrid-os}"
MOUNT_DRIVE="${MOUNT_DRIVE:-$HOME/meu_google_drive}"

echo -e "${CYAN}   [ TASK ] Encerrando processos e limpando o ecossistema...${NC}"

# 1. Encerramento forçado e cirúrgico
pkill -f "hybrid_app.AppImage" 2>/dev/null || true
pkill -f "VSCode-linux-x64/code" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true
sleep 1.5

# 2. Desmontagem com Blindagem Lazy (-uz) para contornar travas de arquivos
if mountpoint -q "$MOUNT_DRIVE" 2>/dev/null; then
    fusermount -uz "$MOUNT_DRIVE" 2>/dev/null || sudo umount -f "$MOUNT_DRIVE" 2>/dev/null || true
fi

# 3. Desmonta o armazenamento do celular
if mountpoint -q "$MOUNT_HYBRID" 2>/dev/null; then
    fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || sudo umount -f "$MOUNT_HYBRID" 2>/dev/null || true
fi

# 4. Destruição de dados residuais e caches
rm -f /tmp/hybrid_app.AppImage /tmp/boot.sh /tmp/vscode_backup.tar.gz 2>/dev/null
rm -rf ~/.config/rclone 2>/dev/null

# 5. Sobrescrita de segurança (Shredding) de chaves criptográficas na RAM volátil
if [ -f ~/.ssh/id_rsa ]; then
    shred -u -n 3 ~/.ssh/id_rsa 2>/dev/null || rm -f ~/.ssh/id_rsa
fi
rm -f ~/.ssh/known_hosts_hybridos 2>/dev/null

echo -e "${LGREEN}   [  OK  ] Google Drive e Celular desconectados. Chaves trituradas e RAM limpa!${NC}"
