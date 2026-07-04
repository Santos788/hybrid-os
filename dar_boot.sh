#!/bin/bash
clear

# Cores para o menu gráfico
AZUL="\033[1;34m"
CIANO="\033[1;36m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
SEM_COR="\033[0m"

# Pega o IP e Usuário passados pelo script preparar_e_rodar.sh
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

echo -e "${CIANO}VERSION:2.0  DISTRO:Android  MOUNT:sshfs  STATUS:READY${SEM_COR}"
echo ""
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR} OPTION ${CIANO}|${SEM_COR}               DESCRIPTION                      ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   1    ${CIANO}|${SEM_COR} - Montar ambiente completo (Celular + Drive)  ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   2    ${CIANO}|${SEM_COR} - Montar apenas armazenamento do Celular        ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   3    ${CIANO}|${SEM_COR} - Desmontar e sair com segurança                ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo ""

read -p "$(echo -e ${AMARELO}"Escolha uma opção [1-3]: "${SEM_COR})" opcao

case $opcao in
    1)
        echo -e "${VERDE}[+] Montando repositório do celular e nuvem...${SEM_COR}"
        mkdir -p ~/hybrid-os ~/meu_google_drive                         
        
        # 🔒 ALTERAÇÃO AQUI: Blindagem de chaves e checagem de host para evitar Reset
        sshfs -p 8022 "$USER_ALVO@$IP_ALVO:/storage/emulated/0/hybrid-os" ~/hybrid-os -o allow_other -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
        
        # Inicialização do Google Drive em segundo plano
        rclone mount gdrive: ~/meu_google_drive --allow-other --vfs-cache-mode full &
        
        echo -e "${VERDE}[OK] Ecossistema completo mapeado com sucesso!${SEM_COR}"
        ;;
    2)
        echo -e "${VERDE}[+] Montando apenas repositório do celular...${SEM_COR}"
        mkdir -p ~/hybrid-os

        # 🔒 ALTERAÇÃO AQUI: Blindagem de chaves e checagem de host para evitar Reset
        sshfs -p 8022 "$USER_ALVO@$IP_ALVO:/storage/emulated/0/hybrid-os" ~/hybrid-os -o allow_other -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
        
        echo -e "${VERDE}[OK] Pasta de projetos ativa em ~/hybrid-os!${SEM_COR}"
        ;;
    3)
        echo -e "${AMARELO}[-] Desmontando e limpando ambiente...${SEM_COR}"

        sudo umount -f ~/hybrid-os 2>/dev/null
        sudo umount -f ~/meu_google_drive 2>/dev/null
        fusermount -uz ~/hybrid-os 2>/dev/null
        fusermount -uz ~/meu_google_drive 2>/dev/null
        
        echo -e "${VERDE}[OK] Unidades liberadas. Saindo com segurança!${SEM_COR}"
        exit 0
        ;;
    *)
        echo -e "${AMARELO}Opção inválida.${SEM_COR}"
        sleep 1
        ;;
esac
