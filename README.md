# 🚀 Hybrid_OS — Transient RAM Architecture & Distributed Storage

Uma infraestrutura de ambiente de desenvolvimento portátil, de alto desempenho e voltada para segurança. O **Hybrid_OS** executa um ambiente de desenvolvimento completo diretamente na memória RAM (Linux Live-USB), estabelecendo uma ponte remota segura com um dispositivo Android (Termux) via SSH/Rclone para persistência distribuída de dados.

---

## 🏗️ Arquitetura & Conceito

```text
  ┌───────────────────────┐         SSH / Rclone         ┌─────────────────────────┐
  │    Android / Termux   │ ◄──────────────────────────► │     Linux Live-USB      │
  │ (Persistência / Dados) │  (Descoberta Automática /   │    (Execução em RAM)    │
  └───────────────────────┘     Verificação Rota)        └─────────────────────────┘
                                                                      │
                                                                      ▼
                                                         ┌─────────────────────────┐
                                                         │ VS Code / Dev Tools /   │
                                                         │ Cleanup pós-execução    │
                                                         └─────────────────────────┘

    Execução Transiente em RAM: Garante altíssima velocidade de leitura/escrita para o ambiente de desenvolvimento, isolando a execução e eliminando rastros no sistema hospedeiro.

    Ponte Android via Termux: Montagem de volume remoto e sincronização transparente de arquivos usando Rclone sobre um túnel SSH seguro na porta 8022.

    DevSecOps & Sanitização: Rotinas automatizadas para validação de chaves SSH do host e encerramento seguro com limpeza de tokens/credenciais da RAM.

🛠️ Estrutura do Projeto
Plaintext

hybrid-os/
├── scripts/
│   ├── setup.sh         # Instalação e configuração de dependências no Live-USB
│   ├── boot.sh          # Descoberta de IP, validação SSH, menu e montagem via Rclone
│   └── cleanup.sh       # Desmontagem de volumes e limpeza de dados/credenciais em RAM
├── .gitignore
├── LICENSE
└── README.md

🚀 Como Executar
Pré-requisitos

    Dispositivo Android com Termux e o servidor SSH ativo (sshd).

    Computador rodando Linux Mint Live-USB conectado na mesma rede Wi-Fi.

Boot Rápido (Comando Único)

Devido às restrições de execução (noexec) nativas de partições de pendrives em ambientes Live, o projeto deve ser espelhado na memória RAM (/tmp) para execução imediata.

Execute o comando unificado abaixo no terminal:
Bash

cd ~/hybrid-os && git pull && rm -rf /tmp/hybrid-os-app && cp -r ~/hybrid-os /tmp/hybrid-os-app && cd /tmp/hybrid-os-app && bash scripts/setup.sh && bash scripts/boot.sh

Passo a Passo Manual

Se preferir executar etapa por etapa:

    Atualizar o repositório local no pendrive:
    Bash

cd ~/hybrid-os && git pull

Copiar o ambiente para a memória RAM:
Bash

rm -rf /tmp/hybrid-os-app && cp -r ~/hybrid-os /tmp/hybrid-os-app && cd /tmp/hybrid-os-app

Preparar as dependências (Setup):
Bash

bash scripts/setup.sh

Iniciar a ponte e o VS Code (Boot):
Bash

bash scripts/boot.sh

Encerrar a sessão e limpar a RAM (Cleanup):
Bash

    bash scripts/cleanup.sh

🛡️ Segurança (AppSec & Operacional)

    Sanitização de Sessão: Nenhum dado sensível ou chave de acesso permanece gravado no disco rígido local após o desligamento.

    Ambiente Isolado: Execução em RAM via diretórios temporários controlados.

    Validação de Identidade SSH: Checagem dinâmica das assinaturas de host (known_hosts) antes de autorizar a montagem do volume via Rclone SFTP.

👨‍💻 Autor

Desenvolvido por Clayton Santos
