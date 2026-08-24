# 🚀 Hybrid_OS — Transient RAM Architecture & Distributed Storage

Uma infraestrutura de ambiente de desenvolvimento portátil, de alto desempenho e voltada para segurança. O **Hybrid_OS** executa um ambiente de desenvolvimento completo diretamente na memória RAM (Linux Live-USB), estabelecendo ponte remota segura com um dispositivo Android (Termux) via SSH/Rclone para persistência distribuída de dados.

---

## 🏗️ Arquitetura & Conceito

```text
  ┌───────────────────────┐         SSH / Rclone         ┌─────────────────────────┐
  │   Android / Termux    │ ◄──────────────────────────► │    Linux Live-USB       │
  │ (Persistência / Dados) │  (Descoberta Automática /   │   (Execução em RAM)     │
  └───────────────────────┘     Verificação Rota)        └─────────────────────────┘
                                                                      │
                                                                      ▼
                                                         ┌─────────────────────────┐
                                                         │ VS Code / Dev Tools /   │
                                                         │ Cleanup pós-execução    │
                                                         └─────────────────────────┘

    Execução Transiente em RAM: Garante altíssima velocidade de leitura e escrita para o ambiente de desenvolvimento, minimizando rastros no sistema hospedeiro.

    Ponte com Android via Termux: Montagem de volume remoto e sincronização transparente de arquivos utilizando rclone sobre túnel SSH seguro.

    DevSecOps & Limpeza em RAM: Rotina automatizada de encerramento que limpa credenciais, tokens e rastros da sessão armazenados em memória após a finalização do trabalho.

🛠️ Estrutura do Projeto
Plaintext

hybrid-os/
├── scripts/
│   ├── boot.sh          # Descoberta de rede, validação SSH e montagem do storage
│   ├── setup.sh         # Configuração de dependências, ambiente virtual e VS Code
│   └── cleanup.sh       # Desmontagem de volumes e limpeza segura de dados/credenciais em RAM
├── .gitignore
├── LICENSE
└── README.md

🚀 Como Executar
Pré-requisitos

    Dispositivo Android com Termux e servidor SSH/Rclone configurados.

    Sistema Linux Live-USB rodando com acesso à rede local.

Passo a Passo

    Clonar o repositório:
    Bash

git clone [https://github.com/Santos788/hybrid-os.git](https://github.com/Santos788/hybrid-os.git)
cd hybrid-os

Conceder permissões de execução aos scripts:
Bash

chmod +x scripts/*.sh

Iniciar a ponte e montar o ambiente:
Bash

./scripts/boot.sh

Preparar e carregar o ambiente de desenvolvimento:
Bash

./scripts/setup.sh

Encerrar a sessão com limpeza de credenciais:
Bash

    ./scripts/cleanup.sh

🛡️ Segurança (AppSec & Operacional)

    Sanitização de Sessão: Nenhum dado sensível ou chave de acesso permanece no disco rígido local.

    Ambiente Isolado: Uso de venv (virtualenv) em Python para evitar conflitos com o sistema base e isolar dependências.

    Validação de Identidade SSH: Verificação das assinaturas dos hosts antes de autenticar o volume montado via Rclone.

👨‍💻 Autor

Desenvolvido por Clayton Santos

    LinkedIn: linkedin.com/in/clayton-santos-7888733b0

    GitHub: github.com/Santos788
