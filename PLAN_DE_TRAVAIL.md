# Plan de travail opérationnel

Projet : predictive e-diagnostics for multi-state movement models

Version : 2026-05-07

## 1. Résumé du projet

L'objectif est de développer une méthode de diagnostic prédictif pour les HMM de mouvement animalier. Le modèle courant est évalué à partir de ses densités prédictives observables, et non à partir des états latents décodés. Les diagnostics sont formulés comme des ratios de densités prédictives produisant des e-values séquentielles et des e-process.

Le premier article doit rester volontairement ciblé : HMM multi-états simples, observations longueur de pas et angle de virage, validation train/test ou par individus, simulations contrôlées et une application réelle reproductible.

## 2. Hypothèses de départ

- Le premier manuscrit porte sur des HMM de mouvement, pas sur un cadre HMM-SSF complet.
- La validité statistique sera d'abord présentée conditionnellement à un ensemble d'entraînement fixé.
- Les états latents seront intégrés par filtrage dans les densités prédictives.
- Les diagnostics par état seront interprétés comme descriptifs si les états sont décodés après coup.
- Les alternatives diagnostiques seront choisies avant d'évaluer les observations de validation.
- Le jeu de données réel n'est pas encore identifié. Je ne sais pas.

## 3. Livrables principaux

| Livrable | Description | Critère d'acceptation |
|---|---|---|
| Note théorique | Cadre HMM, e-process, filtrage, paramètres estimés | Notation stable et preuve préliminaire relue |
| Prototype R | Fonctions de filtrage, densité prédictive et e-process | Exemple reproductible sous modèle simulé |
| Simulations | Six scénarios principaux | Scripts reproductibles, tables et figures générées |
| Application réelle | Analyse d'un jeu de données de mouvement | Données documentées, diagnostic interprété prudemment |
| Manuscrit | Article principal et supplément | Figures, preuves, résultats et références cohérents |
| Dépôt reproductible | Code, données publiques ou instructions, résultats | Nouvelle installation capable de reproduire les sorties principales |

## 4. Phases du projet

Le plan détaillé phase par phase est maintenu dans `docs/PLAN_PAR_PHASE.md`.

| Phase | Objectif | Tâches principales | Sorties attendues |
|---|---|---|---|
| 0 | Structurer le dépôt | Arborescence, README, plan, bibliographie initiale | Dépôt GitHub privé prêt |
| 1 | Stabiliser la théorie | Notation, théorème principal, validité filtrée, paramètres estimés | Note théorique 5 à 8 pages |
| 2 | Construire le prototype R | HMM simple, forward filter, densité prédictive, e-process | Prototype minimal vérifié |
| 3 | Développer les diagnostics | Nombre d'états, angles, dépendance longueur-angle, durées | Fonctions diagnostiques ciblées |
| 4 | Réaliser les simulations | Nul correct, état manquant, angles, dépendance, durées, échec localisé | Tables et figures de simulation |
| 5 | Traiter l'application réelle | Choix du jeu de données, nettoyage, HMM, diagnostics | Figures et interprétation écologique |
| 6 | Rédiger le manuscrit | Méthodes, théorie, simulations, application, discussion | Version 0.1 du manuscrit |
| 7 | Vérifier avant soumission | Audit reproductibilité, relecture statistique, relecture écologique | Dépôt et manuscrit prêts pour soumission |

## 5. Workstreams et tâches détaillées

### Théorie

| ID | Tâche | Sortie |
|---|---|---|
| T1 | Fixer la notation pour les trajectoires, états latents, densités prédictives et filtrage | Table de notation |
| T2 | Écrire le théorème de l'e-process prédictif sous HMM fixé | Énoncé formel |
| T3 | Démontrer que la validité repose sur la densité prédictive marginale observable | Proposition et preuve |
| T4 | Clarifier le rôle des paramètres estimés | Remarque train/test, par individus, cross-fitting |
| T5 | Formaliser la combinaison adaptative de diagnostics | Proposition ou remarque prudente |
| T6 | Définir les limites exactes des garanties anytime-valid | Paragraphe de discussion statistique |

### Code R

| ID | Tâche | Sortie |
|---|---|---|
| C1 | Implémenter une fonction stable pour le calcul log-sum-exp | Utilitaire testé |
| C2 | Implémenter le forward filter HMM sur l'échelle logarithmique | `hmm_forward_filter()` |
| C3 | Implémenter le calcul des e-process | `compute_eprocess()` |
| C4 | Écrire les graphiques standards | Courbes cumulatives, incréments, seuils |
| C5 | Développer le diagnostic K contre K+1 | Fonction diagnostique |
| C6 | Développer le diagnostic angulaire | Fonction diagnostique |
| C7 | Développer le diagnostic longueur-angle | Fonction diagnostique |
| C8 | Développer le diagnostic de durée | Fonction diagnostique |
| C9 | Ajouter des tests unitaires | Tests reproductibles |

