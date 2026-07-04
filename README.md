# HybridOS V2 🚀

O **HybridOS** é um ecossistema de desenvolvimento híbrido e portátil projetado para transformar qualquer máquina em um ambiente de trabalho estável e persistente utilizando um **Live CD/USB Linux** acoplado ao armazenamento seguro de um dispositivo Android via **Termux**.

Esta arquitetura resolve o problema de volatilidade e perda de dados causados pelo reset da memória RAM ao reiniciar o notebook, garantindo persistência completa e inicialização ágil.

---

## 🏗️ Arquitetura do Sistema

1. **Host (Notebook Live CD):** Roda um sistema Linux inteiramente na memória RAM (volátil).
2. **Core (Celular/Termux):** Atua como o servidor de arquivos persistente (armazenamento real do repositório, chaves SSH e dados do VS Code).
3. **Mecanismo de Link:** Conectividade via SSHFS/FUSE e montagem automatizada via rede local sem fio ou ancoragem USB.

---

## 🛠️ Scripts Principais

### 1. `preparar_e_rodar.sh` (No Host/Notebook)
Responsável por preparar o ambiente limpo na RAM do notebook após o boot.
* Ajusta as diretivas do FUSE (`user_allow_other`).
* Remove pontos de montagem órfãos ou travados na memória.
* Instala as dependências necessárias (`rclone`, `sshfs`) contornando bloqueios de mídia física.
* Puxa e executa de forma limpa o menu de boot armazenado no celular.

### 2. `dar_boot.sh` (No Core/Celular)
O gerenciador e inicializador do ecossistema. Fornece um menu seletor para montar os sistemas de arquivos persistentes no notebook, incluindo o repositório local e o Google Drive via Rclone.

### 3. `limpar_tudo.sh` (No Core/Celular)
Script de encerramento seguro. Desmanta os sistemas de arquivos e limpa os rastros da memória antes de desligar o notebook, garantindo a integridade dos dados no dispositivo persistente.

---

## 🚀 Como Inicializar no Notebook

Com o notebook recém-iniciado em modo Live, basta abrir o terminal e rodar o disparador automatizado hospedado diretamente no GitHub:

```bash
curl -sL [https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh](https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh) > /tmp/run.sh && bash /tmp/run.sh
