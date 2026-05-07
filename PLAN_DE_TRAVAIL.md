# Plan de travail opérationnel

Projet : predictive e-diagnostics for multi-state movement models

Version : 2026-05-07

## 1. Résumé du projet

L'objectif est de développer une méthode de diagnostic prédictif pour les HMM de mouvement animalier. Le modèle courant est évalué comme générateur séquentiel à partir de ses densités prédictives observables, et non à partir des états latents décodés. Les diagnostics sont formulés comme des ratios de densités prédictives, de densités de features ou de densités blockwise produisant des e-values séquentielles et des e-process.

La version actuelle de l'article est `paper/predictive_e_diagnostics_hmm_improved.tex`. Elle structure le projet autour de sept composantes : filtrage observable, e-process prédictifs, choix prédictible des diagnostics, mélanges et switching, localisation pondérée et par états filtrés, diagnostics feature-level pour données circulaires-linéaires, diagnostics blockwise pour comportements génératifs à long horizon, et validation train/validation ou par unités indépendantes.

Le premier article doit rester ciblé sur des HMM multi-états simples avec observations longueur de pas et angle de virage, mais les simulations et l'analyse R doivent maintenant refléter la théorie plus riche du papier.

## 2. Hypothèses de départ

- Le premier manuscrit porte sur des HMM de mouvement, pas sur un cadre HMM-SSF complet.
- La validité statistique principale est conditionnelle à une information d'entraînement fixée avant validation.
- Le protocole par défaut est train/validation ou validation par individus.
- Les états latents sont intégrés par filtrage dans les densités prédictives observables.
- Les états décodés peuvent servir à l'interprétation descriptive, mais pas à établir la validité.
- Les alternatives diagnostiques sont choisies avant validation, ou sélectionnées de manière prédictible avec l'information disponible avant `Y_t`.
- Les diagnostics parallèles sur les mêmes observations sont rapportés séparément ou combinés par mélange pondéré. Leur produit n'est pas valide par défaut.
- Le jeu de données réel n'est pas encore identifié. Je ne sais pas.

## 3. Livrables principaux

| Livrable | Description | Critère d'acceptation |
|---|---|---|
| Article principal | Version actuelle dans `paper/predictive_e_diagnostics_hmm_improved.tex` | Compilation LaTeX sans erreur |
| Prototype R | Simulation HMM, filtrage observable, e-process prédictif | Exemple reproductible sous modèle simulé |
| Diagnostics R | État manquant, angles, step-angle, durée, localisation, mélange, blockwise | Interface commune et résultats interprétables |
| Simulations | Scénarios alignés sur les théorèmes du papier | Tables et figures générées de façon reproductible |
| Application réelle | Analyse d'un jeu de données de mouvement avec validation séparée | Données documentées, diagnostics prudents |
| Dépôt reproductible | Code, plans, article, scripts et sorties régénérables | Nouvelle installation capable de reproduire les sorties principales |

## 4. Phases du projet

Le plan détaillé phase par phase est maintenu dans `docs/PLAN_PAR_PHASE.md`.

| Phase | Objectif | Tâches principales | Sorties attendues |
|---|---|---|---|
| 0 | Structurer le dépôt | Arborescence, README, plan, article principal | Dépôt GitHub privé prêt |
| 1 | Stabiliser la théorie | Article principal, filtrage, e-process, localisation, features, blockwise | Version théorique actuelle complétée |
| 2 | Construire le noyau R | Simulation HMM, filtrage observable, log densités, e-process, graphiques | Prototype minimal S1 vérifié |
| 3 | Développer les diagnostics R | Menus diagnostiques, mélanges, switching, localisation, features, blockwise | Fonctions diagnostiques modulaires |
| 4 | Réaliser les simulations | Calibration, puissance, spécificité, localisation, mélange, blockwise, cross-validation | Tables et figures de simulation |
| 5 | Traiter l'application réelle | Choix des données, split train/validation, HMM, diagnostics globaux et localisés | Figures et interprétation écologique |
| 6 | Finaliser le manuscrit | Sections simulations et application, figures, tables, discussion | Version article complète |
| 7 | Vérifier avant soumission | Audit reproductibilité, code, statistiques, écologie, dépôt | Dépôt et manuscrit prêts |

## 5. Workstreams et tâches détaillées

### Théorie et manuscrit

| ID | Tâche | Sortie |
|---|---|---|
| T1 | Maintenir la notation de l'article autour de `Y_t`, `S_t`, `p_0`, `q_t`, `E_t`, `E_{1:t}`, `\mathcal F_t` | Notation stable |
| T2 | Vérifier que les simulations correspondent aux théorèmes : e-process, mixtures, switching, localisation, features, blockwise | Tableau théorie-simulation |
| T3 | Ajouter une section simulation dans l'article une fois les résultats disponibles | Section manuscrit |
| T4 | Ajouter une section application avec interprétation écologique prudente | Section manuscrit |
| T5 | Décider si un supplément est nécessaire pour les preuves longues et détails algorithmiques | Décision documentée |

### Analyse R et infrastructure

| ID | Tâche | Sortie |
|---|---|---|
| C1 | Implémenter des utilitaires numériques stables : `log_sum_exp()`, normalisation log, vérification de probabilités | Utilitaires testés |
| C2 | Implémenter la simulation HMM : états, longueurs, angles, covariables optionnelles, individus | `simulate_hmm_movement()` première version |
| C3 | Implémenter le forward filter sur l'échelle log et les densités prédictives observables | `hmm_forward_filter()`, `hmm_predictive_log_density()` |
| C4 | Implémenter les e-process : incréments, cumulés, seuil, temps de franchissement, résumé | `compute_eprocess()` |
| C5 | Implémenter les graphiques standards : e-process, incréments, seuil, contributions par individu et période | Fonctions de visualisation |
| C6 | Implémenter une interface commune de diagnostic retournant `log_p0`, `log_q`, `log_e`, `log_E`, `weights`, `metadata` | Format de sortie commun |
| C7 | Implémenter les diagnostics full-density : `K+1`, angle flexible, step-angle joint, durée | Fonctions diagnostiques |
| C8 | Implémenter les diagnostics feature-level : Rosenblatt, copule sur `[0,1]^2`, résidus circulaires | Fonctions feature-level |
| C9 | Implémenter les diagnostics blockwise : blocs temporels, features de déplacement, retour, résidence, barrière | Fonctions blockwise |
| C10 | Implémenter les mélanges et switching prédictibles entre diagnostics | Fonctions `diagnostic_mixture()` et `diagnostic_switch()` |
| C11 | Implémenter la localisation pondérée : périodes, habitats, individus, états filtrés, tempering | Fonctions de pondération |
| C12 | Implémenter la validation par individus et les moyennes cross-fitted sûres | Scripts ou fonctions de split |
| C13 | Écrire les tests unitaires et smoke tests R | Tests reproductibles |
| C14 | Documenter les dépendances et les commandes de reproduction | Instructions reproductibles |

### Simulations

| ID | Scénario | Question | Sorties minimales |
|---|---|---|---|
| S1 | Calibration sous null fixed-generator | Le taux de franchissement est-il contrôlé sous le HMM nul fixé ? | Implémenté : faux signal, `sup_t log E`, courbes typiques |
| S2 | Validation train/validation avec paramètres estimés | Le comportement reste-t-il raisonnable conditionnellement au train ? | Comparaison paramètres connus vs estimés |
| S3 | Nombre d'états insuffisant | Le diagnostic `K+1` détecte-t-il un état manquant ? | Puissance, temps de détection, localisation |
| S4 | Angles mal spécifiés | Le diagnostic angulaire réagit-il aux défauts circulaires ? | Signal angulaire, spécificité des autres diagnostics |
| S5 | Dépendance résiduelle step-angle | Les diagnostics Rosenblatt/copule détectent-ils la dépendance invisible aux marges ? | E-process feature-level et full-density |
| S6 | Durées non géométriques | Le diagnostic durée ou blockwise détecte-t-il la persistance comportementale ? | Signal de durée, comparaison HMM/HSMM simplifiée |
| S7 | Échec localisé | Les poids prédictibles localisent-ils le défaut par temps, individu, habitat ou état filtré ? | Courbes globales et localisées |
| S8 | Mélange et switching prédictibles | Les mélanges restent-ils calibrés et plus robustes qu'un diagnostic unique ? | E-process individuels, mixture, switching |
| S9 | Produits parallèles non valides | Le produit naïf de diagnostics parallèles gonfle-t-il le faux signal ? | Démonstration négative contrôlée |
| S10 | Blockwise long-horizon | Les diagnostics de blocs détectent-ils des défauts invisibles à un pas ? | Résultats par bloc et figures de trajectoires |
| S11 | Validation par individus et cross-fitted average | La moyenne pondérée d'e-values par unités indépendantes est-elle stable ? | Résumé par individu et moyenne cross-fitted |
| S12 | Enveloppe composite conservatrice | Une enveloppe simple contrôle-t-elle le faux signal sur une famille de HMM ? | Résultats exploratoires, optionnel |

### Application réelle

