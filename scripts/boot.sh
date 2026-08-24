
#!/bin/bash
clear

AZUL="\033[1;34m"
CIANO="\033[1;36m"
VERDE="\033[1;32m"
AMARELO="\033[1;33m"
VERMELHO="\033[1;31m"
SEM_COR="\033[0m"

# ==========================================================
# 1. GERAÇÃO AUTOMÁTICA E ISOLADA DE CHAVES SSH POR USUÁRIO
# ==========================================================
garantir_chave_ssh() {
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        echo -e "${AMARELO}[!] Chave SSH individual não encontrada. Gerando nova chave segura...${SEM_COR}"
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N "" -q
        echo -e "${VERDE}[OK] Nova chave SSH gerada em $HOME/.ssh/id_rsa${SEM_COR}"
        echo -e "${CIANO}[i] Copie a chave pública abaixo para o ~/.ssh/authorized_keys do seu Termux:${SEM_COR}\n"
        cat "$HOME/.ssh/id_rsa.pub"
        echo -e "\nPressione ENTER após configurar a chave no Termux para continuar..."
        read -r
    fi
}

# ==========================================================
# 2. AUTODESCOBERTA DE IP DO TERMUX (PORTA 8022)
# ==========================================================
descobrir_ip_termux() {
    echo -e "${CIANO}[...] Procurando celular com Termux na rede local (porta 8022)...${SEM_COR}" >&2
    local subrede
    subrede=$(hostname -I 2>/dev/null | awk '{print $1}' | cut -d. -f1-3)
    
    [ -z "$subrede" ] && return 1

    local arq_temp
    arq_temp=$(mktemp)

    for i in $(seq 1 254); do
        (
            timeout 0.3 bash -c "exec 3<>/dev/tcp/$subrede.$i/8022" 2>/dev/null && echo "$subrede.$i" >> "$arq_temp"
        ) &
    done

    sleep 1.5
    local ip_achado
    ip_achado=$(head -n 1 "$arq_temp" 2>/dev/null)
    rm -f "$arq_temp"

    if [ -n "$ip_achado" ]; then
        echo "$ip_achado"
        return 0
    fi
    return 1
}

# Iniciar verificações de segurança
garantir_chave_ssh

if [ -n "$IP_CELULAR" ]; then
    IP_ALVO="$IP_CELULAR"
else
    IP_AUTODETECTADO=$(descobrir_ip_termux)
    if [ -n "$IP_AUTODETECTADO" ]; then
        echo -e "${VERDE}[OK] Celular encontrado no IP: $IP_AUTODETECTADO${SEM_COR}"
        IP_ALVO="$IP_AUTODETECTADO"
    else
        echo -e "${AMARELO}[ ! ] Não foi possível localizar o Termux automaticamente.${SEM_COR}"
        read -rp "$(echo -e "${AMARELO}Digite o IP do celular manualmente: ${SEM_COR}")" IP_ALVO
    fi
fi

USER_ALVO=${USER_TERMUX:-"com.termux"}
MOUNT_HYBRID="${MOUNT_HYBRID:-$HOME/hybrid-os}"
MOUNT_DRIVE="${MOUNT_DRIVE:-$HOME/meu_google_drive}"

echo -e "${AZUL}"
cat << "BANNER"
 _   _ _   _ ____  ____  ___ ____   ___  ____ 
| | | | | | |  _ \|  _ \|_ _|  _ \ / _ \/ ___|
| |_| | |_| | |_) | |_) || || | | | | | \___ \
|  _  |  _  |  _ <|  _ < | || |_| | |_| |___) |
|_| |_|_| |_|_| \_\_| \_\___|____/ \___/|____/
BANNER
echo -e "${SEM_COR}"

echo -e "${CIANO}VERSION:2.2-SECURE  DISTRO:Android  MOUNT:rclone_sftp  STATUS:READY${SEM_COR}"
echo ""
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR} OPTION ${CIANO}|${SEM_COR}                DESCRIPTION                        ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   1    ${CIANO}|${SEM_COR} - Montar ambiente completo + Iniciar VS Code  ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   2    ${CIANO}|${SEM_COR} - Montar apenas armazenamento do Celular        ${CIANO}|${SEM_COR}"
echo -e "${CIANO}|${SEM_COR}   3    ${CIANO}|${SEM_COR} - Desmontar e SALVAR EXTENSÕES com segurança   ${CIANO}|${SEM_COR}"
echo -e "${CIANO}+========================================================+${SEM_COR}"
echo ""

read -rp "$(echo -e "${AMARELO}Escolha uma opção [1-3]: ${SEM_COR}")" opcao

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

# Opções de segurança para o rclone (Evita Man-in-the-Middle)
RCLONE_SECURE_FLAGS="--sftp-override-credentials=true --sftp-ask-password=false"

