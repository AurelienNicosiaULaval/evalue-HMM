# Plan de travail par phase

Source : `PLAN_DE_TRAVAIL.md`

Version : 2026-05-08

## Résumé

Le projet est maintenant dans la phase de finalisation du manuscrit. La version actuelle de l'article, `paper/predictive_e_diagnostics_hmm_improved.tex`, couvre les e-process prédictifs pour HMM, les diagnostics prédictibles multiples, les mélanges, le switching, la localisation pondérée, les diagnostics feature-level, les diagnostics blockwise et la validation par unités indépendantes.

Le principe directeur reste le même : chaque affirmation méthodologique doit être soutenue par une preuve, une simulation, une application reproductible ou une référence.

## Vue d'ensemble des phases

| Phase | Objectif | Tâches principales | Livrables | Critère de réussite |
|---|---|---|---|---|
| 0 | Structurer le dépôt | Organiser l'arborescence, README, plan, article principal | Dépôt GitHub privé prêt | Dépôt propre, versionné, reproductible |
| 1 | Stabiliser la théorie | Article principal, filtrage, e-process, localisation, features, blockwise | Version théorique actuelle | Le manuscrit compile et fixe les claims théoriques |
| 2 | Construire le noyau R | Simulation HMM, filtrage observable, log densités, e-process, graphiques | Prototype R minimal | Calibration simple sous le nul |
| 3 | Développer les diagnostics R | Full-density, feature-level, blockwise, mixtures, switching, localisation | Fonctions diagnostiques modulaires | Interface commune et résultats interprétables |
| 4 | Réaliser les simulations | Calibration, puissance, spécificité, localisation, mixtures, blockwise, cross-validation | Tables et figures | Résultats alignés avec les théorèmes de l'article |
| 5 | Traiter l'application réelle | Données, split train/validation, HMM, diagnostics globaux et localisés | Analyse elk reproductible | Interprétation écologique prudente |
| 6 | Finaliser le manuscrit | Simulations, application, figures, tables, discussion | Article complet en relecture | Claims appuyés par théorie, simulation ou application |
| 7 | Vérifier avant soumission | Audit reproductibilité, code, statistiques, écologie, dépôt | Dépôt et manuscrit prêts | Nouvelle installation capable de reproduire les sorties |

## Phase 0 : structuration du dépôt

Statut : complétée.

Objectif : disposer d'un dépôt privé propre, versionné et prêt pour un travail reproductible.

Tâches :

- Créer l'arborescence du projet.
- Conserver le plan initial comme note source historique.
- Rédiger le README du projet.
- Installer la version principale actuelle de l'article.
- Créer les dossiers pour le code R, les simulations, l'application réelle, les résultats et le manuscrit.
- Ignorer les données brutes, les données traitées et les résultats générés par défaut.

Livrables :

- `README.md`
- `PLAN_DE_TRAVAIL.md`
- `docs/PLAN_PAR_PHASE.md`
- `paper/predictive_e_diagnostics_hmm_improved.tex`
- Arborescence complète du dépôt

Critère de réussite :

- Le dépôt est disponible sur GitHub en privé.
- La branche principale est propre.
- Les données sensibles ne peuvent pas être ajoutées accidentellement sans modification explicite de `.gitignore`.

## Phase 1 : stabilisation théorique

Statut : complétée pour une première version.

Objectif : fixer les garanties théoriques qui guident l'implémentation R et les simulations.

Composantes théoriques à soutenir par le code :

- Densité prédictive observable par filtrage.
- E-process prédictif sous générateur nul fixé.
- Contrôle anytime-valid par seuil `1 / alpha`.
- Choix prédictible des diagnostics.
- Mélanges et switching prédictibles.
- Non-validité du produit naïf de diagnostics parallèles.
- Localisation pondérée par périodes, habitats, individus ou états filtrés.
- Diagnostics feature-level, incluant Rosenblatt et résidus circulaires-linéaires.
- Diagnostics blockwise pour comportement génératif à long horizon.
- Validation conditionnelle après entraînement, validation par individus et moyenne cross-fitted.
- Enveloppe composite conservatrice, optionnelle pour le premier article.