### Simulations

| ID | Scénario | Question |
|---|---|---|
| S1 | Nul correct | Le taux de faux signal est-il contrôlé ? |
| S2 | Nombre d'états insuffisant | Le diagnostic K+1 détecte-t-il un état manquant ? |
| S3 | Distribution angulaire mal spécifiée | Le diagnostic angulaire est-il spécifique ? |
| S4 | Dépendance longueur-angle | Le diagnostic détecte-t-il une dépendance invisible aux marges ? |
| S5 | Durées non géométriques | Le diagnostic détecte-t-il une mémoire de durée ? |
| S6 | Échec localisé | Les incréments localisent-ils le segment problématique ? |

### Application réelle

| ID | Tâche | Sortie |
|---|---|---|
| A1 | Identifier des jeux de données publics candidats | Liste documentée |
| A2 | Évaluer licence, reproductibilité, qualité GPS et nombre d'individus | Tableau comparatif |
| A3 | Prétraiter la trajectoire | Données propres et script |
| A4 | Ajuster HMM K = 2, 3, 4 | Modèles comparés |
| A5 | Calculer les e-process diagnostiques | Résultats par diagnostic |
| A6 | Produire les visualisations finales | Figures article |
| A7 | Écrire une interprétation écologique prudente | Section application |

### Manuscrit

| ID | Tâche | Sortie |
|---|---|---|
| M1 | Construire le squelette LaTeX | `paper/main.tex` |
| M2 | Écrire la section méthodes | Version préliminaire |
| M3 | Écrire la section théorie | Version préliminaire avec preuves |
| M4 | Écrire la section simulations | Figures et tables intégrées |
| M5 | Écrire la section application | Résultats et interprétation |
| M6 | Écrire introduction et discussion | Claims proportionnés |
| M7 | Préparer le supplément | Preuves et détails algorithmiques |

## 6. Jalons de décision

| Jalon | Question | Décision attendue |
|---|---|---|
| D1 | Le premier papier vise-t-il JABES ou Methods in Ecology and Evolution ? | Choix du style de manuscrit |
| D2 | Quel jeu de données réel est utilisable et partageable ? | Dataset retenu |
| D3 | Quelle alternative simple représenter pour le diagnostic longueur-angle ? | Modèle diagnostique retenu |
| D4 | Les simulations suffisent-elles sans application complexe ? | Portée finale de l'article |
| D5 | Le code reste-t-il sous forme de scripts ou devient-il un package R ? | Organisation logicielle |

## 7. Critères de qualité

- Les scripts doivent être reproductibles à partir d'une nouvelle session R.
- Les bibliothèques utilisées doivent être chargées explicitement.
- Les diagnostics doivent séparer clairement estimation, validation et interprétation.
- Les figures doivent montrer les seuils `log(1 / alpha)` et les incréments locaux lorsque pertinent.
- Toute affirmation méthodologique dans le manuscrit doit être appuyée par une preuve, une simulation ou une référence.
- Les résultats d'application ne doivent pas être présentés comme confirmatoires si l'analyse est exploratoire.

## 8. Risques et mesures de mitigation

| Risque | Impact | Mitigation |
|---|---|---|
| Alternatives trop flexibles | Diagnostic peu interprétable | Privilégier des alternatives ciblées |
| Paramètres estimés sur les mêmes données | Garantie statistique fragile | Commencer par train/test ou validation par individus |
| Surinterprétation des états décodés | Conclusion écologique fragile | Utiliser le filtrage pour la validité et le décodage seulement pour décrire |
| Application réelle trop complexe | Manuscrit dispersé | Choisir un dataset simple et reproductible |
| Code difficile à reproduire | Résultats non vérifiables | Automatiser les scripts et documenter les dépendances |

## 9. Prochaine unité de travail recommandée

La prochaine étape scientifique est la Phase 1 : écrire une note théorique courte avec la notation finale, le théorème principal et la preuve pour le cas où le modèle nul et l'alternative diagnostique sont fixés avant la validation.

Voir `docs/PLAN_PAR_PHASE.md` pour le déroulement détaillé, les livrables, les critères de réussite et les tests associés à chaque phase.
