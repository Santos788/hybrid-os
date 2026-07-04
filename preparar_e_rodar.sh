#!/bin/bash
clear
echo -e "\033[1;36m[ HybridOS Host ] Inicializando blindagem anti-erros...\033[0m"

# 1. Configura o FUSE com privilégio sudo direto no sistema do notebook
sudo sed -i '/user_allow_other/d' /etc/fuse.conf 2>/dev/null
echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null

# 2. Desmonta qualquer processo órfão ou fantasma preso na RAM
sudo umount -f ~/hybrid-os 2>/dev/null
sudo umount -f ~/meu_google_drive 2>/dev/null
fusermount -uz ~/hybrid-os 2>/dev/null
fusermount -uz ~/meu_google_drive 2>/dev/null
pkill -f rclone

# 3. Instala dependências e ferramentas de rede se não existirem
if ! command -v rclone &> /dev/null || ! command -v sshfs &> /dev/null || ! command -v nmap &> /dev/null; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list 2>/dev/null
    sudo apt update -y && sudo apt install rclone sshfs nmap -y >/dev/null 2>&1
fi

# 4. Descobre o IP do Celular na rede automaticamente
echo -e "\033[1;33m[ Buscando ] Procurando celular Termux na rede local...\033[0m"
FAIXA_REDE=$(ip route | grep default | awk '{print $3}' | cut -d. -f1-3)".0/24"
IP_CELULAR=$(nmap -p 8022 --open -oG - $FAIXA_REDE | grep "Host:" | awk '{print $2}' | head -n 1)

if [ -z "$IP_CELULAR" ]; then
    echo -e "\033[1;31m[ ! ] Não consegui detectar o celular automaticamente.\033[0m"
    read -p "Digite o IP do seu Termux: " IP_CELULAR
fi

USER_TERMUX="com.termux"

# 🌟 BLINDAGEM DE AUTENTICAÇÃO: Injeta as chaves SSH do celular na RAM do notebook
echo -e "\033[1;33m[ Autenticação ] Sincronizando chaves de segurança...\033[0m"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Como o script 'cat' precisa ler do Termux, se pedir senha/passphrase uma vez, digite-a.
# Ele vai tentar puxar a chave id_rsa privada que você usa.
ssh -p 8022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER_TERMUX@$IP_CELULAR" "cat ~/.ssh/id_rsa" > ~/.ssh/id_rsa 2>/dev/null
chmod 600 ~/.ssh/id_rsa

# 5. Cria a pasta do rclone no notebook e puxa a configuração salva no celular
mkdir -p ~/.config/rclone
ssh -p 8022 -o StrictHostKeyChecking=no "$USER_TERMUX@$IP_CELULAR" "cat /storage/emulated/0/hybrid-os/rclone.conf" > ~/.config/rclone/rclone.conf 2>/dev/null

echo -e "\033[0;32m[ OK ] Configurações injetadas! Puxando ecossistema do celular...\033[0m"
sleep 1

# Exporta as variáveis para o dar_boot.sh ler em seguida
export IP_CELULAR
export USER_TERMUX

# 6. Puxa e executa o boot oficial armazenado no celular
ssh -p 8022 -o StrictHostKeyChecking=no "$USER_TERMUX@$IP_CELULAR" "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh
