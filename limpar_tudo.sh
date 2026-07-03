#!/bin/bash
RED='\033[0;31m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}   [ TASK ] Encerrando processos e limpando o ecossistema...${NC}"

# 1. Derruba os aplicativos abertos pela RAM
pkill -f "hybrid_app.AppImage"
pkill -f "code"
pkill -f "rclone"
sleep 1

# 2. Desmonta o Google Drive com segurança
if mountpoint -q ~/meu_google_drive; then
    fusermount -u ~/meu_google_drive 2>/dev/null
fi

# 3. Desmonta o Armazenamento do Celular (SSHFS)
if mountpoint -q ~/meu_ssd_remoto; then
    fusermount -u ~/meu_ssd_remoto 2>/dev/null
fi

# 4. Remove os resíduos locais da RAM do notebook
rm -f /tmp/hybrid_app.AppImage
rm -rf ~/.config/rclone

echo -e "${LGREEN}   [  OK  ] Google Drive e Celular desconectados. RAM limpa!${NC}"
