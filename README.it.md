<p align="center">
  <a href="README.md">English</a> ·
  <b>Italiano</b> ·
  <a href="README.es.md">Español</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter porta le sessioni di Claude Code da un account che ha raggiunto il limite di utilizzo a uno che ha ancora margine">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 languages" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** è una piccola app per la barra dei menu di macOS pensata per la scheda **Code** di Claude Desktop. Quando un account raggiunge il limite di utilizzo, Porter porta le tue sessioni di Claude Code su un altro account, così riprendi le stesse conversazioni da dove si erano fermate. Ti permette anche di usare **più Claude Desktop affiancati**, uno per account, e tiene in ordine le sessioni: archivia, ripristina, elimina e sposta interi progetti.

> [!NOTE]
> Non ufficiale e non affiliata ad Anthropic. Porter legge e scrive i file di Claude Desktop, che non sono documentati e possono cambiare a ogni aggiornamento. Prima di ogni modifica crea un backup.

## Più Claude Desktop contemporaneamente

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="Tre finestre di Claude Desktop aperte insieme, ciascuna con un account diverso, tutte elencate nel pannello di Porter">
</p>

Di solito Claude Desktop usa un account alla volta: per cambiarlo devi uscire e rientrare. Con Porter non serve.

- **Nuovo profilo…** apre un Claude Desktop separato, con il suo accesso, le sue impostazioni e il suo elenco di sessioni. Accedi lì con un altro account e tieni aperte entrambe le finestre.
- Crea tutti i profili che ti servono, uno per account (lavoro, personale, un cliente…). Funzionano **tutti insieme**, nel Dock e con ⌘-Tab come qualsiasi app.
- Porter elenca ogni profilo con il suo account, l'ultimo utilizzo registrato e le sessioni ferme per un limite. Puoi aprirlo o portarlo in primo piano, rinominarlo o rimuoverlo.
- Spostare le sessioni da un profilo all'altro richiede un clic, e quando un account si esaurisce continui a lavorare nella finestra successiva.
- **Apri i link nel profilo giusto** (nelle opzioni): tutti i profili sono la stessa app Claude, quindi dopo l'accesso nel browser macOS può rimandarti a uno qualsiasi di quelli aperti. Con questa opzione Porter passa i link di Claude al profilo che hai usato per ultimo.

Preferisci un solo Claude Desktop e cambiare account uscendo e rientrando? Disattiva **Più profili** nelle Opzioni: Porter elencherà gli account invece delle app e sposterà le sessioni del vecchio account su quello con cui hai fatto l'accesso.

## Il pannello nella barra dei menu

<img src="assets/readme/panel.svg" width="44%" align="right" alt="Il pannello di Porter nella barra dei menu: schede degli account con le barre di utilizzo a 5 ore e 7 giorni, un badge per le sessioni ferme per il limite e un pulsante per spostarle">

Clicca sull'icona del facchino nella barra dei menu per avere un colpo d'occhio su tutti gli account:

- **Utilizzo a 5 ore e 7 giorni** per ogni account: verde finché c'è margine, arancione vicino al limite, rosso al limite. Un valore registrato da Claude Desktop un po' di tempo fa appare sbiadito con la sua età, e una finestra di 5 ore sicuramente azzerata lo segnala.
- **Sessioni ferme per il limite**, contate per ogni account e con un puntino sull'icona nella barra dei menu.
- **Sposta 6 in Personal →**: un clic sposta le sessioni ferme sull'account con più margine.
- **Sessioni ›** apre quell'account nella finestra principale.

<br clear="right">

## La finestra principale

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="La finestra principale di Porter: account nella barra laterale, sessioni raggruppate per progetto, tre sessioni selezionate e una barra delle azioni con Archivia, Elimina e Sposta in">
</p>

Tutti gli account e le loro sessioni di Claude Code, in un unico posto:

- **Sessioni raggruppate per progetto**, con filtri (aperte, ferme per il limite, archiviate), un menu dei progetti e la ricerca. Un badge verde indica le sessioni attive in questo momento, così non ne sposti una a metà risposta.
- **Seleziona** con un clic, con ⇧-clic per un intervallo o con *Seleziona tutte*. In basso compare la barra delle azioni:
  - **Sposta in…**: scegli l'account di destinazione. Gli originali vengono archiviati, così la stessa sessione non prosegue in due posti.
  - **Copia**: le sessioni restano in entrambi gli account e ogni copia ha una conversazione tutta sua.
  - **Archivia**, **Ripristina** ed **Elimina…** (nel Cestino, quindi puoi ancora recuperarle).
