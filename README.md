# HybridOS — Transient RAM Architecture & Distributed Storage

<video src="./img/demo.webm" width="100%" controls autoplay loop muted></video>

Este script em Bash automatiza a inicialização de um ambiente de desenvolvimento e operação persistente, rodando 100% na memória RAM através de uma sessão Linux Live. O ecossistema transforma um dispositivo Android (via SSHFS) em armazenamento físico persistente e o Google Drive (via Rclone) em um córtex de backup assíncrono em nuvem.

## 🛠️ Tecnologias e Protocolos
* **Bash Scripting:** Tratamento dinâmico de fluxos de dados com barras de progresso via monitoramento de PIDs.
* **SSHFS (SSH Filesystem):** Montagem do storage remoto via interface de rede USB (Tethering).
* **Rclone (FUSE3):** Integração com Cloud Storage utilizando VFS-Cache para persistência assíncrona.
* **Tmpfs:** Execução de binários portáteis (.AppImage) alocados direto em memória RAM para máxima performance e segurança.

## 🛡️ Abordagem de Segurança (Foco em OPSEC & Pentest)
O HybridOS foi desenhado sob o conceito de **Estação Amnésica/Efêmera**, ideal para cenários que exigem alta segurança operacional (OPSEC):
* **Arquitetura Anti-Forense (*Stateless*):** Nossos dados nunca tocam o disco rígido (SSD/HD) local do host. Se a máquina for desligada abruptamente, nenhum rastro físico ou artefato digital permanece para análise forense.
* **Isolamento de Vetores de Ataque:** Aplicativos em formato `.AppImage` são copiados e executados direto na memória RAM (`/tmp`). Isso impede a persistência de malwares ou spywares no sistema de arquivos do Host.
* **Pivoting de Armazenamento:** Uso de redes móveis e túneis SSH em interfaces dinâmicas (`gateway-usb0`), emulando as táticas utilizadas para exfiltração de dados segura em auditorias de segurança.

---

## ⚙️ Configuração do Ambiente (Passo a Passo)

Como o ambiente do notebook roda em modo Live (RAM), a configuração pesada fica concentrada no dispositivo Android, enquanto o Host é preparado dinamicamente pelo script de boot.

### 1. No Dispositivo Android (Termux)
O celular atua como o servidor de armazenamento seguro. Precisamos instalar o servidor SSH e configurar a estrutura de arquivos.

1. **Atualize os pacotes do Termux e instale o OpenSSH:**
   ```bash
   pkg update && pkg upgrade -y
   pkg install openssh -y

    Configure uma senha para o seu usuário do Termux:
    Bash

passwd

(Digite uma senha segura e guarde-a. Ela será solicitada no momento do boot).

Garanta que o Termux tenha acesso ao armazenamento interno do celular:
Bash

termux-setup-storage

(Autorize a permissão na janela pop-up que aparecer na tela).

Inicie o servidor SSH na porta padrão do Termux (8022):
Bash

sshd

Crie a estrutura de diretórios na memória interna do celular:
Bash

    mkdir -p /storage/emulated/0/linux_profile/.config
    mkdir -p /storage/emulated/0/vscode_data

    (É nesta raiz /storage/emulated/0/ que você deve salvar o script dar_boot.sh e qualquer executável .AppImage que deseja injetar na RAM).

2. No Notebook (Host Linux Live)

No primeiro uso, precisamos apenas mapear a nuvem do Google Drive. Nos boots seguintes, o módulo de auto-recuperação do script cuidará do resto das dependências.

    Conecte o celular ao notebook via cabo USB e ative a opção "Ancoragem USB" (Tethering USB) nas configurações do Android.

    Configure o seu ambiente do Google Drive via Rclone:
    Bash

    # Instale temporariamente para a primeira configuração
    sudo apt update && sudo apt install rclone fuse3 -y

    # Inicie o assistente de configuração
    rclone config

        No menu: escolha n (New remote), dê o nome de gdrive.

        Selecione a opção correspondente ao Google Drive.

        Siga o passo a passo no navegador para autorizar o acesso à sua conta.

📦 Funcionalidades Principais do Script

    Auto-Recuperação: Varre e instala dependências ausentes do Kernel (sshfs, rclone, fuse3) de forma transparente a cada inicialização no Linux Live.

    Autoload Dinâmico de Payloads: Escaneia a raiz do dispositivo móvel e injeta automaticamente qualquer aplicativo .AppImage (como o VS Code portátil) na RAM, exibindo o progresso real de cópia e disparando a execução em segundo plano.

    Auto-Clean de Barramento: Higieniza processos zumbis e pontos de montagem travados antes da inicialização para prevenir erros críticos de permissão (Permission Denied).

🚀 Inicialização e Execução

Com a ancoragem USB ativa no Android e o servidor sshd iniciado no Termux, abra o terminal do Host (Notebook) e execute o comando mestre:
Bash

ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh
