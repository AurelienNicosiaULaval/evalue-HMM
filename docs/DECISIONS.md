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
| D015 | 2026-05-07 | Les combinaisons de diagnostics utilisent une moyenne pondérée d'incréments ou un switching prédictible, jamais un produit parallèle | Respecter la section mixtures/switching du manuscrit et garder le produit naïf pour une démonstration négative séparée |
| D016 | 2026-05-07 | Le produit parallèle naïf est documenté seulement comme contre-exemple de calibration | Montrer empiriquement le gonflement du faux signal sous le HMM nul |
| D017 | 2026-05-07 | Le premier scénario train/validation estimé utilise un estimateur oracle-state sur données simulées | Isoler la logique conditionnelle train/validation avant d'introduire un ajusteur HMM général |
| D018 | 2026-05-07 | La validation par individus utilise une moyenne pondérée des e-values finales comme résumé global par défaut | Suivre la proposition cross-fitted du manuscrit et éviter de transformer un scan multi-individus en garantie globale |
| D019 | 2026-05-07 | Le diagnostic long-horizon utilise la rectitude des blocs avec lois de feature ajustées sur simulations indépendantes | Cibler un défaut de comportement génératif agrégé tout en gardant un diagnostic interprétable pour le manuscrit |
| D020 | 2026-05-07 | L'enveloppe composite est implémentée sur une famille finie de HMM nuls et reste un scénario optionnel | Montrer la validité uniforme et son coût de conservatisme sans surcharger le papier principal |
| D021 | 2026-05-07 | Les scénarios S1, S3, S4, S5, S6, S7 et S8 sont retenus pour l'article principal ; S2, S9, S10, S11 et S12 vont au supplément | Garder une narration principale centrée sur calibration, diagnostics ciblés, localisation et combinaison prédictible, tout en documentant les extensions |
| D022 | 2026-05-07 | La première application réelle utilise `moveHMM::elk_data`, avec `elk-115` comme individu de validation et les autres individus pour l'entraînement | Utiliser un jeu de données public, reproductible, inclus dans un package CRAN et directement compatible avec les HMM longueur-angle |

## Décisions ouvertes

| ID | Question | Options actuelles | Statut |
|---|---|---|---|
| O001 | Jeu de données réel | `moveHMM::elk_data` pour la première application ; autres jeux possibles en sensibilité | Décidé pour la première version |
| O002 | Forme du diagnostic longueur-angle | Copule simple, modèle paramétrique conditionnel, alternative non paramétrique contrôlée | À décider |
| O003 | Organisation logicielle | Scripts R, mini-package interne, package R complet | À décider |
| O004 | Revue cible | JABES, Methods in Ecology and Evolution, Biometrics | À décider |