Livrables :

- `paper/predictive_e_diagnostics_hmm_improved.tex`
- Article compilé localement dans `manuscript_outputs/predictive_e_diagnostics_hmm_improved.pdf`
- Tableau de correspondance à créer entre théorèmes, simulations et fonctions R.

Critère de réussite :

- Le manuscrit compile.
- Les claims théoriques à vérifier par simulation sont explicitement identifiés.
- Les limites des garanties exactes sont distinguées des usages exploratoires.

## Phase 2 : noyau R minimal

Statut : première version complétée avec S1.

Objectif : construire une preuve de concept computationnelle fiable avant d'ajouter les diagnostics avancés.

Tâches :

- Implémenter ou stabiliser `log_sum_exp()` et les fonctions de normalisation log.
- Simuler un HMM de mouvement à deux états avec longueurs de pas et angles de virage.
- Permettre plusieurs individus et un split train/validation simple.
- Calculer les probabilités prédictives par forward filtering.
- Calculer `log_p0` comme densité prédictive observable marginalisée sur les états.
- Calculer `log_q` pour une alternative simple fixée avant validation.
- Calculer `log_e_t`, `log_E_t`, seuil `log(1 / alpha)`, temps de franchissement et indicateur de signal.
- Tracer une première courbe `log E_{1:t}` avec seuil et incréments locaux.
- Vérifier sous le nul avec paramètres connus.

Livrables :

- `simulate_hmm_movement()` ou équivalent.
- `hmm_forward_filter()` vérifié sur l'échelle log.
- `hmm_predictive_log_density()` vérifié.
- `compute_eprocess()` vérifié.
- `simulations/01_null_fixed_generator.R`.
- Tables locales `s1_null_fixed_generator_*.csv`.
- Figures locales `s1_null_fixed_generator_*.png`.

Critère de réussite :

- Une nouvelle session R peut reproduire l'exemple minimal.
- Les densités prédictives utilisent les probabilités filtrées et non les états décodés.
- Le taux de franchissement sous nul est compatible avec `alpha` dans une simulation simple.

## Phase 3 : diagnostics R modulaires

Statut : première version complétée avec l'interface commune, les diagnostics `K` contre `K+1`, angulaire, step-angle feature-level, localisation pondérée, durée blockwise, mixture et switching prédictible.

Objectif : développer les diagnostics correspondant au catalogue du papier.

Interface commune attendue :

Chaque diagnostic doit retourner au minimum :

- `diagnostic_name`
- `time`
- `individual_id`, si disponible
- `log_p0`
- `log_q`
- `log_e_increment`
- `log_e_cumulative`
- `threshold`
- `crossing_time`
- `signal`
- `weights`, si diagnostic localisé
- `metadata`, incluant le split, les paramètres et le type de diagnostic

Ordre recommandé :

1. Diagnostic full-density `K` contre `K+1`.
2. Diagnostic full-density ou feature-level pour angles mal spécifiés.
3. Diagnostic Rosenblatt/copule pour dépendance résiduelle step-angle.
4. Localisation pondérée : temps, individu, habitat, état filtré.
5. Diagnostic durée via approximation HSMM ou feature blockwise.
6. Mélange pondéré de diagnostics.
7. Switching prédictible entre diagnostics.
8. Diagnostic blockwise long-horizon.
9. Moyenne cross-fitted par individus.
10. Enveloppe composite conservatrice, optionnelle.

Livrables :

