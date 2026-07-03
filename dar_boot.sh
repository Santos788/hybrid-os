#!/bin/bash
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[1;30m'
BOLD='\033[1m'
NC='\033[0m'

clear
# Arte ASCII corrigida e alinhada com precisão de caracteres
echo -e "${GREEN}"
echo "          .MMMMMMMMMMMMMMMMMMMMMMMMM."
echo "        .MMm----------------------mMM."
echo "       .MM-  .MMMMMMMMMMMMMMMMMMM.  -MM."
echo "       MM-  .MMMMMMMMMMMMMMMMMMMMM.  -MM"
echo "      MM-  .MM   MMMMMMMMMMMMMMMMM.  -MM"
echo "      MM-  .MM   MMMMMMM   MMMMMM.   -MM"
echo "      MM-  .MM   MMMMMMM   MMMMMM.   -MM"
echo "      MM-  .MM   MMMMMMM   MMMMMM.   -MM"
echo "      MM-  .MM   MMMMMMMMMMMMMMMMM.  -MM"
echo "      MM-  .MM   MMMMMMMMMMMMMMMMM.  -MM"
echo "      MM-  .MMMMMMMMMMMMMMMMMMMMMMM.  -MM"
echo "       MM-  .MMMMMMMMMMMMMMMMMMMMM.  -MM"
echo "       MM.    -MMMMMMMMMMMMMMMMM-    .MM"
echo "        MMm.                       .mMM"
echo "          MMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
echo -e "${NC}"

echo -e "${LCYAN}${BOLD}   Bem-vindo ao HybridOS V2 (Menu Dinâmico)${NC}"
echo -e "${GRAY}   ---------------------------------------------------------------${NC}"

log_task() { echo -e "${CYAN}   [ TASK ]${NC} $1"; }
log_ok()   { echo -e "${LGREEN}   [  OK  ]${NC} $1"; }
log_info() { echo -e "${YELLOW}   [ INFO ]${NC} $1"; }
log_fail() { echo -e "${RED}   [ FAIL ]${NC} $1"; }

mkdir -p ~/meu_ssd_remoto
CELULAR_IP=$(ip route show | grep default | awk '{print $3}' | head -n 1)
[ -z "$CELULAR_IP" ] && CELULAR_IP="192.168.141.218"

if ! mountpoint -q ~/meu_ssd_remoto; then
    sshfs -p 8022 com.termux@$CELULAR_IP:/storage/emulated/0 ~/meu_ssd_remoto -o follow_symlinks,cache=yes,allow_other
fi

log_task "Escaneando celular por interfaces portáteis (.AppImage)..."
mapfile -t APPS_LIST < <(find ~/meu_ssd_remoto -path "*/Android" -prune -o -name "*.AppImage" -print)

if [ ${#APPS_LIST[@]} -eq 0 ]; then
    log_fail "Nenhum arquivo .AppImage encontrado no armazenamento."
    exit 1
fi

echo -e "\n${LCYAN}${BOLD}   --- APLICATIVOS DISPONÍVEIS NO HYBRIDOS ---${NC}"
for i in "${!APPS_LIST[@]}"; do
    APP_NAME=$(basename "${APPS_LIST[$i]}")
    echo -e "    [ $i ] $APP_NAME"
done
echo ""

while true; do
    read -p "   Escolha o número do app que deseja rodar na RAM: " OPTION
    if [[ "$OPTION" =~ ^[0-9]+$ ]] && [ "$OPTION" -lt "${#APPS_LIST[@]}" ]; then
        SELECTED_PATH="${APPS_LIST[$OPTION]}"
        SELECTED_NAME=$(basename "$SELECTED_PATH")
        break
    else
        echo -e "   ${RED}Opção inválida! Digite um número da lista.${NC}"
    fi
done

log_info "Carregando $SELECTED_NAME na memória RAM..."
cp "$SELECTED_PATH" /tmp/hybrid_app.AppImage
chmod +x /tmp/hybrid_app.AppImage

/tmp/hybrid_app.AppImage --no-sandbox --disable-gpu --disable-software-rasterizer --user-data-dir ~/meu_ssd_remoto/vscode_data &
