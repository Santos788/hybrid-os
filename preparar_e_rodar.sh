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

# 3. Instala dependências e ferramentas de rede se não existirem
if ! command -v rclone &> /dev/null || ! command -v sshfs &> /dev/null || ! command -v nmap &> /dev/null; then
    sudo sed -i '/cdrom:/d' /etc/apt/sources.list 2>/dev/null
    sudo apt update -y && sudo apt install rclone sshfs nmap -y >/dev/null 2>&1
fi

# 🌟 AUTOMAÇÃO: Descobre o IP do Celular na rede automaticamente
echo -e "\033[1;33m[ Buscando ] Procurando celular Termux na rede local...\033[0m"

# Pega a faixa de IP do notebook (ex: 192.168.141.0/24)
FAIXA_REDE=$(ip route | grep default | awk '{print $3}' | cut -d. -f1-3)".0/24"

# Escaneia a rede procurando quem está com a porta 8022 aberta
IP_CELULAR=$(nmap -p 8022 --open -oG - $FAIXA_REDE | grep "Host:" | awk '{print $2}' | head -n 1)

if [ -z "$IP_CELULAR" ]; then
    echo -e "\033[1;31m[ ERRO ] Celular não encontrado! Certifique-se de que o Termux está aberto e o 'sshd' rodando.\033[0m"
    exit 1
fi

echo -e "\033[1;32m[ Encontrado ] Celular detectado no IP: $IP_CELULAR\033[0m"

# 4. Cria a pasta do rclone no notebook e puxa a configuração salva no celular
mkdir -p ~/.config/rclone
ssh -p 8022 com.termux@$IP_CELULAR "cat /storage/emulated/0/hybrid-os/rclone.conf" > ~/.config/rclone/rclone.conf 2>/dev/null

echo -e "\033[0;32m[ OK ] Configurações injetadas! Puxando ecossistema do celular...\033[0m"
sleep 1

# 5. Puxa e executa o boot oficial armazenado no celular usando o IP dinâmico
ssh -p 8022 com.termux@$IP_CELULAR "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh
