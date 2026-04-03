# Architecture AEON V2

## Vision

AEON n'est pas une application documentaire.
AEON n'est pas non plus un poste d'administration globale.
AEON est le poste de travail modulaire d'un agent sur `OpenComputers`.

Le systeme est organise autour de quatre couches :

- shell principal
- applications metier
- services communs
- peripheriques et integrations

Le principe directeur est le suivant :

- le shell orchestre
- les apps expriment leurs besoins
- les services executent

Le shell ne doit jamais acceder directement au stockage, a la configuration, aux logs ou au materiel.
Toute interaction de ce type doit passer par un service dedie.

## Racine cible sur OpenComputers

```text
/aeon
```

Contenu attendu :

```text
/aeon/bin
/aeon/lib
/aeon/apps
/aeon/data
/aeon/config
/aeon/runtime
/aeon/install
```

Et un seul point d'entree externe :

```text
/bin/aeon
```

## Couches

### 1. Shell principal

Responsabilites :

- session agent
- accueil et navigation
- lancement des apps
- statut machine
- orchestration des services communs

Le shell n'est pas autorise a :

- lire ou ecrire directement les fichiers de configuration
- ecrire des logs lui-meme
- parler directement aux peripheriques
- implementer de logique metier propre a une app

Exemples de modules :

- `/aeon/bin/aeon.lua`
- `/aeon/lib/core/router.lua`
- `/aeon/lib/core/session.lua`
- `/aeon/lib/ui/*.lua`

### 2. Applications metier

Applications prevues en priorite :

- `missions`
- `documents`

Chaque app doit etre autonome, lancable depuis le shell, et ne pas porter la responsabilite du systeme principal.
Les apps sont modulables : un poste peut embarquer seulement les apps utiles a son role et a son equipement.

Exemples :

- une app `glasses-config` peut exister sans etre installee partout
- un poste sans lunettes AR ne doit pas embarquer cette app par defaut
- les apps par defaut restent limitees aux besoins communs des agents

## Contrat minimal d'une app

Chaque app AEON doit respecter ce contrat :

- une app possede un manifest
- une app expose un point d'entree
- une app recoit un contexte systeme
- une app ne parle ni au materiel ni au stockage brut sans passer par un service

Structure cible suggeree :

```text
/aeon/apps/<appId>/
  manifest.lua
  main.lua
```

Manifest minimal attendu :

- `id`
- `name`
- `version`
- `entry`
- `category`
- `requires`
- `optionalDevices`

Contexte systeme minimal attendu :

- `session`
- `services`
- `runtime`
- `ui`
- `logger`

Le router du shell ne lance pas une app ad hoc.
Il charge son manifest, construit un contexte systeme, puis execute son point d'entree.

### 3. Services communs

Responsabilites :

- stockage local
- identite machine
- logs
- configuration
- registre des apps installees
- backend futur pour synchronisation reseau

Un service peut etre obligatoire ou optionnel.
Un service optionnel doit echouer proprement et annoncer son indisponibilite sans casser le shell.

### 4. Peripheriques

Responsabilites :

- imprimante
- scanner
- lunettes AR
- tablettes

Les peripheriques doivent etre des integrations optionnelles. L'OS doit fonctionner meme s'ils sont absents.
Les apps doivent verifier la disponibilite via les services, pas en interrogeant directement le materiel.

## Runtime

Le dossier `/aeon/runtime` existe pour l'etat temporaire et recreable.
Il ne doit pas devenir un stockage durable deguisé.

Y vivent uniquement :

- etat de session courant
- cache temporaire
- verrous
- files de notifications temporaires
- traces de runtime recreables

N'y vivent pas :

- configuration persistante
- donnees metier
- archives
- etats critiques impossibles a reconstruire

## Positionnement des lunettes AR

Les lunettes AR ne remplacent pas l'interface principale.
Elles servent d'extension terrain.

Usages cibles :

- affichage d'objectifs de mission
- waypoints et marqueurs 3D
- notifications critiques
- interaction rapide avec des overlays
- identification contextuelle d'entites ou de lieux

## Installation

L'installation devra :

- creer `/aeon`
- copier l'arborescence necessaire
- ecrire un stub `/bin/aeon`
- verifier les dependances critiques
- initialiser la configuration locale
- enregistrer une version d'installation
- permettre des migrations ulterieures

Exemples de fichiers de suivi :

- `/aeon/config/version.lua`
- `/aeon/install/install-state.lua`

## Contraintes de design

- pas de dependance structurelle a `/home`
- pas de logique metier dans le stub `/bin/aeon`
- pas d'app qui se comporte comme shell principal
- compatibilite avec des machines partielles ou degradees
- aucune app ni shell ne contourne les services communs
