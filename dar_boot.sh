#!/bin/bash
clear

AZUL="\033[1;34m"
CIANO="\033[1;36m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
SEM_COR="\033[0m"

IP_ALVO=${IP_CELULAR:-"localhost"}
USER_ALVO=${USER_TERMUX:-"com.termux"}

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

read -p "$(echo -e ${AMARELO}"Escolha uma opção [1-3]: "${SEM_COR})" opcao

case $opcao in
    1)
        echo -e "${VERDE}[+] Montando repositório via SFTP e nuvem...${SEM_COR}"
        mkdir -p "$HOME/hybrid-os" "$HOME/meu_google_drive"                         
        
        rclone mount :sftp:storage/shared/hybrid-os "$HOME/hybrid-os" --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full 2>/dev/null &
        rclone mount gdrive: "$HOME/meu_google_drive" --allow-other --vfs-cache-mode full &
        
        echo -e "${VERDE}[OK] Ecossistema mapeado com sucesso!${SEM_COR}"
        
        # 🚀 AUTOMAÇÃO DO VS CODE LEVE NA RAM
        echo -e "${CIANO}[+] Preparando VS Code Otimizado na RAM...${SEM_COR}"
        cd /tmp
        if [ ! -d "VSCode-linux-x64" ]; then
            echo -e "${AMARELO}[...] Baixando estrutura do editor...${SEM_COR}"
            wget -q --show-progress -O vscode.tar.gz "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
            tar -xzf vscode.tar.gz
            rm -f vscode.tar.gz
        fi
        
        # RESTAURA EXTENSÕES USANDO CAMINHO SEGURO REESCRITO ($HOME)
        if [ -f "$HOME/hybrid-os/.vscode_backup.tar.gz" ]; then
            echo -e "${CIANO}[+] Restaurando suas extensões salvadas...${SEM_COR}"
            tar -xzf "$HOME/hybrid-os/.vscode_backup.tar.gz" -C "$HOME/" 2>/dev/null
        fi
        
        echo -e "${VERDE}[OK] Disparando VS Code Fluido! Bons estudos de ADS!${SEM_COR}"
        ./VSCode-linux-x64/code "$HOME/hybrid-os" --no-sandbox --disable-gpu --disable-software-rasterizer &> /dev/null &
        ;;
    2)
        echo -e "${VERDE}[+] Montando apenas repositório via SFTP...${SEM_COR}"
        mkdir -p "$HOME/hybrid-os"
        rclone mount :sftp:storage/shared/hybrid-os "$HOME/hybrid-os" --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full 2>/dev/null &
        echo -e "${VERDE}[OK] Pasta de projetos ativa em ~/hybrid-os!${SEM_COR}"
        ;;
    3)
        echo -e "${AMARELO}[-] Fazendo backup das extensões e configurações na RAM...${SEM_COR}"
        pkill -f code
        sleep 1
        
        # Cria a lista de alvos de backup dinamicamente baseado no que existe de fato
        ALVOS_BACKUP=""
        [ -d "$HOME/.vscode" ] && ALVOS_BACKUP=".vscode"
        [ -d "$HOME/.config/Code" ] && ALVOS_BACKUP="$ALVOS_BACKUP .config/Code"

        if [ ! -z "$ALVOS_BACKUP" ]; then
            tar -czf /tmp/vscode_backup.tar.gz -C "$HOME" $ALVOS_BACKUP 2>/dev/null
            cp /tmp/vscode_backup.tar.gz "$HOME/hybrid-os/.vscode_backup.tar.gz" 2>/dev/null
            echo -e "${VERDE}[OK] Extensões salvas com sucesso no celular!${SEM_COR}"
        fi

        echo -e "${AMARELO}[-] Desmontando unidades...${SEM_COR}"
        sudo umount -f "$HOME/hybrid-os" 2>/dev/null
        sudo umount -f "$HOME/meu_google_drive" 2>/dev/null
        fusermount -uz "$HOME/hybrid-os" 2>/dev/null
        fusermount -uz "$HOME/meu_google_drive" 2>/dev/null
        pkill -f "rclone mount"
        echo -e "${VERDE}[OK] Unidades liberadas. Saindo com segurança!${SEM_COR}"
        exit 0
        ;;
    *)
        echo -e "${AMARELO}Opção inválida.${SEM_COR}"
        sleep 1
        ;;
esac
