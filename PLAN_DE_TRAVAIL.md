# Plan de travail opérationnel

Projet : predictive e-diagnostics for multi-state movement models

Version : 2026-05-08

## 1. Résumé du projet

L’objectif est de développer une méthode de diagnostic prédictif pour
les HMM de mouvement animalier. Le modèle courant est évalué comme
générateur séquentiel à partir de ses densités prédictives observables,
et non à partir des états latents décodés. Les diagnostics sont formulés
comme des ratios de densités prédictives, de densités de features ou de
densités blockwise produisant des e-values séquentielles et des
e-process.

La version actuelle de l’article est
`paper/predictive_e_diagnostics_hmm_improved.tex`. Elle structure le
projet autour de sept composantes : filtrage observable, e-process
prédictifs, choix prédictible des diagnostics, mélanges et switching,
localisation pondérée et par états filtrés, diagnostics feature-level
pour données circulaires-linéaires, diagnostics blockwise pour
comportements génératifs à long horizon, et validation train/validation
ou par unités indépendantes.

Le premier article reste ciblé sur des HMM multi-états simples avec
observations longueur de pas et angle de virage. Les simulations S1 à
S12 sont implémentées. L’article principal retient S1, S3, S4, S5, S6,
S7 et S8, tandis que le supplément documente S2, S9, S10, S11 et S12.
L’application réelle utilise
[`moveHMM::elk_data`](https://rdrr.io/pkg/moveHMM/man/elk_data.html),
avec l’individu `elk-115` comme validation complète.

## 2. Hypothèses de départ

- Le premier manuscrit porte sur des HMM de mouvement, pas sur un cadre
  HMM-SSF complet.
- La validité statistique principale est conditionnelle à une
  information d’entraînement fixée avant validation.
- Le protocole par défaut est train/validation ou validation par
  individus.
- Les états latents sont intégrés par filtrage dans les densités
  prédictives observables.
- Les états décodés peuvent servir à l’interprétation descriptive, mais
  pas à établir la validité.
- Les alternatives diagnostiques sont choisies avant validation, ou
  sélectionnées de manière prédictible avec l’information disponible
  avant `Y_t`.
- Les diagnostics parallèles sur les mêmes observations sont rapportés
  séparément ou combinés par mélange pondéré. Leur produit n’est pas
  valide par défaut.
- Le premier jeu de données réel est
  [`moveHMM::elk_data`](https://rdrr.io/pkg/moveHMM/man/elk_data.html),
  avec validation sur l’individu `elk-115`.

## 3. Livrables principaux

| Livrable | Description | Critère d’acceptation |
|----|----|----|
| Article principal | Version actuelle dans `paper/predictive_e_diagnostics_hmm_improved.tex` | Compilation LaTeX sans erreur, figures principales intégrées |
| Prototype R | Simulation HMM, filtrage observable, e-process prédictif | Exemple reproductible sous modèle simulé |
| Diagnostics R | État manquant, angles, step-angle, durée, localisation, mélange, blockwise | Interface commune et résultats interprétables |
| Simulations | Scénarios alignés sur les théorèmes du papier | Tables et figures générées de façon reproductible |
| Application réelle | Analyse de [`moveHMM::elk_data`](https://rdrr.io/pkg/moveHMM/man/elk_data.html) avec validation séparée | Données documentées, diagnostics prudents, figures ggplot intégrées |
| Dépôt reproductible | Code, plans, article, scripts et sorties régénérables | Audit local réussi, nouvelle installation encore à tester |

## 4. Phases du projet

Le plan détaillé phase par phase est maintenu dans
`docs/PLAN_PAR_PHASE.md`.

| Phase | Objectif | Tâches principales | Sorties attendues |
|----|----|----|----|
| 0 | Structurer le dépôt | Arborescence, README, plan, article principal | Dépôt GitHub privé prêt |
| 1 | Stabiliser la théorie | Article principal, filtrage, e-process, localisation, features, blockwise | Version théorique actuelle complétée |
| 2 | Construire le noyau R | Simulation HMM, filtrage observable, log densités, e-process, graphiques | Prototype minimal S1 vérifié |
| 3 | Développer les diagnostics R | Menus diagnostiques, mélanges, switching, localisation, features, blockwise | Première version des diagnostics principaux complétée |
| 4 | Réaliser les simulations | Calibration, puissance, spécificité, localisation, mélange, blockwise, cross-validation | Tables et figures de simulation |
| 5 | Traiter l’application réelle | Choix des données, split train/validation, HMM, diagnostics globaux et localisés | Première application elk complétée |
| 6 | Finaliser le manuscrit | Sections simulations et application, figures, tables, discussion | Article complet en relecture éditoriale |
| 7 | Vérifier avant soumission | Audit reproductibilité, code, statistiques, écologie, dépôt | Audit local complété, `renv.lock` ajouté, test fresh-clone à faire |

## 5. Workstreams et tâches détaillées

### Théorie et manuscrit

| ID | Tâche | Sortie |
|----|----|----|
| T1 | Maintenir la notation de l’article autour de `Y_t`, `S_t`, `p_0`, `q_t`, `E_t`, `E_{1:t}`, `\mathcal F_t` | Notation stable |
| T2 | Vérifier que les simulations correspondent aux théorèmes : e-process, mixtures, switching, localisation, features, blockwise | Tableau théorie-simulation |
| T3 | Ajouter une section simulation dans l’article une fois les résultats disponibles | Complété : section simulation |
| T4 | Ajouter une section application avec interprétation écologique prudente | Complété : section application |
| T5 | Décider si un supplément est nécessaire pour les preuves longues et détails algorithmiques | Complété : supplément créé |

### Analyse R et infrastructure

| ID | Tâche | Sortie |
|----|----|----|
| C1 | Implémenter des utilitaires numériques stables : `log_sum_exp()`, normalisation log, vérification de probabilités | Utilitaires testés |
| C2 | Implémenter la simulation HMM : états, longueurs, angles, covariables optionnelles, individus | [`simulate_hmm_movement()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/simulate_hmm_movement.md) première version |
| C3 | Implémenter le forward filter sur l’échelle log et les densités prédictives observables | [`hmm_forward_filter()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_forward_filter.md), [`hmm_predictive_log_density()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/hmm_predictive_log_density.md) |
| C4 | Implémenter les e-process : incréments, cumulés, seuil, temps de franchissement, résumé | [`compute_eprocess()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/compute_eprocess.md) |
| C5 | Implémenter les graphiques standards : e-process, incréments, seuil, contributions par individu et période | Complété pour simulations et application elk |
| C6 | Implémenter une interface commune de diagnostic retournant `log_p0`, `log_q`, `log_e`, `log_E`, `weights`, `metadata` | [`make_predictive_diagnostic()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/make_predictive_diagnostic.md) première version |
| C7 | Implémenter les diagnostics full-density : `K+1`, angle flexible, step-angle joint, durée | [`diagnostic_extra_state()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_extra_state.md) et [`diagnostic_angle()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_angle.md) premières versions |
| C8 | Implémenter les diagnostics feature-level : Rosenblatt, copule sur `[0,1]^2`, résidus circulaires | [`diagnostic_step_angle_dependence()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_step_angle_dependence.md) première version |
| C9 | Implémenter les diagnostics blockwise : blocs temporels, features de déplacement, retour, résidence, barrière | Amorçé : durée blockwise dans `R/diagnostics_duration.R` |
| C10 | Implémenter les mélanges et switching prédictibles entre diagnostics | Implémenté : [`diagnostic_mixture()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_mixture.md) et [`diagnostic_switch()`](https://aureliennicosiaulaval.github.io/evalue-HMM/reference/diagnostic_switch.md) |
| C11 | Implémenter la localisation pondérée : périodes, habitats, individus, états filtrés, tempering | Implémenté : `R/diagnostics_localization.R` |
| C12 | Implémenter la validation par individus et les moyennes cross-fitted sûres | Scripts ou fonctions de split |
| C13 | Écrire les tests unitaires et smoke tests R | Tests reproductibles |
| C14 | Documenter les dépendances et les commandes de reproduction | Instructions reproductibles |

### Simulations

| ID | Scénario | Question | Sorties minimales |
|----|----|----|----|
| S1 | Calibration sous null fixed-generator | Le taux de franchissement est-il contrôlé sous le HMM nul fixé ? | Implémenté : faux signal, `sup_t log E`, courbes typiques |
| S2 | Validation train/validation avec paramètres estimés | Le comportement reste-t-il raisonnable conditionnellement au train ? | Implémenté : paramètres connus, estimation oracle-state, validation sous vrai nul et sous générateur ajusté |
| S3 | Nombre d’états insuffisant | Le diagnostic `K+1` détecte-t-il un état manquant ? | Implémenté : puissance et temps de détection |
| S4 | Angles mal spécifiés | Le diagnostic angulaire réagit-il aux défauts circulaires ? | Implémenté : signal angulaire fort |
| S5 | Dépendance résiduelle step-angle | Les diagnostics Rosenblatt/copule détectent-ils la dépendance invisible aux marges ? | Implémenté : e-process feature-level |
| S6 | Durées non géométriques | Le diagnostic durée ou blockwise détecte-t-il la persistance comportementale ? | Implémenté : feature blockwise observable, HMM vs HSMM |
| S7 | Échec localisé | Les poids prédictibles localisent-ils le défaut par temps, individu, habitat ou état filtré ? | Implémenté : fenêtre temporelle et état filtré |
| S8 | Mélange et switching prédictibles | Les mélanges restent-ils calibrés et plus robustes qu’un diagnostic unique ? | Implémenté : diagnostics individuels, mixture, switching |
| S9 | Produits parallèles non valides | Le produit naïf de diagnostics parallèles gonfle-t-il le faux signal ? | Implémenté : faux signal gonflé sous nul |
| S10 | Blockwise long-horizon | Les diagnostics de blocs détectent-ils des défauts invisibles à un pas ? | Implémenté : rectitude par bloc, lois simulées indépendantes, puissance long-horizon |
| S11 | Validation par individus et cross-fitted average | La moyenne pondérée d’e-values par unités indépendantes est-elle stable ? | Implémenté : moyenne finale sûre, scan individuel exploratoire, individu défaillant localisé |
| S12 | Enveloppe composite conservatrice | Une enveloppe simple contrôle-t-elle le faux signal sur une famille de HMM ? | Implémenté : famille finie de HMM, enveloppe conservatrice, coût de puissance documenté |

Découpage retenu pour le manuscrit :

- Article principal : S1, S3, S4, S5, S6, S7, S8.
- Matériel supplémentaire : S2, S9, S10, S11, S12.
- Raison : le texte principal reste centré sur calibration, diagnostics
  ciblés, localisation et combinaison prédictible ; le supplément
  documente les analyses de sensibilité, avertissements et extensions
  avancées.

### Application réelle

| ID | Tâche | Sortie |
|----|----|----|
| A1 | Identifier des jeux de données publics candidats, idéalement via `moveHMM` ou `momentuHMM` | Complété : [`moveHMM::elk_data`](https://rdrr.io/pkg/moveHMM/man/elk_data.html) retenu |
| A2 | Évaluer licence, reproductibilité, qualité temporelle, nombre d’individus, covariables et pertinence écologique | Complété : table de sélection |
| A3 | Définir le split train/validation, préférablement par individus si possible | Complété : `elk-115` en validation |
| A4 | Prétraiter les trajectoires et construire `L_t`, `Theta_t`, identifiants et covariables prédictibles | Complété : `application/01_preprocess.R` |
| A5 | Ajuster le HMM nul et les alternatives diagnostiques sur train seulement | Complété : `application/02_fit_hmm.R` |
| A6 | Calculer le filtrage observable et les log densités prédictives sur validation | Complété : `application/03_compute_eprocess.R` |
| A7 | Calculer les diagnostics globaux, localisés, feature-level et blockwise pertinents | Complété pour la première application : `K+1`, angle, mixture, localisation par état filtré |
| A8 | Comparer diagnostics individuels, mélange pondéré et switching si justifié | Complété : diagnostics individuels et fixed mixture |
| A9 | Produire les figures finales : trajectoire, états filtrés, `log E`, incréments, localisation | Complété : figures ggplot dans `paper/figures/` |
| A10 | Rédiger l’interprétation écologique en distinguant signal prédictif, localisation et hypothèses exploratoires | Complété : section application |

### Manuscrit

| ID | Tâche | Sortie |
|----|----|----|
| M1 | Maintenir la version principale de l’article | `paper/predictive_e_diagnostics_hmm_improved.tex` |
| M2 | Ajouter le protocole de simulation aligné sur S1 à S12 | Section simulation |
| M3 | Ajouter les résultats de simulation et figures | Complété : table principale de simulation |
| M4 | Ajouter l’application réelle | Complété : section application et figures |
| M5 | Mettre à jour discussion et limites selon les résultats | Complété pour première version, à relire |
| M6 | Créer un supplément seulement si nécessaire | Complété : `paper/supplementary_material.tex` |

## 6. Jalons de décision

| Jalon | Question | Décision attendue |
|----|----|----|
| D1 | Le premier papier vise-t-il JABES ou Methods in Ecology and Evolution ? | Choix du style de manuscrit |
| D2 | Quel jeu de données réel est utilisable et partageable ? | Dataset retenu |
| D3 | Quelle alternative simple représenter pour le diagnostic step-angle ? | Copule, modèle joint ou feature Rosenblatt |
| D4 | Quels diagnostics doivent être dans le papier principal plutôt qu’en supplément ? | Décidé : S1, S3, S4, S5, S6, S7, S8 au principal ; S2, S9, S10, S11, S12 au supplément |
| D5 | Le code reste-t-il sous forme de scripts ou devient-il un mini-package R interne ? | Organisation logicielle |
| D6 | Faut-il inclure l’enveloppe composite dans le premier article ? | Décidé : supplément |

## 7. Critères de qualité

- Les scripts doivent être reproductibles à partir d’une nouvelle
  session R.
- Les bibliothèques utilisées doivent être chargées explicitement.
- Les simulations doivent séparer génération, entraînement, validation,
  diagnostic et résumé.
- Les diagnostics doivent calculer `p_0` par filtrage observable, pas
  par états décodés.
- Les diagnostics parallèles ne doivent pas être multipliés naïvement
  dans les analyses principales.
- Les figures doivent montrer les seuils `log(1 / alpha)`, les
  incréments locaux et les versions localisées lorsque pertinent.
- Les résultats doivent distinguer calibration sous le nul, puissance
  sous alternative, spécificité diagnostique et localisation.
- Les résultats d’application ne doivent pas être présentés comme
  confirmatoires si l’analyse est exploratoire.

## 8. Risques et mesures de mitigation

| Risque | Impact | Mitigation |
|----|----|----|
| Alternatives trop flexibles | Diagnostic peu interprétable | Commencer par alternatives ciblées et menu pré-spécifié |
| Paramètres estimés sur les mêmes données | Garantie statistique fragile | Utiliser train/validation, validation par individus ou cross-fitting |
| Surinterprétation des états décodés | Conclusion écologique fragile | Utiliser filtrage pour la validité et décodage seulement pour décrire |
| Produit naïf de diagnostics parallèles | Faux signal gonflé | Rapporter séparément ou utiliser mixture/switching prédictible |
| Diagnostics feature-level mal calibrés | Garantie affaiblie | Estimer la loi nulle des features sur train ou simulations indépendantes |
| Diagnostics blockwise trop coûteux | Simulations lentes | Commencer par features de blocs simples et petites grilles |
| Application réelle trop complexe | Manuscrit dispersé | Choisir un dataset simple et reproductible |
| Code difficile à reproduire | Résultats non vérifiables | Automatiser les scripts et documenter les dépendances |

## 9. Prochaine unité de travail recommandée

La prochaine étape scientifique est un test fresh-clone : restaurer les
dépendances avec `renv::restore()` dans une copie neuve du dépôt, puis
relancer l’application, les simulations et la compilation.

Voir `docs/PLAN_PAR_PHASE.md` pour le déroulement détaillé, les
livrables, les critères de réussite et les tests associés à chaque
phase.
