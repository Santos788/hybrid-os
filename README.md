## HybridOS V2 🚀

O HybridOS é um ecossistema de desenvolvimento híbrido e portátil projetado para transformar qualquer máquina em um ambiente de trabalho estável e persistente, utilizando um Live CD/USB Linux Mint acoplado ao armazenamento seguro de um dispositivo Android via Termux.

Esta arquitetura resolve o problema de volatilidade e perda de dados causados pelo reset da memória RAM ao reiniciar o notebook, garantindo persistência completa e inicialização ágil.
🏗️ Arquitetura do Sistema

    Host (Notebook Live CD): Roda um sistema Linux inteiramente na memória RAM (volátil).

    Core (Celular/Termux): Atua como o servidor de arquivos persistente (armazenamento real do repositório, chaves de acesso e configurações).

    Mecanismo de Link: Conectividade via SSHFS/FUSE e montagem automatizada via rede local sem fio (Wi-Fi) ou ancoragem USB.

## 🛠️ Scripts Principais
**1. preparar_e_rodar.sh (Hospedado no GitHub / Executado no Notebook)**

Responsável por preparar o ambiente limpo na RAM do notebook após o boot.

    Ajusta as diretivas do FUSE (user_allow_other).

    Remove pontos de montagem órfãos ou travados na memória.

    Instala as dependências necessárias (rclone, sshfs) contornando bloqueios de mídia física.

    Injeção de Credenciais: Puxa automaticamente o arquivo rclone.conf do celular para a RAM do notebook, eliminando a necessidade de reautenticar o Google Drive a cada boot.

    Puxa e executa de forma limpa o menu de boot armazenado no celular.

## 2. dar_boot.sh (Armazenado no Celular)

O gerenciador e inicializador do ecossistema. Fornece uma interface gráfica estilizada em arte ASCII no terminal do notebook para montar os sistemas de arquivos persistentes, incluindo o repositório de projetos e o Google Drive Virtual (Rclone).
3. limpar_tudo.sh (Armazenado no Celular)

Script de encerramento seguro. Desmonta as unidades Virtuais e limpa os rastros da memória RAM antes de desligar o notebook, garantindo a integridade e segurança dos dados no dispositivo Android.
🚀 Como Inicializar no Notebook

Com o notebook recém-iniciado em modo Live, abra o terminal e execute o disparador automatizado:

```Bash
curl -sL https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh > /tmp/run.sh && bash /tmp/run.sh

💡 Atalho de Produtividade (Alias)

Para inicializações futuras rápidas após a primeira conexão estabelecer as chaves, você pode utilizar o alias configurado no seu terminal:
Bash

alias hyb='ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh'

```
## 👥 Como Usar no seu Próprio Aparelho (Para Outros Usuários)

Se você deseja replicar o ecossistema **HybridOS** usando este repositório, siga estes passos:

1. **No seu Celular (Android):**
   * Instale o **Termux** e o pacote SSH (`pkg install openssh`).
   * Crie a pasta do projeto no armazenamento compartilhado: `mkdir -p /storage/emulated/0/hybrid-os`.
   * Clone este repositório dentro da pasta criada.
   * Configure o seu Google Drive via Rclone e salve o arquivo gerado em `/storage/emulated/0/hybrid-os/rclone.conf`.
   * Inicie o servidor SSH digitando `sshd`.

2. **No Notebook (Live CD Linux):**
   * Abra o terminal e execute o disparador:
     ```bash
     curl -sL [https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh](https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh) > /tmp/run.sh && bash /tmp/run.sh
     ```
   * Se o script não detectar o seu celular automaticamente, digite o IP do seu dispositivo e o seu usuário do Termux quando solicitado.
