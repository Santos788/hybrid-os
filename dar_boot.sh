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
echo -e "${CIANO}|${SEM_COR}   3    ${CIANO}|${SEM_COR} - Desmontar e sair com segurança                ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo ""

read -p "$(echo -e ${AMARELO}"Escolha uma opção [1-3]: "${SEM_COR})" opcao

case $opcao in
    1)
        echo -e "${VERDE}[+] Montando repositório via SFTP e nuvem...${SEM_COR}"
        mkdir -p ~/hybrid-os ~/meu_google_drive                         
        
        rclone mount :sftp:storage/shared/hybrid-os ~/hybrid-os --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full 2>/dev/null &
        rclone mount gdrive: ~/meu_google_drive --allow-other --vfs-cache-mode full &
        
        echo -e "${VERDE}[OK] Ecossistema mapeado com sucesso!${SEM_COR}"
        
        # 🚀 AUTOMAÇÃO DO VS CODE LEVE NA RAM
        echo -e "${CIANO}[+] Preparando VS Code Otimizado na RAM...${SEM_COR}"
        cd /tmp
        if [ ! -d "VSCode-linux-x64" ]; then
            echo -e "${AMARELO}[...] Baixando estrutura do editor (Apenas no primeiro boot)...${SEM_COR}"
            wget -q --show-progress -O vscode.tar.gz "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"
            tar -xzf vscode.tar.gz
            rm -f vscode.tar.gz
        fi
        
        echo -e "${VERDE}[OK] Disparando VS Code Fluido! Bons estudos de ADS!${SEM_COR}"
        # Abre o VS Code apontando direto para a pasta do seu projeto e rodando liso
        ./VSCode-linux-x64/code ~/hybrid-os --extensions-dir ~/hybrid-os/.vscode_ext --user-data-dir ~/hybrid-os/.vscode_data --no-sandbox --disable-gpu --disable-software-rasterizer &> /dev/null &
        ;;
    2)
        echo -e "${VERDE}[+] Montando apenas repositório via SFTP...${SEM_COR}"
        mkdir -p ~/hybrid-os
        rclone mount :sftp:storage/shared/hybrid-os ~/hybrid-os --sftp-host="$IP_ALVO" --sftp-port=8022 --sftp-user="$USER_ALVO" --sftp-key-file="$HOME/.ssh/id_rsa" --allow-other --vfs-cache-mode full 2>/dev/null &
        echo -e "${VERDE}[OK] Pasta de projetos ativa em ~/hybrid-os!${SEM_COR}"
        ;;
    3)
        echo -e "${AMARELO}[-] Desmontando e limpando ambiente...${SEM_COR}"
        sudo umount -f ~/hybrid-os 2>/dev/null
        sudo umount -f ~/meu_google_drive 2>/dev/null
        fusermount -uz ~/hybrid-os 2>/dev/null
        fusermount -uz ~/meu_google_drive 2>/dev/null
        pkill -f "rclone mount"
        pkill -f code
        echo -e "${VERDE}[OK] Unidades liberadas. Saindo com segurança!${SEM_COR}"
        exit 0
        ;;
    *)
        echo -e "${AMARELO}Opção inválida.${SEM_COR}"
        sleep 1
        ;;
esac
