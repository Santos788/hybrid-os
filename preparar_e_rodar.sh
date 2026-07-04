#!/bin/bash
clear
echo -e "\033[1;36m[ HybridOS Host ] Inicializando blindagem anti-erros...\033[0m"

sudo sed -i '/user_allow_other/d' /etc/fuse.conf 2>/dev/null
echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null

sudo umount -f ~/hybrid-os 2>/dev/null
sudo umount -f ~/meu_google_drive 2>/dev/null
fusermount -uz ~/hybrid-os 2>/dev/null
fusermount -uz ~/meu_google_drive 2>/dev/null
pkill -f rclone

if ! command -v rclone &> /dev/null || ! command -v sshfs &> /dev/null || ! command -v nmap &> /dev/null; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list 2>/dev/null
    sudo apt update -y && sudo apt install rclone sshfs nmap -y >/dev/null 2>&1
fi

echo -e "\033[1;33m[ Buscando ] Procurando celular Termux na rede local...\033[0m"
FAIXA_REDE=$(ip route | grep default | awk '{print $3}' | cut -d. -f1-3)".0/24"
IP_CELULAR=$(nmap -p 8022 --open -oG - $FAIXA_REDE | grep "Host:" | awk '{print $2}' | head -n 1)

if [ -z "$IP_CELULAR" ]; then
    echo -e "\033[1;31m[ ! ] Não consegui detectar o celular automaticamente.\033[0m"
    read -p "Digite o IP do seu Termux: " IP_CELULAR
fi

USER_TERMUX="com.termux"

# 🌟 Puxa a chave física do celular que copiamos para a pasta do hybrid-os sem precisar de SSH ativo antes
echo -e "\033[1;33m[ Autenticação ] Injetando chave de segurança na RAM...\033[0m"
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Como a pasta hybrid-os está no celular, vamos simular o rclone injetando o rclone.conf local temporário
mkdir -p ~/.config/rclone
# Cria um rclone.conf temporário apenas para ler a pasta do celular local via SFTP se necessário,
# mas para pegar a chave pura, usamos o cat se já houver conexão, ou criamos o arquivo vindo da pasta compartilhada.
# No Android, a pasta /storage/emulated/0/hybrid-os fica acessível se montada. Como estamos rodando o script no note,
# vamos baixar os arquivos direto do celular usando um servidor http rápido do Python ou via o próprio GitHub.
# Para manter simples e sem erro, puxamos direto do GitHub os scripts e a chave geramos local.

# Copia a chave id_rsa_backup do celular para a RAM do note usando sftp sem checagem estrita
# Agora que adicionamos as chaves em authorized_keys, o comando cat funciona direto e sem senha!
ssh -p 8022 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$USER_TERMUX@$IP_CELULAR" "cat /storage/emulated/0/hybrid-os/id_rsa_backup" > ~/.ssh/id_rsa 2>/dev/null
chmod 600 ~/.ssh/id_rsa

# Puxa o rclone.conf do drive
ssh -p 8022 -o StrictHostKeyChecking=no "$USER_TERMUX@$IP_CELULAR" "cat /storage/emulated/0/hybrid-os/rclone.conf" > ~/.config/rclone/rclone.conf 2>/dev/null

export IP_CELULAR
export USER_TERMUX

echo -e "\033[0;32m[ OK ] Configurações injetadas!\033[0m"
sleep 1

curl -sL "https://raw.githubusercontent.com/Santos788/hybrid-os/main/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh
