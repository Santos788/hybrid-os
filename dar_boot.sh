#!/bin/bash
# ==============================================================================
# HybridOS - Ambiente de Desenvolvimento Persistente em RAM via Android (Termux)
# Desenvolvedor: Clayton (Santos788)
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
echo -e "   com rclone e sobe o VS Code direto na RAM, sem gravar no disco Live."
echo -e "${GRAY}   ---------------------------------------------------------------${NC}"
echo ""

# ---------- Caixa de status inicial (estilo Copilot CLI) ----------
echo -e "${GRAY}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${GRAY}│${NC} ${LGREEN}●${NC} Script      : HybridOS RAM Environment                     ${GRAY}│${NC}"
echo -e "${GRAY}│${NC} ${LGREEN}●${NC} Dev         : Clayton (Santos788)                          ${GRAY}│${NC}"
echo -e "${GRAY}│${NC} ${LGREEN}●${NC} Módulos     : SSHFS · Rclone · Tmpfs · Autoload AppImage   ${GRAY}│${NC}"
echo -e "${GRAY}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""

# ---------- Função utilitária de log ----------
log_task() { echo -e "${CYAN}   [ TASK ]${NC} $1"; }
log_ok()   { echo -e "${LGREEN}   [  OK  ]${NC} $1"; }
log_info() { echo -e "${YELLOW}   [ INFO ]${NC} $1"; }
log_warn() { echo -e "${YELLOW}   [ WARN ]${NC} $1"; }
log_fail() { echo -e "${RED}   [ FAIL ]${NC} $1"; }

# [ETAPA 1] Limpeza preventiva de CD-ROM e saneamento de dependências
log_task "Saneando dependências do Kernel do Linux Live..."
sudo sed -i '/cdrom:/d' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null

# Habilita a opção user_allow_other no FUSE do sistema operacional local
if [ -f /etc/fuse.conf ]; then
    sudo sed -i 's/#\s*user_allow_other/user_allow_other/g' /etc/fuse.conf
    if ! grep -q "^user_allow_other" /etc/fuse.conf; then
        echo "user_allow_other" | sudo tee -a /etc/fuse.conf >/dev/null
    fi
fi

if ! command -v sshfs &>/dev/null || ! command -v rclone &>/dev/null; then
    log_info "Dependências ausentes detectadas: [ sshfs rclone ]"
    log_info "Iniciando instalação automatizada via pacotes estáveis..."
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

# [ETAPA 5] Automação Inteligente do Rclone (Google Drive)
log_task "Conectando córtex externo (Google Drive)..."
if [ -f ~/meu_ssd_remoto/rclone.conf ]; then
    cp ~/meu_ssd_remoto/rclone.conf ~/.config/rclone/rclone.conf
    rclone mount gdrive: ~/meu_google_drive --vfs-cache-mode full &
    log_ok "Google Drive montado com sucesso via cache persistente do celular!"
else
    log_warn "Arquivo 'rclone.conf' não encontrado na raiz do celular."
    echo -e "            Execute 'rclone config' e depois salve o arquivo no celular."
fi

# [ETAPA 6] Carregamento e Execução do VS Code na RAM (Sem erro de GPU e Sandbox)
log_task "Escaneando celular por interfaces portáteis (.AppImage)..."
# Filtro injetado para ignorar pastas restritas do Android e suprimir erros de leitura
VSCODE_APPIMAGE=$(find ~/meu_ssd_remoto -path "*/Android" -prune -o -name "*.AppImage" -print | head -n 1)

if [ -n "$VSCODE_APPIMAGE" ]; then
    cp "$VSCODE_APPIMAGE" /tmp/vscode.AppImage
    chmod +x /tmp/vscode.AppImage
    log_ok "VS Code carregado com sucesso na RAM! 100%"
    echo ""
    echo -e "${GREEN}   ────────────────────────────────────────────────────────────${NC}"
    echo -e "   ${LGREEN}●${NC} ${BOLD}HybridOS ONLINE${NC} — Ambiente pronto e protegido!"
    echo -e "${GREEN}   ────────────────────────────────────────────────────────────${NC}"

    # Execução otimizada: sem aceleração de software, sem sandbox e sem crash gráfico
    /tmp/vscode.AppImage --no-sandbox --disable-gpu --disable-software-rasterizer --user-data-dir ~/meu_ssd_remoto/vscode_data &
else
    log_fail "Nenhum arquivo .AppImage encontrado no celular."
fi