- **Trascina** le sessioni su un altro account nella barra laterale per spostarle lì.
- **Sposta la cartella di un progetto** (o ricollegala dopo averla spostata nel Finder): Porter aggiorna ogni sessione che la usa, in ogni account, insieme alle sue conversazioni e ai worktree git. I progetti la cui cartella non esiste più sono segnalati come *Cartella mancante*.

## Come funziona

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="Diagramma: Porter copia un piccolo file di sessione dall'elenco sessioni di un account a quello di un altro; la conversazione resta in ~/.claude/projects, condivisa da tutti gli account; le chat restano sui server di Anthropic">
</p>

Una conversazione di Claude Code vive nella cartella di Claude Code, `~/.claude/projects`, che non appartiene a nessun account. A un account appartiene solo l'**elenco** delle sessioni di Claude Desktop:

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

(la cartella dati predefinita è `~/Library/Application Support/Claude`). Spostare una sessione significa copiare quel piccolo file nell'elenco dell'altro account, cancellare l'errore «You've hit your limit» e portare con sé i worktree git che usa. Un Claude Desktop in esecuzione tiene l'elenco in memoria, quindi Porter lo chiude prima e lo riapre dopo.

> [!IMPORTANT]
> Porter lavora con ciò che Claude Desktop conserva **sul tuo Mac**: le sessioni della scheda **Code**. Le chat, comprese quelle in cui Claude lavora sui tuoi file, sono salvate sui server di Anthropic e restano legate al loro account.

## Installazione

Richiede **macOS 14** o successivo e [Claude Desktop](https://claude.ai/download).

**Download:** scarica `Porter.dmg` dall'[ultima release](../../releases/latest), aprilo e trascina **Porter for Claude Desktop** in `Applications`. L'app non è notarizzata, quindi la prima volta macOS la blocca: apri **Impostazioni di Sistema → Privacy e sicurezza** e fai clic su **Apri comunque**, oppure esegui:

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**Compilazione dai sorgenti** (Xcode o Command Line Tools):

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

Questo compila `dist/Porter for Claude Desktop.app` e lo copia in `~/Applications`. Attiva **Apri al login** nelle Opzioni per averlo sempre a portata di mano.

Porter parla English, Italiano, Español, Français, Deutsch, Português, 简体中文, 日本語, 한국어 e Русский, seguendo la lingua del tuo Mac.

## Riga di comando

La stessa app sposta le sessioni anche dagli script:

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # account, profili e relativi elenchi di sessioni
"$PORTER" --move --from STORE --to STORE --dry-run      # cosa succederebbe
"$PORTER" --move --from STORE --to STORE --restart      # sposta (originali archiviati)
"$PORTER" --move --from STORE --to STORE --copy         # copia invece di spostare
```

`STORE` è un percorso stampato da `--list`. Aggiungi `--session local_…` (ripetibile) per sessioni specifiche, `--include-archived` per includere anche quelle archiviate e `--data-dir PATH` per una cartella dati di Claude che Porter non conosce ancora.

Porter chiude un Claude Desktop aperto solo con `--restart` (poi lo riapre, e riavvia o apre la destinazione perché carichi le sessioni); senza, uno spostamento che richiede di chiudere un'app si ferma e dice quale. `--dry-run` elenca le app che chiuderebbe.

## Da sapere

- **Annullare:** ogni modifica inizia con un backup in `~/Library/Application Support/Porter/backups`. Per annullare uno spostamento, chiudi Claude Desktop e copia i file salvati nel percorso indicato nel `README.txt` del backup.
- **I dati di utilizzo** vengono da ciò che Claude Desktop registra, cosa che fa di tanto in tanto mentre usi un account. Porter mostra quanto è vecchio ogni valore. Con **Utilizzo in tempo reale** attivo (nelle opzioni), Porter chiede invece i dati a claude.ai ogni pochi minuti, con la sessione di ogni profilo, e mostra anche quando si azzera ogni limite e i limiti di un singolo modello, come Fable. macOS chiede una volta di permettere a Porter di usare la chiave che Claude tiene nel Portachiavi.
- **Un posto alla volta:** non continuare a lavorare sulla stessa sessione da due account insieme. Per questo lo spostamento archivia l'originale; usa Copia quando vuoi davvero due sessioni indipendenti.
- Usa solo account di tua proprietà e rispetta i termini del tuo piano Claude.

## Supporto

Porter è gratuito e open source. Se ti fa risparmiare un po' di attesa, puoi [sostenerlo su GitHub](https://github.com/sponsors/matteogilioli).

## Licenza

[MIT](LICENSE). Claude è un marchio di Anthropic, PBC. Porter è un progetto indipendente e non è affiliato né approvato da Anthropic.
