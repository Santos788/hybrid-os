#!/bin/bash
clear

AZUL="\033[1;34m"
CIANO="\033[1;36m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
VERMELHO="\033[1;31m"
SEM_COR="\033[0m"

IP_ALVO=${IP_CELULAR:-"192.168.100.127"}
USER_ALVO=${USER_TERMUX:-"com.termux"}

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
echo -e "${CIANO}|${SEM_COR} OPTION ${CIANO}|${SEM_COR}               DESCRIPTION                      ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   1    ${CIANO}|${SEM_COR} - Montar ambiente completo + Iniciar VS Code  ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   2    ${CIANO}|${SEM_COR} - Montar apenas armazenamento do Celular        ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   3    ${CIANO}|${SEM_COR} - Desmontar e SALVAR EXTENSÕES com segurança   ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo ""

read -rp "$(echo -e "${AMARELO}Escolha uma opção [1-3]: ${SEM_COR}")" opcao

esperar_montagem() {
    local caminho="$1"
    local tentativas=20
    while [ $tentativas -gt 0 ]; do
        mountpoint -q "$caminho" 2>/dev/null && return 0
        sleep 1
        tentativas=$((tentativas - 1))
    done
    return 1
}

case $opcao in
    1)
        echo -e "${VERDE}[+] Montando canais de armazenamento sequencialmente...${SEM_COR}"
        mkdir -p "$MOUNT_HYBRID" "$MOUNT_DRIVE"

        # Execução escalonada para dar tempo ao hardware móvel processar as conexões
        rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full &
        sleep 1.5
        rclone mount gdrive: "$MOUNT_DRIVE" --allow-other --vfs-cache-mode full &

        echo -e "${AMARELO}[...] Aguardando sincronia dos pontos de montagem...${SEM_COR}"
        if ! esperar_montagem "$MOUNT_HYBRID"; then
            echo -e "${VERMELHO}[ ERRO ] $MOUNT_HYBRID falhou no handshake SFTP. Abortando.${SEM_COR}"
            exit 1
        fi
        if ! esperar_montagem "$MOUNT_DRIVE"; then
            echo -e "${AMARELO}[ ! ] Continuando sem o Google Drive (não configurado).${SEM_COR}"
        fi
        echo -e "${VERDE}[OK] Unidades mapeadas com sucesso!${SEM_COR}"

        # Instalação limpa na RAM
        echo -e "${CIANO}[+] Verificando VS Code na RAM...${SEM_COR}"
        cd /tmp || exit 1
        if [ ! -d "VSCode-linux-x64" ]; then
            echo -e "${AMARELO}[...] Baixando binários estáveis...${SEM_COR}"
            if ! wget -q -O vscode.tar.gz "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" || [ ! -s vscode.tar.gz ]; then
                echo -e "${VERMELHO}[ ERRO ] Download falhou. Verifique sua rede.${SEM_COR}"
                rm -f vscode.tar.gz
                exit 1
            fi
            tar -xzf vscode.tar.gz && rm -f vscode.tar.gz
        fi

        # Restauração persistente das extensões
        if [ -f "$MOUNT_HYBRID/.vscode_backup.tar.gz" ]; then
            echo -e "${CIANO}[+] Restaurando mapeamento de extensões...${SEM_COR}"
            tar -xzf "$MOUNT_HYBRID/.vscode_backup.tar.gz" -C "$HOME/" 2>/dev/null || true
        fi

        echo -e "${VERDE}[OK] Disparando VS Code Otimizado! Bons estudos de ADS!${SEM_COR}"
        ./VSCode-linux-x64/code "$MOUNT_HYBRID" --no-sandbox --disable-gpu --disable-software-rasterizer &> /dev/null &
        ;;
    2)
        echo -e "${VERDE}[+] Mapeando apenas o SFTP do Celular...${SEM_COR}"
        mkdir -p "$MOUNT_HYBRID"
        rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full &
        if esperar_montagem "$MOUNT_HYBRID"; then
            echo -e "${VERDE}[OK] Pasta ativa em: $MOUNT_HYBRID${SEM_COR}"
        else
            echo -e "${VERMELHO}[ ERRO ] Tempo limite de montagem esgotado.${SEM_COR}"
            exit 1
        fi
        ;;
    3)
        echo -e "${AMARELO}[-] Compactando e salvando alterações de ambiente...${SEM_COR}"
        pkill -f "VSCode-linux-x64/code" 2>/dev/null || true
        sleep 1.5

        ALVOS_BACKUP=""
        [ -d "$HOME/.vscode" ] && ALVOS_BACKUP=".vscode"
        [ -d "$HOME/.config/Code" ] && ALVOS_BACKUP="${ALVOS_BACKUP} .config/Code"

        if [ -n "$ALVOS_BACKUP" ] && mountpoint -q "$MOUNT_HYBRID" 2>/dev/null; then
            if tar -czf /tmp/vscode_backup.tar.gz -C "$HOME" $ALVOS_BACKUP 2>/dev/null; then
                cp /tmp/vscode_backup.tar.gz "$MOUNT_HYBRID/.vscode_backup.tar.gz" 2>/dev/null && echo -e "${VERDE}[OK] Extensões salvas com segurança no celular!${SEM_COR}"
            fi
        fi

        echo -e "${AMARELO}[-] Desmontando partições da RAM de forma segura...${SEM_COR}"
        fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || sudo umount -f "$MOUNT_HYBRID" 2>/dev/null || true
        fusermount -uz "$MOUNT_DRIVE" 2>/dev/null || sudo umount -f "$MOUNT_DRIVE" 2>/dev/null || true
        pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
        pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true
        echo -e "${VERDE}[OK] Conexões limpas. Pronto para desligar o PC!${SEM_COR}"
        exit 0
        ;;
    *)
        echo -e "${AMARELO}Opção inválida.${SEM_COR}"
        sleep 1
        ;;
esac
