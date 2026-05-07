# Predictive e-diagnostics for multi-state movement models

Ce dépôt privé structure un projet de recherche sur les e-values et les e-process prédictifs pour le diagnostic de modèles multi-états de mouvement animalier, en particulier les HMM.

## Objectif

Développer un cadre théorique, computationnel et appliqué pour évaluer des HMM de mouvement comme générateurs séquentiels, en utilisant des densités prédictives observables et des diagnostics ciblés.

## État actuel

- Le plan initial est conservé dans `plan_travail_predictive_e_diagnostics_hmm.md`.
- Le plan opérationnel du projet est dans `PLAN_DE_TRAVAIL.md`.
- Le plan de travail par phase est dans `docs/PLAN_PAR_PHASE.md`.
- La note théorique de phase 1 est dans `paper/theory_note_phase1.tex`.
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
│   ├── main.tex
│   ├── theory_note_phase1.tex
│   ├── supplement.tex
│   ├── references.bib
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
```

Exemple minimal pour l'e-process :

```r
log_p0 <- dnorm(c(-0.2, 0.1, 0.5), mean = 0, sd = 1, log = TRUE)
log_p1 <- dnorm(c(-0.2, 0.1, 0.5), mean = 0.3, sd = 1, log = TRUE)
compute_eprocess(log_p0 = log_p0, log_p1 = log_p1, alpha = 0.05)
```

## Données

Les dossiers `application/data_raw/` et `application/data_processed/` sont ignorés par Git, sauf leurs fichiers de documentation. Cette règle évite de publier accidentellement des données sensibles, même dans un dépôt privé.

## Références de départ

Voir `docs/BIBLIOGRAPHIE_DE_DEPART.md` et `paper/references.bib`.
