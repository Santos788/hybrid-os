#!/bin/bash
RED='\033[0;31m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
AMARELO='\033[1;33m'
NC='\033[0m'

# MESMOS caminhos usados em dar_boot.sh e preparar_e_rodar.sh.
# O bug original apontava para ~/meu_ssd_remoto, uma pasta que nunca
# é criada em lugar nenhum — então a limpeza nunca desmontava o
# armazenamento de verdade.
MOUNT_HYBRID="${MOUNT_HYBRID:-$HOME/hybrid-os}"
MOUNT_DRIVE="${MOUNT_DRIVE:-$HOME/meu_google_drive}"

echo -e "${CYAN}   [ TASK ] Encerrando processos e limpando o ecossistema...${NC}"

# 1. Encerra só os processos que ESTE projeto abriu, não qualquer
#    coisa com "code" ou "rclone" no nome.
pkill -f "hybrid_app.AppImage" 2>/dev/null || true
pkill -f "VSCode-linux-x64/code" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true
sleep 1

# 2. Desmonta o Google Drive com segurança
if mountpoint -q "$MOUNT_DRIVE" 2>/dev/null; then
    fusermount -u "$MOUNT_DRIVE" 2>/dev/null || sudo umount -f "$MOUNT_DRIVE" 2>/dev/null || true
fi

# 3. Desmonta o armazenamento do celular (caminho corrigido)
if mountpoint -q "$MOUNT_HYBRID" 2>/dev/null; then
    fusermount -u "$MOUNT_HYBRID" 2>/dev/null || sudo umount -f "$MOUNT_HYBRID" 2>/dev/null || true
fi

# 4. Remove os resíduos locais da RAM do notebook
rm -f /tmp/hybrid_app.AppImage
rm -rf ~/.config/rclone

# 5. Remove as credenciais SSH injetadas nesta sessão — o script
#    original deixava a chave privada e o known_hosts esquecidos no
#    disco/RAM mesmo depois da "limpeza".
if [ -f ~/.ssh/id_rsa ]; then
    shred -u ~/.ssh/id_rsa 2>/dev/null || rm -f ~/.ssh/id_rsa
fi
rm -f ~/.ssh/known_hosts_hybridos

echo -e "${LGREEN}   [  OK  ] Google Drive e Celular desconectados. Credenciais removidas. RAM limpa!${NC}"
