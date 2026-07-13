#!/bin/bash
clear

AZUL="\033[1;34m"
CIANO="\033[1;36m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
VERMELHO="\033[1;31m"
SEM_COR="\033[0m"

# =====================================================================
# BLINDAGEM DE REDE E AUTODESCOBERTA DO CELULAR (CORREÇÃO DO BUG)
# =====================================================================
echo -e "${CIANO}[ Buscando ] Procurando nó Termux na rede local...${SEM_COR}"

# Extrai apenas o primeiro IP ativo da máquina local
IP_MAQUINA=$(hostname -I | awk '{print $1}')

if [ -n "$IP_MAQUINA" ]; then
    # Monta a subrede de forma limpa (ex: 192.168.100.0/24)
    SUBREDE=$(echo "$IP_MAQUINA" | cut -d'.' -f1-3)".0/24"
    
    # Realiza a varredura silenciosa buscando a assinatura do Termux
    IP_DESCOBERTO=$(nmap -sn "$SUBREDE" 2>/dev/null | grep -B 2 "com.termux" | head -n 1 | awk '{print $5}')
fi

# Se encontrar o IP via nmap, usa ele. Se falhar, assume o IP padrão de contingência.
IP_FINAL="${IP_DESCOBERTO:-"192.168.33.235"}"

IP_ALVO=${IP_CELULAR:-$IP_FINAL}
USER_ALVO=${USER_TERMUX:-"com.termux"}

echo -e "${VERDE}[ OK ] Alvo definido para: $IP_ALVO${SEM_COR}"
echo ""
# =====================================================================

# Mesmos caminhos usados no preparar_e_rodar.sh e no limpar_tudo.sh
MOUNT_HYBRID="${MOUNT_HYBRID:-$HOME/hybrid-os}"
MOUNT_DRIVE="${MOUNT_DRIVE:-$HOME/meu_google_drive}"

echo -e "${AZUL}"
cat << "BANNER"
 _   _ _   _ ____  ____  ___ ____   ___  ____ 
| | | | | | | __ )|  _ \|_ _|  _ \ / _ \/ ___|
| |_| | |_| |  _ \| |_) || || | | | | | \___ \
|  _  |  _  | |_) |  _ < | || |_| | |_| |___) |
|_| |_|_| |_|____/|_| \_\___|____/ \___/|____/
BANNER
echo -e "${SEM_COR}"

echo -e "${CIANO}VERSION:2.0  DISTRO:Android  MOUNT:rclone_sftp  STATUS:READY${SEM_COR}"
echo ""
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR} OPTION ${CIANO}|${SEM_COR}                DESCRIPTION                      ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   1    ${CIANO}|${SEM_COR} - Montar ambiente completo + Iniciar VS Code  ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   2    ${CIANO}|${SEM_COR} - Montar apenas armazenamento do Celular        ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   3    ${CIANO}|${SEM_COR} - Desmontar e SALVAR EXTENSÕES com segurança   ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo ""

read -rp "$(echo -e "${AMARELO}Escolha uma opção [1-3]: ${SEM_COR}")" opcao

# Espera até N segundos um ponto de montagem ficar pronto antes de seguir em frente
esperar_montagem() {
    local caminho="$1"
    local tentativas=15
    while [ $tentativas -gt 0 ]; do
        mountpoint -q "$caminho" 2>/dev/null && return 0
        sleep 1
        tentativas=$((tentativas - 1))
    done
    return 1
}