- `R/diagnostic_interface.R`.
- `R/diagnostics_states.R` avec `diagnostic_extra_state()`.
- `R/diagnostics_angles.R` avec `diagnostic_angle()`.
- `R/diagnostics_copula.R` avec `diagnostic_step_angle_dependence()`.
- `R/diagnostics_localization.R` avec localisation linéaire, tempering par puissance, fenêtres temporelles et poids d'état filtré.
- `R/diagnostics_duration.R` avec diagnostic blockwise de durée basé sur un indicateur observable de pas long.
- `R/diagnostics_combination.R` avec mixture pondérée et switching prédictible.
- Documentation courte de chaque diagnostic.
- Exemples reproductibles sur données simulées.
- Tests unitaires ou smoke tests.

Critère de réussite :

- Chaque diagnostic produit un e-process interprétable.
- Les sorties ont une structure commune.
- Les diagnostics ne reposent pas sur les états Viterbi pour la validité.
- Les produits naïfs de diagnostics parallèles ne sont pas utilisés dans l'analyse principale.

## Phase 4 : simulations principales

Statut : complétée pour la première version avec S1 à S12.

Objectif : évaluer calibration, puissance, spécificité, localisation et comportement des combinaisons diagnostiques.

Scénarios prioritaires :

| ID | Scénario | Question | Résultat attendu |
|---|---|---|---|
| S1 | Null fixed-generator | L'e-process est-il calibré sous HMM nul fixé ? | Implémenté, faux signal compatible avec `alpha` |
| S2 | Train/validation avec paramètres estimés | La calibration reste-t-elle raisonnable conditionnellement au train ? | Implémenté avec estimateur oracle-state, différence documentée entre paramètres connus et estimés |
| S3 | Nombre d'états insuffisant | Le diagnostic `K+1` détecte-t-il un état manquant ? | Implémenté, croissance forte de `log E` |
| S4 | Angles mal spécifiés | Le diagnostic angulaire détecte-t-il un défaut circulaire ? | Implémenté, signal angulaire fort |
| S5 | Dépendance step-angle | Le diagnostic Rosenblatt/copule détecte-t-il une dépendance invisible aux marges ? | Implémenté, signal feature-level clair |
| S6 | Durées non géométriques | Le diagnostic durée ou blockwise détecte-t-il la persistance comportementale ? | Implémenté, signal fort sous HSMM et conservateur sous HMM nul |
| S7 | Échec localisé | Les poids prédictibles localisent-ils le défaut ? | Implémenté, signal plus net dans la fenêtre et l'état ciblés |
| S8 | Mixture et switching | Les combinaisons prédictibles restent-elles calibrées et robustes ? | Implémenté, mixture calibrée et switching interprétable |
| S9 | Produit parallèle naïf | Le produit de diagnostics parallèles gonfle-t-il le faux signal ? | Implémenté, faux signal gonflé sous nul |
| S10 | Blockwise long-horizon | Les défauts à long horizon sont-ils détectés par blocs ? | Implémenté, signal blockwise via rectitude des blocs |
| S11 | Validation par individus | Les e-values par individus et leur moyenne cross-fitted sont-elles stables ? | Implémenté, moyenne finale sûre et scan individuel exploratoire |
| S12 | Enveloppe composite | Une enveloppe composite simple contrôle-t-elle le faux signal ? | Implémenté en supplément |

Découpage retenu :

- Article principal : S1, S3, S4, S5, S6, S7, S8.
- Matériel supplémentaire : S2, S9, S10, S11, S12.
- Le fichier principal est `paper/predictive_e_diagnostics_hmm_improved.tex`.
- Le supplément est `paper/supplementary_material.tex`.

Mesures à rapporter :

- Taux de faux signal pour `alpha = 0.10`, `0.05`, `0.01`.
- Puissance empirique.
- Temps moyen de franchissement du seuil.
- Distribution de `sup_t log E_{1:t}`.
- Pente moyenne de `log E_{1:t}` sous alternative.
- Diagnostic dominant.
- Qualité de localisation temporelle, individuelle, habitat ou état filtré.
- Comparaison diagnostic individuel, mixture et switching.
- Coût computationnel approximatif.

Livrables :

