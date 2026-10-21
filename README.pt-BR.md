<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.it.md">Italiano</a> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <b>Português</b> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="O Porter leva sessões do Claude Code de uma conta que atingiu o limite de uso para outra com espaço sobrando">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 idiomas" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="Licença MIT" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

O **Porter** é um pequeno app de barra de menus do macOS para a aba **Code** do Claude Desktop. Quando uma conta atinge o limite de uso, o Porter leva suas sessões do Claude Code para outra conta, e você retoma as mesmas conversas exatamente de onde pararam. Ele também permite rodar **vários Claude Desktops lado a lado**, um por conta, e mantém suas sessões em ordem: arquivar, restaurar, apagar e mover projetos inteiros.

> [!NOTE]
> Não oficial e sem vínculo com a Anthropic. O Porter lê e grava os arquivos do próprio Claude Desktop, que não são documentados e podem mudar a qualquer atualização. Ele faz um backup antes de cada alteração.

## Vários Claude Desktops ao mesmo tempo

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="Três janelas do Claude Desktop abertas ao mesmo tempo, cada uma com uma conta diferente, todas listadas no painel do Porter">
</p>

O Claude Desktop normalmente roda uma conta por vez: para usar outra, você sai e entra de novo. Com o Porter, não precisa.

- **Novo perfil…** abre um Claude Desktop separado, com login, ajustes e lista de sessões próprios. Entre ali com outra conta e deixe as duas janelas abertas.
- Crie quantos perfis tiver de contas (trabalho, pessoal, um cliente…). Todos rodam **ao mesmo tempo**, no Dock e com ⌘-Tab como qualquer app.
- O Porter lista cada perfil com sua conta, o último uso registrado e as sessões paradas por um limite. Ele abre ou traz cada um para a frente, renomeia ou remove.
- Mover sessões entre perfis é um clique, e quando uma conta acaba você simplesmente continua na próxima janela.
- **Abrir links no perfil certo** (nas opções): todos os perfis são o mesmo app Claude, então depois de entrar pelo navegador o macOS pode mandar você de volta a qualquer um dos abertos. Com esta opção, o Porter passa os links do Claude ao perfil que você usou por último.

Prefere um só Claude Desktop e trocar de conta saindo e entrando? Desative **Vários perfis** nas opções: o Porter passa a listar contas em vez de apps e move as sessões da conta antiga para a conta em que você está logado.

## O painel da barra de menus

<img src="assets/readme/panel.svg" width="44%" align="right" alt="O painel do Porter na barra de menus: cartões de contas com barras de uso de 5 horas e 7 dias, um selo de sessões paradas pelo limite e um botão para movê-las">

Clique no porteiro na barra de menus para ver todas as contas de relance:

- **Uso de 5 horas e 7 dias** de cada conta: verde enquanto há folga, laranja perto do limite, vermelho quando chegou nele. Um valor que o Claude Desktop registrou há algum tempo aparece esmaecido com a idade, e uma janela de 5 horas que com certeza já reiniciou é indicada como tal.
- **Sessões paradas pelo limite**, contadas em cada conta e com um ponto no ícone da barra de menus.
- **Mover 6 para Personal →**: um clique move as sessões paradas para a conta com mais espaço sobrando.
- **Sessões ›** abre essa conta na janela principal.

<br clear="right">

## A janela principal

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="A janela principal do Porter: contas em uma barra lateral, sessões agrupadas por projeto, três sessões selecionadas e uma barra de ações com Arquivar, Apagar e Mover para">
</p>

Todas as contas e suas sessões do Claude Code em um só lugar:

- **Sessões agrupadas por projeto**, com filtros (abertas, paradas pelo limite, arquivadas), um menu de projetos e busca. Um selo verde marca as sessões ativas neste momento, para você não mover uma no meio de uma resposta.
- **Selecione** com um clique, ⇧-clique para um intervalo ou *Selecionar todas*. A barra de ações aparece na parte de baixo:
  - **Mover para…**: escolha a conta de destino. Os originais são arquivados, para que a mesma sessão não seja continuada em dois lugares.
  - **Copiar**: as sessões ficam nas duas contas, e cada cópia ganha uma conversa própria.
  - **Arquivar**, **Restaurar** e **Apagar…** (vão para a Lixeira, então ainda dá para recuperar).
