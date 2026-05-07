# Données traitées

Les fichiers de données traitées ne sont pas suivis par Git par défaut.

Documenter ici les scripts qui génèrent chaque fichier traité.

- `elk_prepared.csv` est généré par `application/01_preprocess.R`.
- `elk_movehmm_selected_models.rds` est généré par `application/02_fit_hmm.R`.
- `elk_application_diagnostics.rds` est généré par `application/03_compute_eprocess.R`.