- Scripts de simulation alignés sur S1 à S12.
- `simulations/run_all_simulations.R` mis à jour.
- Tables dans `results/simulation_tables/`.
- Figures dans `results/simulation_figures/`.
- Court rapport de simulation ou section manuscrit.

Critère de réussite :

- Les simulations sont reproductibles.
- Les résultats soutiennent directement les claims du papier.
- Les figures montrent global, localisé et incréments lorsque pertinent.
- Les scénarios optionnels sont clairement marqués comme supplément ou extension.

## Phase 5 : application réelle

Objectif : démontrer l'utilité du cadre sur un jeu de données de mouvement réel, public et reproductible.

Statut : première application reproductible complétée avec `moveHMM::elk_data`. L'individu `elk-115` est tenu hors entraînement, les autres individus servent à ajuster les HMM `K = 2, 3, 4`, et le modèle nul est sélectionné par BIC.

Tâches :

- Identifier des jeux de données candidats dans les écosystèmes `moveHMM` et `momentuHMM`. Complété pour la première version.
- Documenter la source, les variables disponibles, le nombre d'individus et la qualité temporelle. Complété pour la première application.
- Choisir un dataset simple plutôt qu'une application trop complexe. Complété : `moveHMM::elk_data`.
- Définir un split train/validation, préférablement par individus si plusieurs individus sont disponibles. Complété : `elk-115` en validation.
- Prétraiter les trajectoires. Complété : `application/01_preprocess.R`.
- Construire longueurs de pas, angles de virage, identifiants, périodes et covariables prédictibles. Complété.
- Ajuster le HMM nul et les alternatives sur train seulement. Complété : `application/02_fit_hmm.R`.
- Calculer `log_p0` par filtrage observable sur validation. Complété : `application/03_compute_eprocess.R`.
- Calculer un menu de diagnostics : `K+1`, angle, step-angle, durée ou blockwise selon la pertinence du dataset. Complété pour la première application : `K+1`, angle, fixed mixture et localisation.
- Calculer les versions localisées : individu, période, habitat si disponible, état filtré. Complété pour l'état filtré à longue distance.
- Comparer diagnostics individuels, mixture pondérée et switching seulement si la règle est prédictible. Complété avec fixed mixture.
- Produire les figures d'application. Complété avec figures ggplot.
- Rédiger l'interprétation écologique sans surinterpréter les états décodés. Complété dans la section application.

Livrables :

- Fiche de sélection du jeu de données.
- Scripts `application/01_preprocess.R` à `application/04_figures_application.R` complétés.
- Tables de résultats d'application.
- Figures dans `results/application_figures/`.
- Section application du manuscrit.

Critère de réussite :

- L'analyse peut être reproduite depuis les scripts.
- Les données sont légalement utilisables et documentées.
- L'interprétation distingue clairement diagnostic prédictif, localisation et hypothèse écologique.

## Phase 6 : finalisation du manuscrit

Statut : en cours. Les sections théorie, simulations et application sont présentes; la priorité est maintenant la relecture éditoriale, la cohérence avec le supplément et l'audit reproductibilité.

Objectif : intégrer les résultats de simulation et d'application dans la version actuelle de l'article.

Tâches :

- Vérifier la section simulation avec design, scénarios, métriques et résultats.
- Vérifier les figures et tables de simulation.
- Vérifier la section application réelle et ses figures.
- Relire discussion et limites selon les résultats.
- Maintenir le découpage principal/supplément déjà décidé.
- Vérifier que le supplément ne contredit pas l'article principal.
- Harmoniser les références croisées, captions, notations et seuils.

Livrables :

- `paper/predictive_e_diagnostics_hmm_improved.tex` complété et relu.
- Figures et tables intégrées.
- Supplément `paper/supplementary_material.tex` cohérent avec l'article.
- Bibliographie cohérente.

Critère de réussite :

- Le manuscrit compile.
- Les claims sont appuyés par une preuve, une simulation ou une référence.
- Les limites sont explicites.

## Phase 7 : vérification avant soumission

