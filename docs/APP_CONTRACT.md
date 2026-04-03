# AEON App Contract

## But

Definir un format unique pour les applications AEON.
Le but est d'eviter que chaque app invente sa propre convention de lancement.

## Principes

- une app est un module installable
- une app n'est pas le shell
- une app declare ce qu'elle est et ce dont elle a besoin
- une app recoit un contexte systeme fourni par AEON
- une app ne contourne jamais les services communs

## Arborescence cible

```text
/aeon/apps/<appId>/
  manifest.lua
  main.lua
```

## Manifest

Le fichier `manifest.lua` doit retourner une table.

Champs minimaux :

- `id`
- `name`
- `version`
- `entry`
- `category`

Champs recommandes :

- `description`
- `requires`
- `optionalDevices`
- `defaultInstalled`
- `launcher`

Exemple :

```lua
return {
  id = "missions",
  name = "Missions",
  version = "2.0.0-alpha",
  entry = "/aeon/apps/missions/main.lua",
  category = "operations",
  description = "Mission access for field agents.",
  requires = {"storage", "config"},
  optionalDevices = {"glasses"},
  defaultInstalled = true,
  launcher = {
    label = "Missions",
    order = 10
  }
}
```

## Point d'entree

Le fichier `main.lua` doit retourner soit :

- une table avec `run(context)`
- une fonction unique prenant `context`

## Contexte systeme

Le shell construit et transmet un contexte unique.

Champs minimaux :

- `session`
- `services`
- `runtime`
- `ui`
- `logger`

Exemple d'usage :

```lua
return {
  run = function(context)
    local storage = context.services.storage
    local ui = context.ui
    ui.info("Mission console ready.")
  end
}
```

## Regles d'isolation

Une app ne doit pas :

- lire directement des fichiers de config
- parler directement a un composant materiel
- ecrire dans le runtime d'une autre app
- supposer qu'un peripherique optionnel existe

Une app doit :

- demander ses dependances via `context.services`
- echouer proprement si un service optionnel est absent
- garder ses donnees persistantes dans les emplacements prevus par les services

## Apps par defaut et apps optionnelles

AEON distingue :

- les apps par defaut, presentes sur la plupart des postes agents
- les apps optionnelles, installees selon le role ou l'equipement

Exemples :

- `missions` : par defaut
- `documents` : par defaut
- `glasses-config` : optionnelle

## Installation

Une app installee doit etre enregistree dans le registre des apps.
Le shell ne doit lister que les apps valides disposant d'un manifest et d'un point d'entree exploitables.
