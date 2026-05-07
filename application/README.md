# Application réelle

Ce dossier contiendra l'analyse empirique du projet, alignée sur l'article `paper/predictive_e_diagnostics_hmm_improved.tex`.

Le jeu de données réel n'est pas encore choisi. Je ne sais pas.

## Principe d'analyse

L'application doit privilégier une validation séparée :

- entraînement et choix des diagnostics sur `train` ;
- calcul des densités prédictives et e-process sur `validation` ;
- validation par individus si plusieurs individus sont disponibles.

Les états latents doivent être intégrés par filtrage dans `log_p0`. Les états décodés peuvent être utilisés pour la description écologique, mais pas pour établir la validité des e-process.

## Scripts prévus

| Script | Rôle |
|---|---|
| `01_preprocess.R` | Importer, documenter et nettoyer les données ; construire longueurs de pas, angles, individus, périodes et covariables prédictibles |
| `02_fit_hmm.R` | Ajuster le HMM nul et les alternatives diagnostiques sur l'ensemble d'entraînement |
| `03_compute_eprocess.R` | Calculer `log_p0`, `log_q`, les e-process globaux, localisés, feature-level et blockwise sur validation |
| `04_figures_application.R` | Produire trajectoires, courbes `log E`, incréments, diagnostics localisés et synthèses par individu |

## Sorties attendues

- Tables dans `results/simulation_tables/` ou un futur dossier `results/application_tables/` si nécessaire.
- Figures dans `results/application_figures/`.
- Interprétation écologique prudente pour la section application.

Les données brutes et traitées sont ignorées par Git par défaut. Ajouter ici seulement des fichiers de documentation ou des données explicitement partageables.
