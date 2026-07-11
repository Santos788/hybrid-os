# HybridOS

Um jeito de transformar qualquer notebook velho (ou um Live USB do Linux Mint) numa estação de trabalho completa, usando o seu celular Android como "HD externo" via Wi-Fi.

## A ideia por trás disso

Se você já tentou programar a partir de um Live USB, sabe o problema: tudo roda na RAM, e no segundo em que você desliga o notebook, seus arquivos, extensões e configurações somem junto.

O HybridOS resolve isso de um jeito meio inusitado: em vez de depender de um disco local, ele conecta o notebook ao seu celular Android (rodando Termux) via SSH/SFTP, e usa o `rclone` pra montar essa conexão como se fosse uma pasta normal do sistema. Na prática, você tem um notebook descartável e voador — reinicia, monta de novo, e seus arquivos continuam exatamente onde estavam, guardados no bolso.

É uma solução para um cenário bem específico: notebooks emprestados, laboratórios de faculdade, máquinas que você não confia o suficiente pra instalar um SO nelas, ou simplesmente a vontade de nunca mais perder um projeto por causa de um Live USB reiniciado sem querer.

## Como funciona, por trás dos panos

```
┌─────────────────────┐         SSH / SFTP          ┌──────────────────┐
│   Notebook (RAM)     │ ───────────────────────────▶│  Celular (Termux) │
│   Linux Mint Live     │  ◀───────────────────────── │  Armazenamento    │
│   + rclone mount      │        porta 8022           │  persistente      │
└─────────────────────┘                              └──────────────────┘
```

O celular guarda os arquivos de verdade. O notebook só monta essa pasta remotamente e trabalha nela como se fosse local — com cache do `rclone` garantindo que a experiência não fique lenta demais mesmo numa rede doméstica comum.

## O que você precisa antes de começar

- Um notebook rodando **Linux Mint em modo Live** (USB ou CD)
- Um celular Android com o **Termux** instalado, com o servidor SSH ativo (`sshd`) na porta 8022
- Ambos os dispositivos na **mesma rede Wi-Fi**
- No Termux, ter rodado **`termux-setup-storage`** pelo menos uma vez (isso cria o link de acesso ao armazenamento real do celular — sem isso, o notebook vai conseguir se conectar, mas vai ver uma pasta vazia, o que costuma confundir bastante gente na primeira tentativa)
- Uma chave SSH e um `rclone.conf` já preparados na pasta `hybrid-os` do armazenamento do celular (veja a seção de configuração inicial abaixo)

## Os três scripts

| Script | O que ele faz |
|---|---|
| `preparar_e_rodar.sh` | O ponto de partida. Instala as dependências no notebook, procura o celular na rede, autentica com ele e busca as credenciais necessárias. No fim, chama o `dar_boot.sh` automaticamente. |
| `dar_boot.sh` | O menu principal. Monta o armazenamento do celular (e o Google Drive, se configurado), e opcionalmente já abre o VS Code direto na pasta do projeto. Também tem a opção de desmontar tudo com segurança, salvando suas extensões antes. |
| `limpar_tudo.sh` | O botão de pânico. Desmonta tudo, mata os processos relacionados e limpa qualquer credencial que tenha ficado na RAM do notebook — importante rodar antes de desligar, principalmente se o notebook não é seu. |

## Colocando pra rodar

No notebook (Live USB do Linux Mint), abra um terminal e rode:

```bash
curl -sL https://raw.githubusercontent.com/Santos788/hybrid-os/main/preparar_e_rodar.sh | bash
```

O script vai:
1. Ajustar as configurações de FUSE necessárias para o `rclone`
2. Instalar `rclone`, `sshfs` e `nmap` se ainda não estiverem presentes
3. Procurar automaticamente o celular na rede local (e pedir o IP manualmente se não achar)
4. Confirmar a identidade do celular com você antes de confiar nele — na primeira vez ele mostra a "impressão digital" da conexão e pede sua confirmação; nas próximas vezes, se essa impressão mudar, ele avisa e para, em vez de conectar sem perguntar
5. Buscar a chave SSH e o `rclone.conf` do celular
6. Abrir o menu do `dar_boot.sh`

A partir daí, é só escolher a opção que faz sentido pro seu momento: montar tudo e abrir o VS Code, montar só o armazenamento, ou desmontar com segurança.

Quando terminar de usar o notebook:

```bash
bash limpar_tudo.sh
```

## Configuração inicial no celular (uma vez só)

Antes da primeira vez que você usar o HybridOS, o celular precisa estar preparado:

```bash
# Dentro do Termux
pkg install openssh
sshd
termux-setup-storage

mkdir -p ~/storage/shared/hybrid-os
cd ~/storage/shared/hybrid-os
```

Gere um par de chaves para o notebook confiar no celular (ou copie uma chave já existente do notebook para cá como `id_rsa_backup`), e adicione a chave pública correspondente ao `~/.ssh/authorized_keys` do Termux. Prepare também o seu `rclone.conf` (com a configuração do Google Drive, se for usar) e coloque ele nessa mesma pasta.

Depois disso, o `preparar_e_rodar.sh` cuida do resto sozinho, toda vez que você usar um notebook novo.

## Sobre segurança

Vale ser honesto aqui: esse projeto foi pensado pra uso pessoal, numa rede doméstica em que você confia. Ele conecta um notebook desconhecido (Live USB) ao seu celular via SSH, e isso tem implicações que valem a pena entender antes de usar em qualquer lugar:

- A verificação de identidade do celular protege contra ataques de rede (como alguém se passando pelo seu celular), mas só funciona se você conferir a impressão digital na primeira conexão em vez de simplesmente aceitar
- As credenciais (chave SSH, configuração do rclone) ficam apenas na RAM do notebook e são removidas pelo `limpar_tudo.sh` — mas isso só acontece se você lembrar de rodar esse script antes de desligar
- Evite usar em redes públicas ou não confiáveis (Wi-Fi de aeroporto, cafeteria, etc.) — o tráfego SSH/SFTP é criptografado, mas a superfície de ataque de expor um servidor SSH na rede local ainda existe

Se for usar em notebooks que não são seus (laboratório, biblioteca), rode o `limpar_tudo.sh` religiosamente ao terminar.

## Problemas comuns

**"Montou, mas a pasta está vazia"** — quase sempre significa que o `termux-setup-storage` não foi rodado no celular (ou a permissão de armazenamento não foi concedida). Rode o comando no Termux e tente montar de novo.

**"Não consegui detectar o celular automaticamente"** — normal em redes com isolamento de dispositivos (algumas redes de trabalho ou Wi-Fi de operadora bloqueiam isso). Quando o script pedir, digite o IP do celular manualmente — você pode encontrá-lo em Configurações > Wi-Fi > detalhes da rede conectada, no Android.

**"A identidade do celular mudou desde a última vez"** — o script vai parar de propósito. Se você trocou de celular ou reinstalou o Termux, apague o arquivo `~/.ssh/known_hosts_hybridos` no notebook e conecte de novo. Se não fez nada disso, desconfie da rede em que você está.

## Contribuindo

Encontrou um bug, tem uma ideia de melhoria, ou quer adaptar isso pra outro cenário (iOS, outro gerenciador de arquivos remoto, etc.)? Abra uma issue ou mande um pull request. É um projeto pequeno e pessoal, mas toda contribuição ajuda.

## Licença

Adicione aqui a licença de sua preferência (MIT costuma ser uma boa escolha padrão para projetos assim).
