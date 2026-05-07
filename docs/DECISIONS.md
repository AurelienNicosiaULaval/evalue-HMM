# Registre des décisions

Ce fichier conserve les décisions méthodologiques importantes afin de rendre le projet traçable.

## Décisions prises

| ID | Date | Décision | Raison |
|---|---|---|---|
| D001 | 2026-05-07 | Le premier article se concentre sur des HMM multi-états simples | Réduire la portée et obtenir une preuve de concept solide |
| D002 | 2026-05-07 | La validité principale sera formulée sur données de validation séparées | Éviter les ambiguïtés liées aux paramètres estimés sur les mêmes données |
| D003 | 2026-05-07 | Les densités prédictives doivent marginaliser les états latents par filtrage | Ne pas traiter les états décodés comme observés |
| D004 | 2026-05-07 | Les données brutes et traitées sont ignorées par défaut dans Git | Réduire le risque de publier des données sensibles |
| D005 | 2026-05-07 | La note de phase 1 formalise d'abord le cas train/test avec modèles fixés avant validation | Obtenir une garantie claire avant d'étendre aux analyses adaptatives ou cross-fitting |
| D006 | 2026-05-07 | La note de phase 1 est rédigée en anglais dans un format proche d'un article | Faciliter la réutilisation directe dans le manuscrit |
| D007 | 2026-05-07 | `predictive_e_diagnostics_hmm_improved.tex` devient l'unique source principale de l'article | Remplacer les anciens brouillons et travailler à partir d'une seule version propre |
| D008 | 2026-05-07 | Le plan R et simulation suit la version améliorée de l'article : mixtures, switching, localisation, features, blockwise et validation par individus | Aligner les simulations sur les garanties théoriques réellement présentes dans le manuscrit |
| D009 | 2026-05-07 | La Phase 2 commence par un HMM simulé avec longueurs Gamma et angles wrapped-normal | Obtenir un noyau R sans dépendances externes avant d'ajouter les diagnostics avancés |
| D010 | 2026-05-07 | Le premier diagnostic full-density implémenté est `K` contre `K+1` avec paramètres fixés | Tester l'interface commune sur un scénario de puissance simple avant d'ajouter des diagnostics plus complexes |
| D011 | 2026-05-07 | Le diagnostic angulaire est d'abord implémenté comme ratio full-density avec structure HMM fixe | Tester la détection d'une mauvaise spécification circulaire avant les diagnostics feature-level |
| D012 | 2026-05-07 | Le diagnostic step-angle est implémenté comme e-process feature-level Rosenblatt avec copule gaussienne | Tester la détection d'une dépendance résiduelle invisible aux marges sans changer le HMM nul |
| D013 | 2026-05-07 | La localisation pondérée est implémentée comme transformation prédictible d'un diagnostic déjà calculé | Réutiliser les diagnostics existants et respecter la garantie `1 + W_t(E_t - 1)` du manuscrit |
| D014 | 2026-05-07 | Le diagnostic de durée est implémenté comme e-value blockwise sur une feature observable de persistance | Éviter de traiter les durées latentes décodées comme observées et suivre la théorie blockwise du manuscrit |

## Décisions ouvertes

| ID | Question | Options actuelles | Statut |
|---|---|---|---|
| O001 | Jeu de données réel | moveHMM, momentuHMM, données publiques Movebank si licence compatible, données de projet si partageables | À décider |
| O002 | Forme du diagnostic longueur-angle | Copule simple, modèle paramétrique conditionnel, alternative non paramétrique contrôlée | À décider |
| O003 | Organisation logicielle | Scripts R, mini-package interne, package R complet | À décider |
| O004 | Revue cible | JABES, Methods in Ecology and Evolution, Biometrics | À décider |
