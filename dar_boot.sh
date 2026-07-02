#!/bin/bash

# ============================================================
#   H Y B R I D O S   —   Ambiente Persistente na RAM v2.0
# ============================================================

RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[38;5;203m'
GREEN='\033[38;5;83m'
CYAN='\033[38;5;51m'
YELLOW='\033[38;5;220m'
MAGENTA='\033[38;5;171m'
BLUE='\033[38;5;75m'
GRAY='\033[38;5;240m'
WHITE='\033[38;5;255m'

PASTA_CELULAR="$HOME/meu_ssd_remoto"
PASTA_DRIVE="$HOME/meu_google_drive"

ok()    { echo -e "   ${GREEN}${BOLD}[  OK  ]${RESET} $1"; }
fail()  { echo -e "   ${RED}${BOLD}[ FAIL ]${RESET} $1"; }
warn()  { echo -e "   ${YELLOW}${BOLD}[ WARN ]${RESET} $1"; }
info()  { echo -e "   ${BLUE}${BOLD}[ INFO ]${RESET} $1"; }
task()  { echo -e "   ${MAGENTA}${BOLD}[ TASK ]${RESET} $1"; }

cabecalho() {
  clear
  local UPTIME_SIS=$(uptime -p 2>/dev/null | sed 's/up //')
  local RAM_TOTAL=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}')
  local RAM_USADA=$(free -h 2>/dev/null | awk '/Mem:/ {print $3}')

  local logo_plain=(
    "      .:+ossssssssso+:."
    "   :+sssssssssssssssssss+:"
    " .ossssssssssssssssssssssso."
    "+sssss   ##   sssss   ##   sssss+"
    "sssssss######sssssss######sssssss"
    "ssssssss####sssssssssss####ssssssss"
    ".ssssssssssssssssssssssssssssss."
    " ossssssssssssssssssssssssssssso"
    " ssssss##################ssssss"
    " +sssss##################sssss+"
    "  ossssssssssssssssssssssssssso"
    "   +sssssssssssssssssssssssss+"
    "    .+sssssssssssssssssssss+."
    "        :+sssssssssssssss+:"
    "           .:+ossssso+:."
  )
  local largura_col=38

  local info_lines=(
    "${WHITE}${BOLD}root@hybridos${RESET}"
    "${GRAY}------------------------------------${RESET}"
    "${GREEN}${BOLD}Kernel${RESET}${DIM}:${RESET}    tmpfs-ram (Mod Auto-Recuperação)"
    "${GREEN}${BOLD}Corpo${RESET}${DIM}:${RESET}     itel A70 ${DIM}(Android/Termux)${RESET}"
    "${GREEN}${BOLD}Uptime${RESET}${DIM}:${RESET}    ${UPTIME_SIS:-recém-iniciado}"
    "${GREEN}${BOLD}Shell${RESET}${DIM}:${RESET}     $SHELL"
    "${GREEN}${BOLD}CPU${RESET}${DIM}:${RESET}       $(nproc 2>/dev/null || echo '?') núcleos"
    "${GREEN}${BOLD}Memória${RESET}${DIM}:${RESET}   ${RAM_USADA:-?} / ${RAM_TOTAL:-?}"
    ""
    "${CYAN}●${RESET}${GREEN}●${RESET}${YELLOW}●${RESET}${RED}●${RESET}${MAGENTA}●${RESET}${BLUE}●${RESET}${WHITE}●${RESET}"
  )

  local i max=${#logo_plain[@]}
  [ ${#info_lines[@]} -gt $max ] && max=${#info_lines[@]}

  for ((i=0; i<max; i++)); do
    local esq="${logo_plain[$i]:-}"
    local dir="${info_lines[$i]:-}"
    printf "  ${RED}%-*s${RESET}   %b\n" "$largura_col" "$esq" "$dir"
  done
  echo
}

banner_ferramenta() {
  echo -e "${CYAN}"
  cat <<'EOF'
  888    888          888               d8b      888  .d88888b.  .d8888b. 
  888    888          888               Y8P      888 d88P" "Y88bd88P  Y88b
  888    888          888                        888 888     88888888888  
  8888888888 888  888 88888b.  888d888 888 .d88888888 888     88888b.      
  888    888 888  888 888 "88b 888P"   888d88" 888888 888     888"Y8888b.  
  888    888 888  888 888  888 888     888888  888888 888     888    "888  
  888    888 Y88b 888 888 d88P 888     8888888b 888888 Y88b. .d88Y88b  d88P  
  888    888  "Y88888 88888P"  888     888 "Y8888888888  "Y88888P"  "Y8888P" 
EOF
  echo -e "${RESET}"
  echo -e "   ${GREEN}+ -- --=[ Módulos Dinâmicos: SSHFS · Rclone · Tmpfs · Autoload AppImage${RESET}"
  echo
}

barra_progresso() {
  local origem="$1" destino="$2" nome_prog="$3"
  local tamanho_total=$(stat -c%s "$origem" 2>/dev/null || echo 0)
  cp "$origem" "$destino" 2>/dev/null &
  local pid=$!
  local largura=24
  while kill -0 "$pid" 2>/dev/null; do
    local atual=$(stat -c%s "$destino" 2>/dev/null || echo 0)
    local pct=0
    [ "$tamanho_total" -gt 0 ] && pct=$(( atual * 100 / tamanho_total ))
    [ "$pct" -gt 100 ] && pct=100
    local preenchido=$(( pct * largura / 100 ))
    local vazio=$(( largura - preenchido ))
    
    printf "\r   ${MAGENTA}${BOLD}[ TASK ]${RESET} injetando %-15s ${CYAN}[" "$nome_prog"
    [ "$preenchido" -gt 0 ] && printf '▓%.0s' $(seq 1 $preenchido) 2>/dev/null
    [ "$vazio" -gt 0 ] && printf '░%.0s' $(seq 1 $vazio) 2>/dev/null
    printf "]${RESET} %3d%%" "$pct"
    sleep 0.1
  done
  printf "\r"; ok "payload %-15s carregado com sucesso na RAM!      " "$nome_prog"
  wait "$pid"
}

# ============================================================
# BOOT SEQUENCE
# ============================================================
cabecalho
banner_ferramenta

# ---- 1. AUTO-RECUPERAÇÃO DE DEPENDÊNCIAS DO LINUX LIVE ----
task "Saneando dependências do Kernel do Linux Live..."
DEPS_FALTANDO=()
command -v sshfs >/dev/null 2>&1 || DEPS_FALTANDO+=("sshfs")
command -v rclone >/dev/null 2>&1 || DEPS_FALTANDO+=("rclone")
if [ ! -f /usr/bin/fusermount3 ] && [ ! -f /bin/fusermount3 ]; then
  DEPS_FALTANDO+=("fuse3")
fi

if [ ${#DEPS_FALTANDO[@]} -ne 0 ]; then
  info "Dependências ausentes detectadas: [ ${DEPS_FALTANDO[*]} ]"
  info "Iniciando instalação automatizada via pacotes estáveis..."
  sudo apt update -y && sudo apt install "${DEPS_FALTANDO[@]}" -y --fix-missing
  if [ $? -eq 0 ]; then
    ok "Dependências injetadas com sucesso no ecossistema!"
  else
    fail "Falha crítica ao instalar dependências. Verifique sua internet."
    exit 1
  fi
else
  ok "Todas as dependências do Kernel estão de pé."
fi

# ---- 2. PREPARAÇÃO DOS DIRETÓRIOS ----
# Limpeza de segurança para evitar trancamentos (Permission Denied)
fusermount -u -z "$PASTA_CELULAR" 2>/dev/null
fusermount -u -z "$PASTA_DRIVE" 2>/dev/null
rm -rf "$PASTA_CELULAR" "$PASTA_DRIVE"
mkdir -p "$PASTA_CELULAR" "$PASTA_DRIVE"
ok "Diretórios tmpfs limpos e recriados na memória RAM."

# ---- 3. DESCOBERTA DO IP DO CELULAR ----
task "Sondando barramento USB em busca do corpo físico..."
IP_CELULAR=$(ip route show | grep default | awk '{print $3}' | head -n 1)
ORIGEM_IP="gateway-usb0"
if [ -z "$IP_CELULAR" ]; then
  IP_CELULAR=$(ip neigh show | grep -E "usb|rndis" | awk '{print $1}' | head -n 1)
  ORIGEM_IP="tabela-arp"
fi
if [ -z "$IP_CELULAR" ]; then
  IP_CELULAR="192.168.141.218"
  ORIGEM_IP="fallback-estatico"
fi
ok "Dispositivo localizado  →  ${BOLD}${IP_CELULAR}${RESET} ${DIM}(${ORIGEM_IP})${RESET}"

# ---- 4. MONTAGEM SSHFS DO CELULAR ----
task "Enxertando sistema de arquivos Android via SSHFS..."
sshfs -p 8022 -o ConnectTimeout=5,reconnect,cache=yes com.termux@"$IP_CELULAR":/storage/emulated/0 "$PASTA_CELULAR"
if [ $? -eq 0 ]; then
  ok "Fusão concluída — Armazenamento do itel A70 agora é local."
else
  fail "Kernel Panic — Não foi possível realizar a fusão física."
  exit 1
fi

# ---- 5. MONTAGEM GOOGLE DRIVE VIA RCLONE ----
task "Conectando córtex externo (Google Drive)..."
if rclone listremotes 2>/dev/null | grep -q "gdrive:"; then
  rclone mount gdrive: "$PASTA_DRIVE" --vfs-cache-mode writes &
  sleep 1
  ok "Córtex externo sincronizado  →  ${DIM}${PASTA_DRIVE}${RESET}"
else
  warn "Remoto 'gdrive:' não configurado. Use 'rclone config' em outro terminal."
fi

# ---- 6. RESTAURANDO PERFIL DE USUÁRIO ----
task "Restaurando memórias e preferências de ambiente..."
if [ -d "$PASTA_CELULAR/linux_profile/.config" ]; then
  rm -rf "$HOME/.config"
  ln -s "$PASTA_CELULAR/linux_profile/.config" "$HOME/.config"
  ok "Preferências do usuário restauradas com sucesso em ~/.config"
else
  warn "Perfil persistente não encontrado em linux_profile/.config. Pulando."
fi

# ---- 7. CARREGADOR DINÂMICO DE PAYLOADS (.AppImage) ----
task "Escaneando celular por interfaces portáteis (.AppImage)..."
HAS_APPIMAGE=false

# Loop lê todos os arquivos .AppImage na raiz do celular
for arquivo in "$PASTA_CELULAR"/*.AppImage; do
  if [ -f "$arquivo" ]; then
    HAS_APPIMAGE=true
    nome_base=$(basename "$arquivo")
    
    # Copia com barra de progresso para a RAM (/tmp)
    barra_progresso "$arquivo" "/tmp/$nome_base" "$nome_base"
    chmod +x "/tmp/$nome_base" 2>/dev/null
    
    # Inicializa de acordo com o programa
    if [[ "$nome_base" == *"vscode"* || "$nome_base" == *"code"* ]]; then
      /tmp/$nome_base --user-data-dir "$PASTA_CELULAR/vscode_data" & disown
    else
      # Qualquer outro AppImage roda normalmente em background
      /tmp/$nome_base & disown
    fi
  fi
done

if [ "$HAS_APPIMAGE" = false ]; then
  warn "Nenhum payload .AppImage encontrado na raiz do celular."
fi

# ============================================================
# STATUS FINAL
# ============================================================
echo
echo -e "${GRAY}   ────────────────────────────────────────────────────────────${RESET}"
echo -e "   ${GREEN}${BOLD}●${RESET} ${BOLD}${WHITE}HybridOS ONLINE${RESET}  ${DIM}— Próximo boot será 100%% autônomo!${RESET}"
echo -e "${GRAY}   ────────────────────────────────────────────────────────────${RESET}"
echo
