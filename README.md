# Predictive e-diagnostics for multi-state movement models

Ce dépôt privé structure un projet de recherche sur les e-values et les e-process prédictifs pour le diagnostic de modèles multi-états de mouvement animalier, en particulier les HMM.

## Objectif

Développer un cadre théorique, computationnel et appliqué pour évaluer des HMM de mouvement comme générateurs séquentiels, en utilisant des densités prédictives observables et des diagnostics ciblés.

## État actuel

- Le plan initial est conservé dans `plan_travail_predictive_e_diagnostics_hmm.md`.
- Le plan opérationnel du projet est dans `PLAN_DE_TRAVAIL.md`.
- Le plan de travail par phase est dans `docs/PLAN_PAR_PHASE.md`.
- The current and only article source is in `paper/predictive_e_diagnostics_hmm_improved.tex`.
- Le noyau R minimal de Phase 2 inclut simulation, filtrage, densités prédictives, e-process et estimation oracle pour les scénarios contrôlés.
- La Phase 3 est amorcée avec les diagnostics `K+1`, angulaire, step-angle feature-level, localisation pondérée, durée blockwise, mixture et switching prédictible.
- Le scénario S2 compare paramètres connus, paramètres estimés sur train et validation sous générateur ajusté. L'estimation actuelle utilise les états simulés et n'est pas encore un ajusteur HMM général.
- Le scénario S9 démontre pourquoi le produit parallèle naïf n'est pas utilisé comme procédure valide.
- Le dépôt contient une arborescence de travail pour la théorie, le code R, les simulations, l'application réelle, les figures et le manuscrit.
- Le jeu de données réel n'est pas encore choisi. Je ne sais pas.

## Structure du dépôt

```text
.
├── README.md
├── PLAN_DE_TRAVAIL.md
├── plan_travail_predictive_e_diagnostics_hmm.md
├── R/
├── simulations/
├── application/
│   ├── data_raw/
│   └── data_processed/
├── results/
│   ├── simulation_tables/
│   ├── simulation_figures/
│   └── application_figures/
├── paper/
│   ├── predictive_e_diagnostics_hmm_improved.tex
│   └── figures/
├── manuscript_outputs/
└── docs/
    ├── PLAN_PAR_PHASE.md
    ├── BIBLIOGRAPHIE_DE_DEPART.md
    └── DECISIONS.md
```

## Démarrage local

```bash
git clone git@github.com:AurelienNicosiaULaval/evalue-HMM.git
cd evalue-HMM
```

Les fonctions R de base peuvent être chargées ainsi :

```r
source("R/eprocess.R")
source("R/hmm_forward_filter.R")
source("R/predictive_density_hmm.R")
source("R/simulate_hmm_movement.R")
source("R/estimate_hmm_training.R")
source("R/diagnostic_interface.R")
source("R/diagnostics_states.R")
source("R/diagnostics_angles.R")
source("R/diagnostics_copula.R")
source("R/diagnostics_localization.R")
source("R/diagnostics_duration.R")
source("R/diagnostics_combination.R")
```

Exemple minimal pour l'e-process :

```r
log_p0 <- dnorm(c(-0.2, 0.1, 0.5), mean = 0, sd = 1, log = TRUE)
log_p1 <- dnorm(c(-0.2, 0.1, 0.5), mean = 0.3, sd = 1, log = TRUE)
compute_eprocess(log_p0 = log_p0, log_p1 = log_p1, alpha = 0.05)
```

Pour lancer la première simulation de calibration :

```bash
Rscript simulations/01_null_fixed_generator.R
```

Pour lancer le scénario train/validation avec estimation contrôlée :

```bash
Rscript simulations/02_train_validation_estimated.R
```

Pour lancer le premier diagnostic `K` contre `K+1` :

```bash
Rscript simulations/03_underfit_states.R
```

Pour lancer le diagnostic angulaire :

```bash
Rscript simulations/04_angle_misspecification.R
```

Pour lancer le diagnostic feature-level de dépendance step-angle :

```bash
Rscript simulations/05_step_angle_dependence.R
```

Pour lancer le diagnostic blockwise de durée :

```bash
Rscript simulations/06_duration_or_blockwise.R
```

Pour lancer le scénario de localisation pondérée :

```bash
Rscript simulations/07_localized_failure.R
```

Pour lancer les mixtures et switching prédictibles :

```bash
Rscript simulations/08_mixture_switching.R
```

Pour lancer la démonstration négative du produit parallèle naïf :

```bash
Rscript simulations/09_parallel_product_warning.R
```

## Données

Les dossiers `application/data_raw/` et `application/data_processed/` sont ignorés par Git, sauf leurs fichiers de documentation. Cette règle évite de publier accidentellement des données sensibles, même dans un dépôt privé.

## Références

La version actuelle de l'article contient sa bibliographie directement dans le fichier LaTeX. Le fichier `docs/BIBLIOGRAPHIE_DE_DEPART.md` reste une note de travail historique.