- **Arraste** sessões para outra conta na barra lateral para movê-las para lá.
- **Mover a pasta de um projeto** (ou revinculá-la depois de movê-la no Finder): o Porter atualiza todas as sessões que a usam, em todas as contas, junto com as conversas e os git worktrees. Projetos cuja pasta sumiu ficam marcados com *Pasta não encontrada*.

## Como funciona

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="Diagrama: o Porter copia um pequeno arquivo de sessão da lista de sessões de uma conta para a de outra; a conversa permanece em ~/.claude/projects, compartilhada por todas as contas; os chats ficam nos servidores da Anthropic">
</p>

Uma conversa do Claude Code fica na pasta do próprio Claude Code, `~/.claude/projects`, que não pertence a nenhuma conta. O que pertence a uma conta é apenas a **lista** de sessões do Claude Desktop:

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

(a pasta de dados padrão é `~/Library/Application Support/Claude`). Mover uma sessão copia esse pequeno arquivo para a lista da outra conta, limpa o erro "You've hit your limit" e leva junto os git worktrees que ela usa. Um Claude Desktop em execução mantém a lista na memória, por isso o Porter o encerra antes e o reabre depois.

> [!IMPORTANT]
> O Porter trabalha com o que o Claude Desktop guarda **no seu Mac**: sessões da aba **Code**. Os chats, inclusive aqueles em que o Claude trabalha nos seus arquivos, ficam nos servidores da Anthropic e continuam com a conta deles.

## Instalação

Requer **macOS 14** ou superior e o [Claude Desktop](https://claude.ai/download).

**Download:** baixe o `Porter.dmg` da [versão mais recente](../../releases/latest), abra-o e arraste o **Porter for Claude Desktop** para `Applications`. O app não é notarizado, então o macOS o bloqueia na primeira vez: abra **Ajustes do Sistema → Privacidade e Segurança** e clique em **Abrir Mesmo Assim**, ou execute:

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**Compilar a partir do código-fonte** (Xcode ou as Command Line Tools):

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

Isso gera `dist/Porter for Claude Desktop.app` e o copia para `~/Applications`. Ative **Abrir ao iniciar sessão** nas opções para manter o Porter sempre à mão.

O Porter fala English, Italiano, Español, Français, Deutsch, Português, 简体中文, 日本語, 한국어 e Русский, seguindo o idioma do seu Mac.

## Linha de comando

O mesmo app move sessões a partir de scripts:

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # contas, perfis e suas listas de sessões
"$PORTER" --move --from STORE --to STORE --dry-run      # o que aconteceria
"$PORTER" --move --from STORE --to STORE --restart      # mover (originais arquivados)
"$PORTER" --move --from STORE --to STORE --copy         # copiar em vez disso
```

`STORE` é um caminho exibido por `--list`. Adicione `--session local_…` (repetível) para sessões específicas, `--include-archived` para incluir também as arquivadas e `--data-dir PATH` para uma pasta de dados do Claude que o Porter ainda não conhece.

O Porter só fecha um Claude Desktop aberto com `--restart` (depois o reabre, e reinicia ou abre o destino para carregar as sessões); sem ele, uma movimentação que precisa fechar um app para e diz qual. `--dry-run` lista os apps que ele fecharia.

## Bom saber

- **Desfazer:** toda alteração começa com um backup em `~/Library/Application Support/Porter/backups`. Para desfazer uma movimentação, encerre o Claude Desktop e copie os arquivos salvos de volta para o caminho indicado no `README.txt` do backup.
- **Os números de uso** vêm do que o Claude Desktop registra, o que ele faz de vez em quando enquanto você usa uma conta. O Porter mostra a idade de cada valor. Com **Uso em tempo real** ativado (nas opções), o Porter pede os dados ao claude.ai a cada poucos minutos, com a sessão de cada perfil, e mostra também quando cada limite reinicia e os limites de um único modelo, como o Fable. O macOS pede uma vez para o Porter usar a chave que o Claude guarda nas Chaves.
- **Um lugar por vez:** não continue trabalhando na mesma sessão a partir de duas contas ao mesmo tempo. Por isso mover arquiva o original; use Copiar quando realmente quiser duas sessões independentes.
- Use apenas contas que sejam suas e siga os termos do seu plano do Claude.

## Apoio

O Porter é gratuito e de código aberto. Se ele poupa um pouco da sua espera, você pode [apoiá-lo no GitHub](https://github.com/sponsors/matteogilioli).

## Licença

[MIT](LICENSE). Claude é uma marca da Anthropic, PBC. O Porter é um projeto independente e não é afiliado nem endossado pela Anthropic.
