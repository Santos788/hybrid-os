#!/bin/bash
set -e

AZUL="\033[1;34m"
VERDE="\033[1;32m"
CIANO="\033[1;36m"
SEM_COR="\033[0m"

echo -e "${AZUL}[+] Preparando o ambiente do Pendrive Live (HybridOS)...${SEM_COR}"

# 1. Atualizar repositórios e instalar dependências essenciais
echo -e "${CIANO}[...] Instalando ferramentas necessárias (rclone, fuse, ssh, wget)...${SEM_COR}"
sudo apt update -y
sudo apt install -y rclone fuse3 openssh-client wget tar

# 2. Habilitar suporte ao FUSE para usuários não-root
echo -e "${CIANO}[...] Ajustando permissões do FUSE...${SEM_COR}"
sudo sed -i 's/#user_allow_other/user_allow_other/g' /etc/fuse.conf 2>/dev/null || true

# 3. Criar a estrutura de diretórios necessária
echo -e "${CIANO}[...] Criando diretórios no sistema...${SEM_COR}"
mkdir -p "$HOME/hybrid-os"
mkdir -p "$HOME/meu_google_drive"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# 4. Dar permissão de execução ao script de boot
if [ -f "$HOME/scripts/boot.sh" ]; then
    chmod +x "$HOME/scripts/boot.sh"
fi

echo -e "${VERDE}[OK] Instalação concluída com sucesso!${SEM_COR}"
echo -e "${CIANO}Para iniciar o ambiente, execute: ./scripts/boot.sh${SEM_COR}"
