<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.it.md">Italiano</a> ·
  <a href="README.es.md">Español</a> ·
  <b>Français</b> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter transporte les sessions Claude Code d'un compte qui a atteint sa limite d'utilisation vers un compte qui a encore de la marge">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 languages" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** est une petite app de barre des menus macOS pour l'onglet **Code** de Claude Desktop. Quand un compte atteint sa limite d'utilisation, Porter transporte vos sessions Claude Code vers un autre compte : vous reprenez les mêmes conversations exactement là où elles s'étaient arrêtées. Il permet aussi de lancer **plusieurs Claude Desktop côte à côte**, un par compte, et garde vos sessions en ordre : archiver, restaurer, supprimer et déplacer des projets entiers.

> [!NOTE]
> Non officiel et sans lien avec Anthropic. Porter lit et écrit les fichiers propres à Claude Desktop, qui ne sont pas documentés et peuvent changer à chaque mise à jour. Il fait une sauvegarde avant chaque modification.

## Plusieurs Claude Desktop en même temps

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="Trois fenêtres Claude Desktop ouvertes en même temps, chacune connectée à un compte différent, toutes listées dans le panneau de Porter">
</p>

Claude Desktop n'utilise normalement qu'un compte à la fois : pour en changer, il faut se déconnecter puis se reconnecter. Avec Porter, plus besoin.

- **Nouveau profil…** ouvre un Claude Desktop distinct, avec sa propre connexion, ses réglages et sa liste de sessions. Connectez-vous-y avec un autre compte et gardez les deux fenêtres ouvertes.
- Créez autant de profils que de comptes (travail, perso, un client…). Ils tournent tous **en même temps**, dans le Dock et avec ⌘-Tab comme n'importe quelle app.
- Porter liste chaque profil avec son compte, sa dernière utilisation connue et les sessions bloquées par une limite. Il l'ouvre ou le met au premier plan, le renomme ou le supprime.
- Déplacer des sessions d'un profil à l'autre se fait en un clic, et quand un compte est épuisé, vous continuez simplement dans la fenêtre suivante.

Vous préférez un seul Claude Desktop et changer de compte en vous déconnectant puis reconnectant ? Désactivez **Plusieurs profils** dans les Options : Porter liste alors des comptes au lieu d'apps et déplace les sessions de l'ancien compte vers celui auquel vous êtes connecté.

## Le panneau de la barre des menus

<img src="assets/readme/panel.svg" width="44%" align="right" alt="Le panneau de Porter dans la barre des menus : cartes de compte avec barres d'utilisation sur 5 heures et 7 jours, un badge pour les sessions bloquées par la limite et un bouton pour les déplacer">

Cliquez sur l'icône du porteur dans la barre des menus pour voir d'un coup d'œil tous vos comptes :

- **Utilisation sur 5 heures et 7 jours** pour chaque compte : vert tant qu'il reste de la marge, orange près de la limite, rouge à la limite. Une valeur enregistrée il y a un moment par Claude Desktop s'affiche estompée avec son ancienneté, et une fenêtre de 5 heures forcément réinitialisée le signale.
- **Sessions bloquées par la limite**, comptées pour chaque compte et signalées par un point sur l'icône de la barre des menus.
- **Déplacer 6 vers Personal →** : un clic déplace les sessions bloquées vers le compte qui a le plus de marge.
- **Sessions ›** ouvre ce compte dans la fenêtre principale.

<br clear="right">

## La fenêtre principale

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="La fenêtre principale de Porter : comptes dans une barre latérale, sessions regroupées par projet, trois sessions sélectionnées et une barre d'actions avec Archiver, Supprimer et Déplacer vers">
</p>

Tous les comptes et leurs sessions Claude Code, au même endroit :

- **Sessions regroupées par projet**, avec des filtres (ouvertes, bloquées par la limite, archivées), un menu des projets et la recherche. Un badge vert signale les sessions actives en ce moment, pour ne pas en déplacer une en pleine réponse.
- **Sélectionnez** d'un clic, avec ⇧-clic pour une plage ou avec *Tout sélectionner*. La barre d'actions apparaît en bas :
  - **Déplacer vers…** : choisissez le compte de destination. Les originaux sont archivés, pour que la même session ne continue pas à deux endroits.
  - **Copier** : les sessions restent dans les deux comptes, et chaque copie a sa propre conversation.
  - **Archiver**, **Restaurer** et **Supprimer…** (vers la Corbeille, vous pouvez donc encore les récupérer).