case $opcao in
    1)
        echo -e "${VERDE}[+] Montando repositório via SFTP e nuvem...${SEM_COR}"
        mkdir -p "$MOUNT_HYBRID" "$MOUNT_DRIVE"

        rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full &
        rclone mount gdrive: "$MOUNT_DRIVE" --allow-other --vfs-cache-mode full &

        echo -e "${AMARELO}[...] Aguardando as montagens ficarem prontas...${SEM_COR}"
        if ! esperar_montagem "$MOUNT_HYBRID"; then
            echo -e "${VERMELHO}[ ERRO ] $MOUNT_HYBRID não montou a tempo. Abortando antes de abrir o VS Code.${SEM_COR}"
            exit 1
        fi
        if ! esperar_montagem "$MOUNT_DRIVE"; then
            echo -e "${AMARELO}[ ! ] $MOUNT_DRIVE não montou (Google Drive pode não estar configurado). Continuando sem ele.${SEM_COR}"
        fi
        echo -e "${VERDE}[OK] Ecossistema mapeado com sucesso!${SEM_COR}"

        # AUTOMAÇÃO DO VS CODE LEVE NA RAM
        echo -e "${CIANO}[+] Preparando VS Code Otimizado na RAM...${SEM_COR}"
        cd /tmp || exit 1
        if [ ! -d "VSCode-linux-x64" ]; then
            echo -e "${AMARELO}[...] Baixando estrutura do editor...${SEM_COR}"
            if ! wget -q -O vscode.tar.gz "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" \
                || [ ! -s vscode.tar.gz ]; then
                echo -e "${VERMELHO}[ ERRO ] Falha ao baixar o VS Code. Abortando.${SEM_COR}"
                rm -f vscode.tar.gz
                exit 1
            fi
            if ! tar -tzf vscode.tar.gz > /dev/null 2>&1; then
                echo -e "${VERMELHO}[ ERRO ] Arquivo do VS Code baixado está corrompido. Abortando.${SEM_COR}"
                rm -f vscode.tar.gz
                exit 1
            fi
            tar -xzf vscode.tar.gz
            rm -f vscode.tar.gz
        fi

        # RESTAURA EXTENSÕES USANDO CAMINHO SEGURO REESCRITO ($HOME)
        if [ -f "$MOUNT_HYBRID/.vscode_backup.tar.gz" ]; then
            echo -e "${CIANO}[+] Restaurando suas extensões salvas...${SEM_COR}"
            tar -xzf "$MOUNT_HYBRID/.vscode_backup.tar.gz" -C "$HOME/" 2>/dev/null || \
                echo -e "${AMARELO}[ ! ] Backup de extensões não pôde ser restaurado (arquivo pode estar corrompido).${SEM_COR}"
        fi

        echo -e "${VERDE}[OK] Disparando VS Code Fluido! Bons estudos de ADS!${SEM_COR}"
        ./VSCode-linux-x64/code "$MOUNT_HYBRID" --no-sandbox --disable-gpu --disable-software-rasterizer &> /dev/null &
        ;;
    2)
        echo -e "${VERDE}[+] Montando apenas repositório via SFTP...${SEM_COR}"
        mkdir -p "$MOUNT_HYBRID"
        rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full &
        if esperar_montagem "$MOUNT_HYBRID"; then
            echo -e "${VERDE}[OK] Pasta de projetos ativa em $MOUNT_HYBRID!${SEM_COR}"
        else
            echo -e "${VERMELHO}[ ERRO ] A montagem não ficou pronta a tempo.${SEM_COR}"
            exit 1
        fi
        ;;
    3)
        echo -e "${AMARELO}[-] Fazendo backup das extensões e configurações na RAM...${SEM_COR}"
        pkill -f "VSCode-linux-x64/code" 2>/dev/null || true
        sleep 1

        ALVOS_BACKUP=""
        [ -d "$HOME/.vscode" ] && ALVOS_BACKUP=".vscode"
        [ -d "$HOME/.config/Code" ] && ALVOS_BACKUP="$ALVOS_BACKUP .config/Code"

        if [ -n "$ALVOS_BACKUP" ]; then
            if tar -czf /tmp/vscode_backup.tar.gz -C "$HOME" $ALVOS_BACKUP 2>/tmp/tar_err.log; then
                if cp /tmp/vscode_backup.tar.gz "$MOUNT_HYBRID/.vscode_backup.tar.gz" 2>/tmp/cp_err.log; then
                    echo -e "${VERDE}[OK] Extensões salvas com sucesso no celular!${SEM_COR}"
                else
                    echo -e "${VERMELHO}[ ERRO ] Não consegui copiar o backup para $MOUNT_HYBRID (ainda está montado?):${SEM_COR}"
                    cat /tmp/cp_err.log
                fi
            else
                echo -e "${VERMEDLO}[ ERRO ] Falha ao compactar as extensões:${SEM_COR}"
                cat /tmp/tar_err.log
            fi
        fi

        echo -e "${AMARELO}[-] Desmontando unidades...${SEM_COR}"
        fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || sudo umount -f "$MOUNT_HYBRID" 2>/dev/null || true
        fusermount -uz "$MOUNT_DRIVE" 2>/dev/null || sudo umount -f "$MOUNT_DRIVE" 2>/dev/null || true
        pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
        pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true
        echo -e "${VERDE}[OK] Unidades liberadas. Saindo com segurança!${SEM_COR}"
        exit 0
        ;;
    *)
        echo -e "${AMARELO}Opção inválida.${SEM_COR}"
        sleep 1
        ;;
esac
