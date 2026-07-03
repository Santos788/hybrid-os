#!/bin/bash
# ==============================================================================
# HybridOS - Ambiente de Desenvolvimento Persistente em RAM via Android (Termux)
# Desenvolvedor: Clayton (Santos788)
# Versão: 2.0 (Menu Dinâmico de AppImages)
# ==============================================================================

# ---------- Paleta de cores (estilo Mint / terminal hacker) ----------
GREEN='\033[0;32m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
LCYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[1;30m'
BOLD='\033[1m'
NC='\033[0m' # reset

clear

# ---------- Logo Linux Mint (ASCII) + cabeçalho lado a lado ----------
echo -e "${GREEN}"
echo "        .MMMMMMMMMMMMMMMMMMMMMMMMM."
echo "      .MMm----------------------mMM."
echo "     .MM-  .MMMMMMMMMMMMMMMMMMM.  -MM."
echo "     MM-  .MMMMMMMMMMMMMMMMMMMMM.  -MM"
echo "    MM-  .MM   MMMMMMMMMMMMMMMMM.  -MM"
echo "    MM-  .MM   MMMMMMM   MMMMMM.   -MM"
echo "    MM-  .MM   MMMMMMM   MMMMMM.   -MM"
echo "    MM-  .MM   MMMMMMM   MMMMMM.   -MM"
echo "    MM-  .MM   MMMMMMMMMMMMMMMMM.  -MM"
echo "    MM-  .MM   MMMMMMMMMMMMMMMMM.  -MM"
echo "    MM-  .MMMMMMMMMMMMMMMMMMMMMMM.  -MM"
echo "     MM-  .MMMMMMMMMMMMMMMMMMMMM.  -MM"
echo "     MM.    -MMMMMMMMMMMMMMMMM-    .MM"
echo "      MMm.                       .mMM"
echo "        MMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
echo -e "${NC}"

echo -e "${LCYAN}${BOLD}   Bem-vindo ao HybridOS${NC}"
echo -e "${GRAY}   ---------------------------------------------------------------${NC}"
echo -e "${CYAN}   HybridOS${NC} monta seu celular via SSHFS, sincroniza o Google Drive"
echo -e "   com rclone e sobe aplicativos direto na RAM, sem gravar no disco Live."
echo -e "${GRAY}   ---------------------------------------------------------------${NC}"
echo ""

# ---------- Caixa de status inicial ----------
echo -e "${GRAY}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${GRAY}│${NC} ${LGREEN}●${NC} Script      : HybridOS RAM Environment                     ${GRAY}│${NC}"
echo -e "${GRAY}│${NC} ${LGREEN}●${NC} Dev         : Clayton (Santos788)                          ${GRAY}│${NC}"
echo -e "${GRAY}│${NC} ${LGREEN}●${NC} Módulos     : SSHFS · Rclone · Tmpfs · Dynamic Launcher    ${GRAY}│${NC}"
echo -e "${GRAY}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""

# ---------- Função utilitária de log ----------
log_task() { echo -e "${CYAN}   [ TASK ]${NC} $1"; }
log_ok()   { echo -e "${LGREEN}   [  OK  ]${NC} $1"; }
log_info() { echo -e "${YELLOW}   [ INFO ]${NC} $1"; }
log_warn() { echo -e "${YELLOW}   [ WARN ]${NC} $1"; }
log_fail() { echo -e "${RED}   [ FAIL ]${NC} $1"; }

# [ETAPA 1] Saneamento de dependências do Kernel do Linux Live
log_task "Saneando dependências do Kernel do Linux Live..."
sudo sed -i '/cdrom:/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null

if [ -f /etc/fuse.conf ]; then
    sudo sed -i 's/#\s*user_allow_other/user_allow_other/g' /etc/fuse.conf
    if ! grep -q "^user_allow_other" /etc/fuse.conf; then
        echo "user_allow_other" | sudo tee -a /etc/fuse.conf >/dev/null
    fi
fi

if ! command -v sshfs &>/dev/null || ! command -v rclone &>/dev/null; then
    log_info "Dependências ausentes detectadas: [ sshfs rclone ]"
    sudo apt-get update -y && sudo apt-get install -y sshfs rclone
    if [ $? -ne 0 ]; then
        log_fail "Falha crítica ao instalar dependências. Verifique sua internet."
        exit 1
    fi
fi
log_ok "Todas as dependências do Kernel estão de pé."

# [ETAPA 2] Configuração de pontos de montagem na RAM
mkdir -p ~/meu_ssd_remoto
mkdir -p ~/meu_google_drive
mkdir -p ~/.config/rclone
log_ok "Diretórios tmpfs limpos e recriados na memória RAM."

# [ETAPA 3] Identificação dinâmica do IP do Celular (Tethering USB)
log_task "Sondando barramento USB em busca do corpo físico..."
CELULAR_IP=$(ip route show | grep default | awk '{print $3}' | head -n 1)
[ -z "$CELULAR_IP" ] && CELULAR_IP="192.168.141.218"
log_ok "Dispositivo localizado  →  ${LCYAN}$CELULAR_IP${NC} (gateway-usb0)"

# [ETAPA 4] Fusão via SSHFS
log_task "Enxertando sistema de arquivos Android via SSHFS..."
sshfs -p 8022 com.termux@$CELULAR_IP:/storage/emulated/0 ~/meu_ssd_remoto -o follow_symlinks,cache=yes,allow_other
if [ $? -ne 0 ]; then
    log_fail "Falha na fusão via SSHFS. Verifique o Termux/Senha."
    exit 1
fi
log_ok "Fusão concluída — Armazenamento do itel A70 agora é local."

# [ETAPA 5] Automação do Rclone (Google Drive)
log_task "Conectando córtex externo (Google Drive)..."
if [ -f ~/meu_ssd_remoto/rclone.conf ]; then
    cp ~/meu_ssd_remoto/rclone.conf ~/.config/rclone/rclone.conf
    rclone mount gdrive: ~/meu_google_drive --vfs-cache-mode full &
    log_ok "Google Drive montado com sucesso via cache persistente do celular!"
else
    log_warn "Arquivo 'rclone.conf' não encontrado na raiz do celular."
fi

# [ETAPA 6] Varredura e Menu Dinâmico de Aplicativos (.AppImage)
log_task "Escaneando celular por interfaces portáteis (.AppImage)..."
mapfile -t APPS_LIST < <(find ~/meu_ssd_remoto -path "*/Android" -prune -o -name "*.AppImage" -print)

if [ ${#APPS_LIST[@]} -eq 0 ]; then
    log_fail "Nenhum arquivo .AppImage encontrado no armazenamento do celular."
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

log_info "Carregando $SELECTED_NAME na memória RAM... 100%"
cp "$SELECTED_PATH" /tmp/hybrid_app.AppImage
chmod +x /tmp/hybrid_app.AppImage

echo ""
echo -e "${GREEN}   ────────────────────────────────────────────────────────────${NC}"
echo -e "   ${LGREEN}●${NC} ${BOLD}HybridOS ONLINE${NC} — Executando $SELECTED_NAME protegido!"
echo -e "${GREEN}   ────────────────────────────────────────────────────────────${NC}"

# Inicialização com flags anti-crash de GPU e Sandbox prontas para qualquer AppImage
/tmp/hybrid_app.AppImage --no-sandbox --disable-gpu --disable-software-rasterizer --user-data-dir ~/meu_ssd_remoto/vscode_data &
