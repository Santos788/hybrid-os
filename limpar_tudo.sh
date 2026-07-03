#!/bin/bash
RED='\033[0;31m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}   [ TASK ] Fechando aplicativos e limpando a memória RAM...${NC}"

# 1. Fecha o VS Code ou qualquer outro AppImage
pkill -f "hybrid_app.AppImage"
pkill -f "codium"
pkill -f "code"
sleep 1

# 2. Desmonto o Google Drive (Rclone)
if mountpoint -q ~/meu_google_drive; then
    fusermount -u ~/meu_google_drive 2>/dev/null
fi

# 3. Desmonto o armazenamento do Celular (SSHFS)
if mountpoint -q ~/meu_ssd_remoto; then
    fusermount -u ~/meu_ssd_remoto 2>/dev/null
fi

# 4. Faxina nos arquivos temporários locais
rm -f /tmp/hybrid_app.AppImage
rm -f /tmp/boot.sh
rm -f /tmp/limpar_tudo.sh

echo -e "${LGREEN}   [  OK  ] HybridOS desmontado com sucesso! Pode desconectar o USB.${NC}"
