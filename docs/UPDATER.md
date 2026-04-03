# AEON Updater

Le fichier [updater.lua](C:\Users\romai\Desktop\Codex\Aeon\src\updater\updater.lua) sert a deployer le contenu de `src/rootfs` vers un poste `OpenComputers`.

## Principe

- le repo GitHub contient tout le projet
- le poste OC ne telecharge que `src/rootfs`
- le script s'appuie sur un manifest de release
- le script cree les dossiers cibles puis telecharge les fichiers dans `/aeon` et `/bin`

## Fichiers

- [updater.lua](C:\Users\romai\Desktop\Codex\Aeon\src\updater\updater.lua)
- [release_manifest.lua](C:\Users\romai\Desktop\Codex\Aeon\src\updater\release_manifest.lua)

## Usage sur OpenComputers

Telecharger le script :

```lua
wget -f https://raw.githubusercontent.com/Salweth/A.E.O.N/main/src/updater/updater.lua /tmp/aeon-updater.lua
```

Lancer la mise a jour :

```lua
lua /tmp/aeon-updater.lua
```

## Options

Changer le repo :

```lua
lua /tmp/aeon-updater.lua --repo Salweth/A.E.O.N
```

Changer la branche :

```lua
lua /tmp/aeon-updater.lua --branch main
```

Changer explicitement l'URL du manifest :

```lua
lua /tmp/aeon-updater.lua --manifest https://raw.githubusercontent.com/Salweth/A.E.O.N/main/src/updater/release_manifest.lua
```

## Resultat attendu

Le script installe :

- `/aeon/...`
- `/bin/aeon`
- `/aeon/config/version.txt`
