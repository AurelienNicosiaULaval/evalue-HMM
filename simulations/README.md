# Simulations

Les simulations doivent maintenant suivre la version actuelle de l'article `paper/predictive_e_diagnostics_hmm_improved.tex`.

Chaque script doit séparer clairement :

1. génération des données ;
2. entraînement ou fixation du modèle nul ;
3. construction des alternatives diagnostiques ;
4. validation ;
5. calcul des e-process ;
6. figures et tables.

Les sorties doivent être écrites dans :

- `results/simulation_tables/`
- `results/simulation_figures/`

## Scripts prévus

| Script | Scénario |
|---|---|
| `01_null_fixed_generator.R` | Calibration sous HMM nul fixé, implémenté |
| `02_train_validation_estimated.R` | Validation train/validation avec paramètres estimés |
| `03_underfit_states.R` | Nombre d'états insuffisant, implémenté |
| `04_angle_misspecification.R` | Distribution angulaire mal spécifiée |
| `05_step_angle_dependence.R` | Dépendance résiduelle longueur-angle via Rosenblatt ou copule |
| `06_duration_or_blockwise.R` | Durées non géométriques ou diagnostic de bloc |
| `07_localized_failure.R` | Échec localisé et pondérations prédictibles |
| `08_mixture_switching.R` | Mélanges et switching prédictibles |
| `09_parallel_product_warning.R` | Démonstration que le produit parallèle naïf n'est pas valide par défaut |
| `10_blockwise_long_horizon.R` | Diagnostics blockwise à long horizon |
| `11_individual_validation_crossfit.R` | Validation par individus et moyenne cross-fitted |
| `12_composite_envelope_optional.R` | Enveloppe composite conservatrice, optionnelle |
| `run_all_simulations.R` | Exécution séquentielle des scripts implémentés |

Les scénarios S1 à S8 sont prioritaires pour le premier manuscrit. Les scénarios S9 à S12 peuvent servir d'avertissement méthodologique, de supplément ou d'extension selon l'espace disponible.
