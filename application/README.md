# Application réelle

Ce dossier contiendra l'analyse empirique du projet, alignée sur l'article `paper/predictive_e_diagnostics_hmm_improved.tex`.

Le jeu de données retenu pour la première application est `moveHMM::elk_data`, le jeu de données elk associé à Morales et al. (2004) et distribué avec le package `moveHMM` de Michelot et al. (2016).

Références :

- Morales et al. (2004), Ecology, https://doi.org/10.1890/03-0269
- Michelot et al. (2016), Methods in Ecology and Evolution, https://doi.org/10.1111/2041-210X.12578

## Principe d'analyse

L'application doit privilégier une validation séparée :

- entraînement et choix des diagnostics sur `train` ;
- calcul des densités prédictives et e-process sur `validation` ;
- validation par individus si plusieurs individus sont disponibles.

Les états latents doivent être intégrés par filtrage dans `log_p0`. Les états décodés peuvent être utilisés pour la description écologique, mais pas pour établir la validité des e-process.

## Scripts prévus

| Script | Rôle |
|---|---|
| `01_preprocess.R` | Importer `moveHMM::elk_data`, construire longueurs de pas et angles, documenter le split train/validation |
| `02_fit_hmm.R` | Ajuster les HMM `K = 2, 3, 4` sur les individus d'entraînement et choisir le nul par BIC |
| `03_compute_eprocess.R` | Calculer `log_p0`, les diagnostics `K+1`, angulaire, mixture et localisation par état filtré sur validation |
| `04_figures_application.R` | Produire trajectoires, courbes `log E`, incréments et synthèses visuelles |
| `run_application.R` | Exécuter toute la chaîne d'application dans l'ordre |
| `utils_movehmm_eprocess.R` | Convertir les objets `moveHMM` en densités prédictives observables par filtrage |

## Sorties attendues

- Tables dans `results/application_tables/`.
- Figures dans `results/application_figures/`.
- Interprétation écologique prudente pour la section application.

Les données brutes et traitées sont ignorées par Git par défaut. Ajouter ici seulement des fichiers de documentation ou des données explicitement partageables.

## Commandes

```bash
Rscript application/01_preprocess.R
Rscript application/02_fit_hmm.R
Rscript application/03_compute_eprocess.R
Rscript application/04_figures_application.R
```

Ou toute la chaîne :

```bash
Rscript application/run_application.R
```
