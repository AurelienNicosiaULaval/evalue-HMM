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

## Décisions ouvertes

| ID | Question | Options actuelles | Statut |
|---|---|---|---|
| O001 | Jeu de données réel | moveHMM, momentuHMM, données publiques Movebank si licence compatible, données de projet si partageables | À décider |
| O002 | Forme du diagnostic longueur-angle | Copule simple, modèle paramétrique conditionnel, alternative non paramétrique contrôlée | À décider |
| O003 | Organisation logicielle | Scripts R, mini-package interne, package R complet | À décider |
| O004 | Revue cible | JABES, Methods in Ecology and Evolution, Biometrics | À décider |
