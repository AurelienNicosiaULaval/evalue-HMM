# Predictive e-diagnostics for multi-state movement models

Ce dépôt privé structure un projet de recherche sur les e-values et les e-process prédictifs pour le diagnostic de modèles multi-états de mouvement animalier, en particulier les HMM.

## Objectif

Développer un cadre théorique, computationnel et appliqué pour évaluer des HMM de mouvement comme générateurs séquentiels, en utilisant des densités prédictives observables et des diagnostics ciblés.

## État actuel

- Le plan initial est conservé dans `plan_travail_predictive_e_diagnostics_hmm.md`.
- Le plan opérationnel du projet est dans `PLAN_DE_TRAVAIL.md`.
- Le plan de travail par phase est dans `docs/PLAN_PAR_PHASE.md`.
- La version courante et unique de l'article est dans `paper/predictive_e_diagnostics_hmm_improved.tex`.
- Le matériel supplémentaire est dans `paper/supplementary_material.tex`.
- Découpage actuel des simulations : S1, S3, S4, S5, S6, S7 et S8 dans l'article principal ; S2, S9, S10, S11 et S12 dans le supplément.
- Le noyau R minimal de Phase 2 inclut simulation, filtrage, densités prédictives, e-process et estimation oracle pour les scénarios contrôlés.
- La Phase 3 a une première version fonctionnelle avec les diagnostics `K+1`, angulaire, step-angle feature-level, localisation pondérée, durée blockwise, mixture et switching prédictible.
- Le scénario S2 compare paramètres connus, paramètres estimés sur train et validation sous générateur ajusté. L'estimation actuelle utilise les états simulés et n'est pas encore un ajusteur HMM général.
- Le scénario S10 implémente un diagnostic blockwise long-horizon basé sur la rectitude des blocs.
- Le scénario S9 démontre pourquoi le produit parallèle naïf n'est pas utilisé comme procédure valide.
- Le scénario S11 implémente la validation par individus avec moyenne cross-fitted finale et signale le scan multi-individus comme exploratoire.
- Le scénario S12 implémente une enveloppe composite conservatrice sur une famille finie de HMM nuls.
- L'application réelle utilise `moveHMM::elk_data` avec validation sur l'individu `elk-115`; les figures ggplot prêtes pour le manuscrit sont dans `paper/figures/`.
- Le dépôt contient une arborescence de travail pour la théorie, le code R, les simulations, l'application réelle, les figures et le manuscrit.

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
│   ├── supplementary_material.tex
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
source("R/diagnostics_long_horizon.R")
source("R/diagnostics_composite.R")
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

Pour lancer le diagnostic blockwise long-horizon :

```bash
Rscript simulations/10_blockwise_long_horizon.R
```

Pour lancer la validation par individus et moyenne cross-fitted :

```bash
Rscript simulations/11_individual_validation_crossfit.R
```

Pour lancer l'enveloppe composite conservatrice :

```bash
Rscript simulations/12_composite_envelope_optional.R
```

Pour lancer l'application réelle :

```bash
Rscript application/run_application.R
```

## Données

Les dossiers `application/data_raw/` et `application/data_processed/` sont ignorés par Git, sauf leurs fichiers de documentation. Cette règle évite de publier accidentellement des données sensibles, même dans un dépôt privé.

## Références

La version actuelle de l'article contient sa bibliographie directement dans le fichier LaTeX. Le fichier `docs/BIBLIOGRAPHIE_DE_DEPART.md` reste une note de travail historique.