Statut : audit local complété. Le rapport est dans `docs/REPRODUCIBILITY_AUDIT.md`. Un premier `renv.lock` a été ajouté. Il reste à tester une reproduction sur une installation neuve.

Objectif : vérifier la reproductibilité, la validité statistique et la cohérence éditoriale avant soumission.

Tâches :

- Relancer tous les scripts depuis une session R propre.
- Vérifier que les tables et figures du manuscrit sont régénérables.
- Auditer les dépendances R.
- Vérifier que les données sensibles ne sont pas suivies par Git.
- Vérifier que le produit naïf de diagnostics parallèles n'est pas utilisé comme résultat valide.
- Relire les preuves.
- Relire les simulations et leurs conclusions.
- Relire l'interprétation écologique.
- Nettoyer les fichiers temporaires.
- Préparer une archive ou une version reproductible du dépôt.

Livrables :

- Rapport d'audit interne.
- Manuscrit prêt pour soumission.
- Supplément prêt si nécessaire.
- Dépôt propre et reproductible.

Critère de réussite :

- Une nouvelle installation peut reproduire les résultats principaux.
- Les figures et tables correspondent au manuscrit.
- Les conclusions restent proportionnées aux résultats.

## Tests et scénarios de validation

| Test | Phase | Résultat attendu |
|---|---|---|
| Test R minimal | 2 | `compute_eprocess()` retourne incréments, cumulés, seuil et temps de franchissement |
| Filtrage HMM | 2 | `log_p0` utilise les probabilités filtrées, pas les états Viterbi |
| Null fixed-generator | 4 | Le taux de faux signal reste contrôlé pour `alpha = 0.10`, `0.05`, `0.01` |
| Train/validation estimé | 4 | Implémenté avec paramètres connus, estimation oracle-state et validation sous générateur ajusté |
| État manquant | 4 | Le diagnostic `K+1` accumule de l'évidence contre le modèle sous-ajusté |
| Angles mal spécifiés | 4 | Le diagnostic angulaire réagit davantage que les diagnostics non concernés |
| Dépendance step-angle | 4 | Le diagnostic Rosenblatt/copule détecte une dépendance résiduelle |
| Durées non géométriques | 4 | Le diagnostic durée ou blockwise détecte une mémoire de durée |
| Échec localisé | 4 | Les poids prédictibles localisent les segments problématiques |
| Mixture/switching | 4 | Les combinaisons prédictibles restent calibrées sous le nul |
| Produit parallèle naïf | 4 | Le faux signal gonflé est démontré comme avertissement méthodologique |
| Blockwise long-horizon | 4 | Implémenté, les features de blocs détectent un défaut de dépendance angulaire long-horizon |
| Validation par individus | 4, 5 | Implémenté, les résultats par individu et la moyenne cross-fitted sont rapportés |
| Application réelle | 5 | Les résultats sont reproductibles et interprétés prudemment |
| Audit final | 7 | Le dépôt permet de reconstruire les sorties principales |

## Hypothèses et choix par défaut

- Le premier manuscrit vise un style JABES par défaut.
- Le projet reste centré sur les HMM simples, pas sur les HMM-SSF complets.
- La garantie statistique principale est formulée avec séparation train/validation ou validation par individus.
- Les états latents sont intégrés par filtrage dans les densités prédictives.
- Les états décodés peuvent servir à l'interprétation, mais pas à établir la validité de l'e-process.
- Les diagnostics parallèles sont rapportés séparément ou combinés par mixture/switching prédictible.
- Le produit naïf de diagnostics parallèles n'est pas une procédure valide par défaut.
- Le code reste sous forme de scripts R pour la première version.
- La transformation en package R est une décision ultérieure.
- Le premier jeu de données réel est `moveHMM::elk_data`.
- Des jeux de données additionnels pourront être utilisés plus tard comme analyses de sensibilité.

## Prochaine action concrète

Tester `renv::restore()` sur une installation neuve ou dans un clone séparé, puis relancer les scripts principaux.