- **Glissez** des sessions sur un autre compte dans la barre latérale pour les y déplacer.
- **Déplacez le dossier d'un projet** (ou relancez-en le lien après l'avoir déplacé dans le Finder) : Porter met à jour toutes les sessions qui l'utilisent, dans tous les comptes, avec leurs conversations et leurs worktrees git. Les projets dont le dossier a disparu sont signalés *Dossier introuvable*.

## Fonctionnement

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="Schéma : Porter copie un petit fichier de session de la liste de sessions d'un compte vers celle d'un autre ; la conversation reste dans ~/.claude/projects, partagé par tous les comptes ; les chats restent sur les serveurs d'Anthropic">
</p>

Une conversation Claude Code vit dans le dossier propre à Claude Code, `~/.claude/projects`, qui n'appartient à aucun compte. Seule la **liste** des sessions de Claude Desktop appartient à un compte :

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

(le dossier de données par défaut est `~/Library/Application Support/Claude`). Déplacer une session copie ce petit fichier dans la liste de l'autre compte, efface l'erreur « You've hit your limit » et emporte les worktrees git qu'elle utilise. Un Claude Desktop en cours d'exécution garde sa liste en mémoire : Porter le quitte donc d'abord, puis le rouvre ensuite.

> [!IMPORTANT]
> Porter travaille avec ce que Claude Desktop conserve **sur votre Mac** : les sessions de l'onglet **Code**. Les chats, y compris ceux où Claude travaille sur vos fichiers, sont stockés sur les serveurs d'Anthropic et restent liés à leur compte.

## Installation

Nécessite **macOS 14** ou plus récent et [Claude Desktop](https://claude.ai/download).

**Téléchargement :** récupérez `Porter.dmg` dans la [dernière version](../../releases/latest), ouvrez-le et faites glisser **Porter for Claude Desktop** dans `Applications`. L'app n'est pas notarisée, donc macOS la bloque la première fois : ouvrez **Réglages Système → Confidentialité et sécurité** et cliquez sur **Ouvrir quand même**, ou lancez :

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**Compiler depuis les sources** (Xcode ou les Command Line Tools) :

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

Cela compile `dist/Porter for Claude Desktop.app` et le copie dans `~/Applications`. Activez **Ouvrir à la connexion** dans les Options pour garder Porter à portée de main.

Porter parle English, Italiano, Español, Français, Deutsch, Português, 简体中文, 日本語, 한국어 et Русский, selon la langue de votre Mac.

## Ligne de commande

La même app déplace aussi les sessions depuis des scripts :

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # comptes, profils et leurs listes de sessions
"$PORTER" --move --from STORE --to STORE --dry-run      # ce qui se passerait
"$PORTER" --move --from STORE --to STORE --restart      # déplacer (originaux archivés)
"$PORTER" --move --from STORE --to STORE --copy         # copier au lieu de déplacer
```

`STORE` est un chemin affiché par `--list`. Ajoutez `--session local_…` (répétable) pour des sessions précises, `--include-archived` pour inclure aussi les archivées, et `--data-dir PATH` pour un dossier de données Claude que Porter ne connaît pas encore.

Porter ne ferme un Claude Desktop ouvert qu'avec `--restart` (il le rouvre ensuite, et redémarre ou ouvre la destination pour qu'elle charge les sessions) ; sans cette option, un déplacement qui doit fermer une app s'arrête et indique laquelle. `--dry-run` liste les apps qu'il fermerait.

## Bon à savoir

- **Annuler :** chaque modification commence par une sauvegarde dans `~/Library/Application Support/Porter/backups`. Pour annuler un déplacement, quittez Claude Desktop et recopiez les fichiers sauvegardés vers le chemin indiqué dans le `README.txt` de la sauvegarde.
- **Les chiffres d'utilisation** proviennent de ce que Claude Desktop enregistre, ce qu'il fait de temps en temps pendant que vous utilisez un compte. Porter indique l'ancienneté de chaque valeur.
- **Un seul endroit à la fois :** ne continuez pas à travailler sur la même session depuis deux comptes en même temps. C'est pourquoi le déplacement archive l'original ; utilisez Copier quand vous voulez vraiment deux sessions indépendantes.
- N'utilisez que des comptes qui vous appartiennent et respectez les conditions de votre abonnement Claude.

## Soutien

Porter est gratuit et open source. S'il vous évite un peu d'attente, vous pouvez le [soutenir sur GitHub](https://github.com/sponsors/matteogilioli).

## Licence

[MIT](LICENSE). Claude est une marque d'Anthropic, PBC. Porter est un projet indépendant, sans affiliation avec Anthropic ni approbation de sa part.
