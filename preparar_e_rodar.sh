#!/bin/bash
clear
echo -e "\033[1;36m[ HybridOS Host ] Inicializando blindagem anti-erros...\033[0m"

# 1. Configura o FUSE com privilégio sudo direto no sistema do notebook
sudo sed -i '/user_allow_other/d' /etc/fuse.conf 2>/dev/null
echo "user_allow_other" | sudo tee -a /etc/fuse.conf > /dev/null

# 2. Desmonta qualquer processo órfão ou fantasma preso na RAM
sudo umount -f ~/meu_google_drive 2>/dev/null
sudo umount -f ~/meu_ssd_remoto 2>/dev/null
fusermount -uz ~/meu_google_drive 2>/dev/null
fusermount -uz ~/meu_ssd_remoto 2>/dev/null

# 3. Instala as dependências se elas não existirem na RAM do Live CD
if ! command -v rclone &> /dev/null || ! command -v sshfs &> /dev/null; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list 2>/dev/null
    sudo apt update -y && sudo apt install rclone sshfs -y >/dev/null 2>&1
fi

echo -e "\033[0;32m[ OK ] Notebook pronto! Puxando ecossistema do celular...\033[0m"
sleep 1

# 4. Puxa e executa o boot oficial armazenado no celular
ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh
