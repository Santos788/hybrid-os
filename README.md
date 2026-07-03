# HybridOS 🚀

Um ambiente de desenvolvimento portátil, persistente e seguro, projetado para rodar **100% na memória RAM (Linux Live)** utilizando o armazenamento de um dispositivo Android como core persistente.

---

## 💡 O Conceito
O **HybridOS** resolve o problema de trabalhar em ambientes *Live CD/USB*. Ele transforma seu celular (via Termux) em um "SSD Remoto" criptografado e seguro, monta partições em cache na RAM do host, sincroniza automações na nuvem e sobe o ambiente de código isolado de escrita em disco físico.

    .MMMMMMMMMMMMMMMMMMMMMMMMM.
  .MMm----------------------mMM.     [+] Host: Linux Mint (RAM Live)
 .MM-  .MMMMMMMMMMMMMMMMMMM.  -MM.   [+] Core: Android via Termux (USB)
 MM-  .MMMMMMMMMMMMMMMMMMMMM.  -MM   [+] Storage: SSHFS Persistent
MM-  .MM   MMMMMMM   MMMMMM.   -MM   [+] Cloud: Rclone + Google Drive
    MMMMMMMMMMMMMMMMMMMMMMMMMMMMM    [+] IDE: VS Code (.AppImage na RAM)


---

## 🛠️ Funcionalidades & Arquitetura
* **Fusão Securitária (SSHFS):** Montagem direta do sistema de arquivos do Android via barramento USB com bypass de permissões FUSE (`user_allow_other`).
* **Córtex Externo (Rclone):** Integração automática com o Google Drive utilizando arquivos de configuração persistidos de forma segura no dispositivo móvel.
* **Isolamento de Cache RAM:** O VS Code é carregado e executado direto no diretório `/tmp/` com persistência de dados do usuário (`vscode_data`) direcionada de volta ao celular.
* **Bypass de Hardware Antigo:** Otimizado com flags do Chromium (`--no-sandbox`, `--disable-gpu`, `--disable-software-rasterizer`) eliminando falhas de renderização gráfica e travamentos em arquiteturas legadas (como Intel Haswell).

---

## 🌍 Portabilidade & Requisitos (Para Outros Utilizadores)

O script foi desenhado para ser agnóstico no lado do PC host (instalando dependências e configurando o FUSE automaticamente), mas o utilizador precisa de garantir os seguintes pré-requisitos no seu dispositivo Android:

1. **Termux configurado** com acesso ao armazenamento interno (`termux-setup-storage`).
2. **Servidor SSH ativo** rodando no Termux (`sshd` na porta `8022`).
3. **Ancoragem USB (Tethering USB)** ativa entre o telemóvel e o computador.
4. O script `dar_boot.sh` guardado no armazenamento interno do Android respeitando a estrutura do repositório.

---

## 🚀 Como Executar

Para dar o boot completo na infraestrutura a partir de uma nova sessão RAM, utilize o comando adaptando o IP para o gateway do seu dispositivo:

```bash
ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh

⚡ Dica de Produtividade

Crie um atalho prático (alias) no terminal do seu ambiente local:
Bash

alias hyb='ssh -p 8022 com.termux@192.168.141.218 "cat /storage/emulated/0/hybrid-os/dar_boot.sh" > /tmp/boot.sh && bash /tmp/boot.sh'

Agora basta digitar hyb para colocar todo o ecossistema de pé!

Developed by Clayton (Santos788) 💻