| ID | Tâche | Sortie |
|---|---|---|
| A1 | Identifier des jeux de données publics candidats, idéalement via `moveHMM` ou `momentuHMM` | Liste documentée |
| A2 | Évaluer licence, reproductibilité, qualité temporelle, nombre d'individus, covariables et pertinence écologique | Tableau comparatif |
| A3 | Définir le split train/validation, préférablement par individus si possible | Protocole d'analyse |
| A4 | Prétraiter les trajectoires et construire `L_t`, `Theta_t`, identifiants et covariables prédictibles | Données propres |
| A5 | Ajuster le HMM nul et les alternatives diagnostiques sur train seulement | Objets modèles |
| A6 | Calculer le filtrage observable et les log densités prédictives sur validation | `log_p0` validé |
| A7 | Calculer les diagnostics globaux, localisés, feature-level et blockwise pertinents | Résultats par diagnostic |
| A8 | Comparer diagnostics individuels, mélange pondéré et switching si justifié | Table de synthèse |
| A9 | Produire les figures finales : trajectoire, états filtrés, `log E`, incréments, localisation | Figures article |
| A10 | Rédiger l'interprétation écologique en distinguant signal prédictif, localisation et hypothèses exploratoires | Section application |

### Manuscrit

| ID | Tâche | Sortie |
|---|---|---|
| M1 | Maintenir la version principale de l'article | `paper/predictive_e_diagnostics_hmm_improved.tex` |
| M2 | Ajouter le protocole de simulation aligné sur S1 à S12 | Section simulation |
| M3 | Ajouter les résultats de simulation et figures | Figures et tables intégrées |
| M4 | Ajouter l'application réelle | Section application |
| M5 | Mettre à jour discussion et limites selon les résultats | Discussion proportionnée |
| M6 | Créer un supplément seulement si nécessaire | Supplément optionnel |

## 6. Jalons de décision

| Jalon | Question | Décision attendue |
|---|---|---|
| D1 | Le premier papier vise-t-il JABES ou Methods in Ecology and Evolution ? | Choix du style de manuscrit |
| D2 | Quel jeu de données réel est utilisable et partageable ? | Dataset retenu |
| D3 | Quelle alternative simple représenter pour le diagnostic step-angle ? | Copule, modèle joint ou feature Rosenblatt |
| D4 | Quels diagnostics doivent être dans le papier principal plutôt qu'en supplément ? | Portée finale des simulations |
| D5 | Le code reste-t-il sous forme de scripts ou devient-il un mini-package R interne ? | Organisation logicielle |
| D6 | Faut-il inclure l'enveloppe composite dans le premier article ? | Principal, supplément ou reporté |

## 7. Critères de qualité

- Les scripts doivent être reproductibles à partir d'une nouvelle session R.
- Les bibliothèques utilisées doivent être chargées explicitement.
- Les simulations doivent séparer génération, entraînement, validation, diagnostic et résumé.
- Les diagnostics doivent calculer `p_0` par filtrage observable, pas par états décodés.
- Les diagnostics parallèles ne doivent pas être multipliés naïvement dans les analyses principales.
- Les figures doivent montrer les seuils `log(1 / alpha)`, les incréments locaux et les versions localisées lorsque pertinent.
- Les résultats doivent distinguer calibration sous le nul, puissance sous alternative, spécificité diagnostique et localisation.
- Les résultats d'application ne doivent pas être présentés comme confirmatoires si l'analyse est exploratoire.

## 8. Risques et mesures de mitigation

| Risque | Impact | Mitigation |
|---|---|---|
| Alternatives trop flexibles | Diagnostic peu interprétable | Commencer par alternatives ciblées et menu pré-spécifié |
| Paramètres estimés sur les mêmes données | Garantie statistique fragile | Utiliser train/validation, validation par individus ou cross-fitting |
| Surinterprétation des états décodés | Conclusion écologique fragile | Utiliser filtrage pour la validité et décodage seulement pour décrire |
| Produit naïf de diagnostics parallèles | Faux signal gonflé | Rapporter séparément ou utiliser mixture/switching prédictible |
| Diagnostics feature-level mal calibrés | Garantie affaiblie | Estimer la loi nulle des features sur train ou simulations indépendantes |
| Diagnostics blockwise trop coûteux | Simulations lentes | Commencer par features de blocs simples et petites grilles |
| Application réelle trop complexe | Manuscrit dispersé | Choisir un dataset simple et reproductible |
| Code difficile à reproduire | Résultats non vérifiables | Automatiser les scripts et documenter les dépendances |

## 9. Prochaine unité de travail recommandée

La prochaine étape scientifique est la Phase 3 : commencer les diagnostics R modulaires avec une interface commune, puis implémenter le diagnostic `K` contre `K+1`.

Voir `docs/PLAN_PAR_PHASE.md` pour le déroulement détaillé, les livrables, les critères de réussite et les tests associés à chaque phase.
