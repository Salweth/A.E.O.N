# AEON V2

Refonte du poste agent AEON pour `OpenComputers`.

Cette version repart sur une base plus propre que le prototype documentaire :

- le point d'entree n'est plus une app documents
- toute l'application vit sous `/aeon`
- `/bin/aeon` n'est qu'un stub de lancement
- les apps metier sont separees du shell principal et des services materiels
- le systeme cible est le poste de travail d'un agent, pas un back-office administratif
- les applications doivent etre modulables et installables selon les besoins du poste

## Objectifs V2

- construire un vrai shell principal AEON
- integrer `missions` et `files` comme applications
- definir un systeme d'apps installables
- preparer des services materiels comme les lunettes AR
- rendre l'installation reproductible et desinstallable

## Arborescence de travail

```text
Aeon/
  docs/
  src/
    installer/
    rootfs/
      aeon/
        bin/
        lib/
        apps/
        data/
        config/
        runtime/
        install/
      bin/
```

## Cible OpenComputers

L'installation finale devra produire :

```text
/aeon/...
/bin/aeon
```

Avec les principes suivants :

- pas d'ecriture dispersee a la racine
- code, donnees et configuration sous `/aeon`
- stub minimal dans `/bin` pour lancer l'OS facilement
- seules les apps necessaires doivent etre presentes sur un poste
- les services materiels restent optionnels

## Separation des donnees

AEON distingue deja deux familles de contenu :

- les fichiers locaux du poste agent
- les documents officiels AEON, qui vivront plus tard sur une infrastructure distante

Dans la V2 actuelle, l'app locale `Files` sert d'explorateur du poste et travaille dans `/aeon/data/files`.

## Priorites immediates

1. figer l'architecture V2
2. creer le launcher principal AEON
3. figer le contrat des apps AEON
4. preparer le service `glasses`
5. construire l'installateur et la gestion de version