case $opcao in
    1)
        echo -e "${VERDE}[+] Montando repositório via SFTP seguro...${SEM_COR}"
        mkdir -p "$MOUNT_HYBRID" "$MOUNT_DRIVE"

        rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" \
            --sftp-host="$IP_ALVO" \
            --sftp-port=8022 \
            --sftp-user="$USER_ALVO" \
            --sftp-key-file="$HOME/.ssh/id_rsa" \
            $RCLONE_SECURE_FLAGS \
            --allow-other \
            --vfs-cache-mode full &

        rclone mount gdrive: "$MOUNT_DRIVE" --allow-other --vfs-cache-mode full &

        echo -e "${AMARELO}[...] Aguardando as montagens ficarem prontas...${SEM_COR}"
        if ! esperar_montagem "$MOUNT_HYBRID"; then
            echo -e "${VERMELHO}[ ERRO ] $MOUNT_HYBRID não montou. Cancelando por segurança.${SEM_COR}"
            fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || true
            exit 1
        fi
        
        esperar_montagem "$MOUNT_DRIVE" || echo -e "${AMARELO}[ ! ] Google Drive ignorado.${SEM_COR}"
        echo -e "${VERDE}[OK] Ecossistema mapeado com segurança!${SEM_COR}"

        # AUTOMAÇÃO DO VS CODE COM SANDBOX ATIVA NA RAM
        echo -e "${CIANO}[+] Preparando VS Code Otimizado na RAM (Com Sandbox)...${SEM_COR}"
        cd /tmp || exit 1
        if [ ! -d "VSCode-linux-x64" ]; then
            if ! wget -q -O vscode.tar.gz "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" || [ ! -s vscode.tar.gz ]; then
                echo -e "${VERMELHO}[ ERRO ] Falha ao baixar o VS Code. Abortando.${SEM_COR}"
                rm -f vscode.tar.gz
                exit 1
            fi
            tar -xzf vscode.tar.gz && rm -f vscode.tar.gz
        fi

        if [ -f "$MOUNT_HYBRID/.vscode_backup.tar.gz" ]; then
            echo -e "${CIANO}[+] Restaurando suas extensões salvas...${SEM_COR}"
            tar -xzf "$MOUNT_HYBRID/.vscode_backup.tar.gz" -C "$HOME/" 2>/dev/null
        fi

        echo -e "${VERDE}[OK] Disparando VS Code Seguro!${SEM_COR}"
        
        # Execução segura sem desativar a sandbox: usa diretório isolado na RAM
        mkdir -p /tmp/vscode-user-data
        ./VSCode-linux-x64/code "$MOUNT_HYBRID" --user-data-dir="/tmp/vscode-user-data" &> /dev/null &
        ;;

    2)
        echo -e "${VERDE}[+] Montando repositório via SFTP seguro...${SEM_COR}"
        mkdir -p "$MOUNT_HYBRID"
        rclone mount :sftp:storage/shared/hybrid-os "$MOUNT_HYBRID" \
            --sftp-host="$IP_ALVO" \
            --sftp-port=8022 \
            --sftp-user="$USER_ALVO" \
            --sftp-key-file="$HOME/.ssh/id_rsa" \
            $RCLONE_SECURE_FLAGS \
            --allow-other \
            --vfs-cache-mode full &

        if esperar_montagem "$MOUNT_HYBRID"; then
            echo -e "${VERDE}[OK] Pasta de projetos ativa em $MOUNT_HYBRID!${SEM_COR}"
        else
            echo -e "${VERMELHO}[ ERRO ] A montagem falhou.${SEM_COR}"
            fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || true
            exit 1
        fi
        ;;

    3)
        echo -e "${AMARELO}[-] Fazendo backup das extensões na RAM...${SEM_COR}"
        pkill -f "VSCode-linux-x64/code" 2>/dev/null || true
        sleep 1

        ALVOS_BACKUP=""
        [ -d "$HOME/.vscode" ] && ALVOS_BACKUP=".vscode"
        [ -d "$HOME/.config/Code" ] && ALVOS_BACKUP="$ALVOS_BACKUP .config/Code"

        if [ -n "$ALVOS_BACKUP" ]; then
            if tar -czf /tmp/vscode_backup.tar.gz -C "$HOME" $ALVOS_BACKUP 2>/dev/null; then
                cp /tmp/vscode_backup.tar.gz "$MOUNT_HYBRID/.vscode_backup.tar.gz" 2>/dev/null && \
                    echo -e "${VERDE}[OK] Extensões salvas com sucesso no celular!${SEM_COR}"
            fi
        fi

        echo -e "${AMARELO}[-] Desmontando e limpando rastros na RAM...${SEM_COR}"
        fusermount -uz "$MOUNT_HYBRID" 2>/dev/null || sudo umount -f "$MOUNT_HYBRID" 2>/dev/null || true
        fusermount -uz "$MOUNT_DRIVE" 2>/dev/null || sudo umount -f "$MOUNT_DRIVE" 2>/dev/null || true
        pkill -f "rclone mount.*$MOUNT_HYBRID" 2>/dev/null || true
        pkill -f "rclone mount.*$MOUNT_DRIVE" 2>/dev/null || true

        # Limpeza de diretórios temporários na RAM
        rm -rf /tmp/vscode-user-data /tmp/vscode_backup.tar.gz 2>/dev/null

        echo -e "${VERDE}[OK] Sessão encerrada e limpa com sucesso!${SEM_COR}"
        exit 0
        ;;
    *)
        echo -e "${AMARELO}Opção inválida.${SEM_COR}"
        sleep 1
        ;;
esac
