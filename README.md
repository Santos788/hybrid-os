# HybridOS V2 🚀

[![Shell](https://img.shields.io/badge/language-Shell-89e051?logo=gnu-bash&logoColor=white)](https://github.com/Santos788/hybrid-os/search?l=shell)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](#-licença)
[![Status](https://img.shields.io/badge/status-ativo-success)](#)

> Ecossistema de desenvolvimento híbrido e portátil que transforma qualquer notebook em um ambiente de trabalho estável, seguro e persistente, combinando um **Live CD/USB Linux Mint** (executado em RAM) com o armazenamento persistente de um dispositivo Android via **Termux**.

---

## 📖 Sobre o projeto

O **HybridOS** nasceu para resolver um problema comum de quem trabalha em ambientes **Linux Live**: a perda total de dados e configurações a cada reinicialização, já que tudo roda na memória RAM (volátil).

A solução acopla o notebook rodando em modo Live a um celular Android via Termux, que atua como servidor de arquivos persistente. Com isso, projetos, bancos de dados e configurações do ambiente de desenvolvimento sobrevivem a qualquer reboot, sem exigir instalação local no disco do notebook.

**Principais benefícios:**

- ✅ Persistência completa de projetos, bancos de dados e configurações
- ✅ Inicialização rápida e ambiente sempre limpo (Live CD)
- ✅ Autenticação sem senha via chaves SSH
- ✅ Autodescoberta de IP na rede local (sem configuração manual de roteador)
- ✅ Backup automático de extensões e configurações do VS Code

---

## 🏗️ Arquitetura do sistema

| Camada | Papel |
|---|---|
| **Host** (Notebook Live CD) | Roda Linux Mint inteiramente na RAM — estação de trabalho efêmera, limpa e segura |
| **Core** (Celular/Termux) | Servidor de arquivos persistente: repositório, chaves de acesso, ferramentas e configurações |
| **Mecanismo de link** (Motor V2) | Túnel SFTP gerenciado via **Rclone Mount**, com tolerância a falhas, cache em disco e reconexão automática via Wi-Fi ou USB |

---

## 🛠️ Scripts principais

### `preparar_e_rodar.sh`
*Hospedado no GitHub · executado no notebook*

Prepara o ambiente limpo na RAM logo após o boot:

- Ajusta diretivas do FUSE (`user_allow_other`) com privilégios administrativos
- Remove pontos de montagem órfãos e processos travados na memória
- Instala dependências necessárias (`rclone`, `sshfs`, `nmap`)
- **Autodescoberta de IP:** varre a rede local via `nmap` para localizar o celular automaticamente
- **Injeção de chaves e credenciais:** obtém a chave SSH privada (`id_rsa_backup`) e o `rclone.conf` do celular, estabelecendo um handshake seguro sem exigir digitação de senha

### `dar_boot.sh`
*Armazenado no celular*

Gerenciador e inicializador visual do ecossistema, com interface interativa em ASCII art:

- **Opção 1 — Completo:** monta a pasta de projetos do celular em `~/hybrid-os`, monta o Google Drive virtual em `~/meu_google_drive`, restaura o backup de extensões e inicializa o VS Code otimizado para RAM (GPU desativada para evitar travamentos no ambiente Live)
- **Opção 2 — Apenas celular:** monta somente a pasta de projetos local do Termux
- **Opção 3 — Sair e salvar:** compacta `.vscode` e `.config/Code` (se existirem) em `.tar.gz`, envia ao celular, desmonta as unidades e encerra os processos com segurança

### `limpar_tudo.sh`
*Armazenado no celular*

Encerramento seguro complementar: desmonta as unidades virtuais e finaliza os processos de `rclone mount` ativos, garantindo a integridade dos dados e bancos de dados (ex: SQLite3) no dispositivo Android.

---

## 💾 Estratégia de persistência de dados

Como o host é volátil e o Android impõe restrições rígidas de segurança ao sistema de arquivos, os dados são segmentados em três camadas:

1. **Projetos e bancos de dados** (`.py`, `.json`, `.db`) — salvos de forma síncrona no armazenamento físico do Android via Rclone Mount. Cada `Ctrl+S` é gravado imediatamente no celular.
2. **Ambiente de desenvolvimento (VS Code)** — executa na velocidade da RAM do notebook. Extensões e configurações são salvas em `/tmp`, compactadas em `.vscode_backup.tar.gz` ao escolher a Opção 3, e restauradas automaticamente no próximo boot.
3. **Bibliotecas Python (`pip install`)** — o `venv` roda inteiramente na RAM (`/tmp/venv_projeto`) para contornar o bloqueio do Android a links simbólicos. As dependências são persistidas via `requirements.txt`, salvo na pasta do projeto no celular.

---

## 🐍 Guia de trabalho: Python com venv na RAM

```bash
# 1. Criar/ativar o ambiente virtual na RAM
cd ~/hybrid-os/Projetos/seu_projeto
python3 -m venv /tmp/venv_projeto
source /tmp/venv_projeto/bin/activate

# 2. Restaurar bibliotecas (primeiro boot do projeto)
pip install -r requirements.txt

# 3. Salvar novas bibliotecas sempre que instalar algo
pip install nova-biblioteca
pip freeze > requirements.txt
```

---

## 🚀 Como inicializar no notebook

Com o notebook em modo Live, abra o terminal e execute:

```bash
curl -sL https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh > /tmp/run.sh && bash /tmp/run.sh
```

---

## 👥 Como usar em seu próprio ambiente

### No celular (Android)

1. Instale o Termux e o pacote OpenSSH: `pkg install openssh`
2. Conceda acesso ao armazenamento: `termux-setup-storage`
3. Crie a pasta do projeto: `mkdir -p /storage/emulated/0/hybrid-os`
4. Gere um par de chaves SSH sem senha: `ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""`
5. Autorize a chave localmente: `cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys`
6. Faça backup da chave privada: `cp ~/.ssh/id_rsa /storage/emulated/0/hybrid-os/id_rsa_backup`
7. Configure o Google Drive via Rclone, salvando o arquivo em `/storage/emulated/0/hybrid-os/rclone.conf`
8. Inicie o servidor SSH: `sshd`

### No notebook (Live CD Linux)

Execute o comando de inicialização listado na seção acima. O script cuida do pareamento de chaves, otimização gráfica e montagem, de forma totalmente automatizada.

---

## 📋 Requisitos

- Notebook capaz de bootar Linux Mint em modo Live (CD/USB)
- Dispositivo Android com Termux instalado
- Rede Wi-Fi compartilhada entre os dois dispositivos (ou ancoragem USB)
- Conta Google Drive (opcional, para o mount virtual)

## ⚠️ Aviso

Este projeto foi desenvolvido para uso pessoal, resolvendo um problema específico de persistência em ambientes Linux Live. Use por sua conta e risco, revise os scripts antes de executá-los e mantenha backups das suas chaves de acesso.

## 🤝 Contribuindo

Sugestões, correções e melhorias são bem-vindas. Sinta-se à vontade para abrir uma *issue* ou enviar um *pull request*.

## 📄 Licença

Distribuído sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
