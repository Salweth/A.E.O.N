# Files App

## Role

`Files` est l'explorateur local du poste AEON.
Il ne represente pas les documents officiels AEON.

## Portee

L'application travaille uniquement dans :

```text
/aeon/data/files
```

Sous-dossiers prepares par defaut :

- `/aeon/data/files/downloads`
- `/aeon/data/files/notes`
- `/aeon/data/files/tmp`

## Fonctions V1/V2

- explorer les dossiers locaux
- entrer dans un dossier
- revenir au parent
- creer un dossier
- creer un fichier texte
- lire un fichier texte
- editer un fichier texte simple
- renommer
- supprimer

## Distinction importante

AEON doit separer deux mondes :

- les fichiers internes d'un poste
- les documents officiels de l'organisation

`Files` couvre uniquement le premier cas.
Les documents officiels devront plus tard passer par un systeme distant dedie.

## Service associe

L'app repose sur :

- `/aeon/lib/aeon/services/filesystem.lua`

Le shell et l'app ne doivent pas manipuler librement des chemins hors de ce service.
