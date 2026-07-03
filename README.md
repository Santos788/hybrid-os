# HybridOS V2 🚀

Um ambiente de desenvolvimento portátil, agnóstico e de alta performance, projetado para rodar **100% na memória RAM (Linux Live)**, utilizando o armazenamento de um dispositivo Android como core persistente e criptografado.

---

## 💡 O Conceito
O **HybridOS** elimina a volatilidade e a falta de persistência de ambientes *Live CD/USB*. Ele transforma seu smartphone (via Termux) em um "SSD Remoto" seguro via barramento USB, monta partições em cache na RAM do host, sincroniza automações na nuvem e sobe qualquer IDE ou ferramenta sem tocar ou gravar no disco físico da máquina.

[+] Host: Linux Mint (RAM Live)
[+] Core: Android via Termux (USB)
[+] Storage: SSHFS Persistent
[+] Cloud: Rclone + Google Drive
[+] IDE/Launcher: Dynamic Menu (.AppImage)



---

## 🛠️ Novas Funcionalidades & Arquitetura (V2)
* **Launcher Dinâmico via Menu:** O script faz uma varredura automática no armazenamento do Android e monta um menu seletor numérico no terminal. Permite escolher e carregar instantaneamente **qualquer aplicativo `.AppImage`** (VS Code, Postman, DBeaver, Insomnia) direto na RAM do host.
* **Fusão Securitária (SSHFS):** Montagem do sistema de arquivos mobile via barramento USB com bypass de permissões FUSE (`user_allow_other`) injetado direto em `/etc/fuse.conf` a cada boot.
* **Córtex Externo (Rclone):** Integração automatizada com o Google Drive, espelhando configurações e arquivos guardados no dispositivo móvel de forma volátil.
* **Bypass Gráfico (Intel Haswell):** Otimizações em nível de Kernel e flags do Chromium (`--no-sandbox`, `--disable-gpu`, `--disable-software-rasterizer`) eliminando travamentos gráficos e gargalos em hardwares legados.

---

## 🌍 Portabilidade & Pré-requisitos
O script configura o computador host completamente do zero automaticamente, exigindo apenas as seguintes definições no dispositivo Android:
1. **Termux configurado** com acesso ao armazenamento (`termux-setup-storage`).
2. **Servidor SSH ativo** rodando no Termux (`sshd` na porta `8022`).
3. **Ancoragem USB (Tethering)** ativa entre o celular e o computador.
4. O script `dar_boot.sh` localizado na pasta raiz do repositório no celular.

---

## 🚀 Como Executar

Para iniciar o ecossistema completo em uma nova sessão RAM limpa, utilize o comando único:

```bash
ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh

⚡ Dica de Produtividade

Crie um atalho prático (alias) no terminal do ambiente local para não precisar decorar o comando:
Bash

alias hyb='ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh'

Depois, basta digitar apenas hyb para colocar toda a infraestrutura de pé!

Developed by Clayton (Santos788) 💻
