# HybridOS V2 🚀

O **HybridOS** é um ecossistema de desenvolvimento híbrido e portátil projetado para transformar qualquer máquina em um ambiente de trabalho estável e persistente. Ele utiliza um **Live CD/USB Linux Mint** (executado inteiramente na RAM) acoplado ao armazenamento seguro e persistente de um dispositivo Android via **Termux**.

Esta arquitetura resolve definitivamente o problema de volatilidade e perda de dados causados pelo reset da memória RAM ao reiniciar o notebook, garantindo persistência completa, segurança estrita e inicialização ágil para desenvolvedores backend.

---

## 🏗️ Arquitetura do Sistema

1. **Host (Notebook Live CD):** Roda um sistema Linux Mint inteiramente na memória RAM (volátil), ideal para estações de trabalho efêmeras, limpas e seguras.
2. **Core (Celular/Termux):** Atua como o servidor de arquivos persistente (armazenamento real do repositório, chaves de acesso, ferramentas e configurações do ecossistema).
3. **Mecanismo de Link (Motor V2):** Conectividade estável baseada em túnel **SFTP gerenciado via Rclone Mount**, garantindo tolerância a falhas, cache em disco e reconexão automática via rede local sem fio (Wi-Fi) ou ancoragem USB.

---

## 🛠️ Scripts Principais (Mantidos na Raiz)

### 1. `preparar_e_rodar.sh` (Hospedado no GitHub / Executado no Notebook)
Responsável por preparar o ambiente limpo na RAM do notebook logo após o boot.
* Ajusta as diretivas do FUSE (`user_allow_other`) com privilégios administrativos.
* Remove e limpa pontos de montagem órfãos, processos fantasmas ou tomadas travadas na memória.
* Instala as dependências necessárias (`rclone`, `sshfs`, `nmap`) contornando bloqueios de mídias físicas.
* **Autodescoberta de IP:** Escaneia a rede local via `nmap` para localizar o celular automaticamente, tornando o ecossistema independente de IPs estáticos ou configurações manuais de roteador.
* **Injeção de Chaves e Credenciais:** Puxa a chave SSH privada (`id_rsa_backup`) e o arquivo `rclone.conf` do celular para a RAM do notebook. Isso estabelece um aperto de mão (*handshake*) seguro e transparente, permitindo o acesso completo **sem exigir digitação de senhas**.

### 2. `dar_boot.sh` (Armazenado no Celular)
O gerenciador e inicializador visual do ecossistema. Fornece uma interface interativa estilizada em arte ASCII diretamente no terminal do notebook para montar as unidades virtuais:
* **Opção 1 (Completo):** Monta a pasta de projetos do celular em `~/hybrid-os` (mirando direto em `storage/shared/hybrid-os`) e o Google Drive virtual em `~/meu_google_drive`.
* **Opção 2 (Apenas Celular):** Monta exclusivamente a pasta de projetos local do Termux.
* **Opção 3 (Sair):** Executa a desmontagem segura.

### 3. `limpar_tudo.sh` (Armazenado no Celular)
Script de encerramento seguro. Desmonta as unidades virtuais e mata os processos do `rclone mount` ativos na memória RAM antes de desligar o notebook, garantindo a integridade total dos dados e arquivos de banco de dados (como SQLite3) no dispositivo Android.

---

## 🚀 Como Inicializar no Notebook

Com o notebook recém-iniciado em modo Live, abra o terminal e execute o disparador automatizado:

```bash
curl -sL https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh > /tmp/run.sh && bash /tmp/run.sh
```

## 👥 Como Usar no seu Próprio Aparelho (Para Outros Usuários)

Se você deseja replicar o ecossistema HybridOS usando este repositório como base, siga estes passos:

        No seu Celular (Android):

        Instale o Termux e o pacote OpenSSH (pkg install openssh).

        Garanta acesso ao armazenamento: termux-setup-storage.

        Crie a pasta do projeto: mkdir -p /storage/emulated/0/hybrid-os.

        Gere seu par de chaves de segurança sem senha: ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "".

        Autorize a chave localmente: cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys.

        Faça o backup da chave privada para a pasta do ecossistema: cp ~/.ssh/id_rsa /storage/emulated/0/hybrid-os/id_rsa_backup.

        Configure seu Google Drive via Rclone, salvando o arquivo gerado em /storage/emulated/0/hybrid-os/rclone.conf.

        Inicialize o servidor SSH digitando sshd.

    No Notebook (Live CD Linux):

        Execute o comando de disparo do curl listado na seção de inicialização. O script cuidará do pareamento de chaves e montagem de forma 100% automatizada.
