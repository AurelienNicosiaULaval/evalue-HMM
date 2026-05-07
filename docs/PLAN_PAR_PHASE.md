# Plan de travail par phase

Source : `PLAN_DE_TRAVAIL.md`

Version : 2026-05-07

## Résumé

Le projet sera mené en huit phases, de la structuration du dépôt jusqu'à la préparation à la soumission. Le principe directeur est de commencer par un cadre théorique simple et vérifiable, puis de construire progressivement le prototype R, les diagnostics, les simulations, l'application réelle et le manuscrit.

## Vue d'ensemble des phases

| Phase | Objectif | Tâches principales | Livrables | Critère de réussite |
|---|---|---|---|---|
| 0 | Structurer le dépôt | Organiser l'arborescence, README, plan, bibliographie initiale, fichiers de départ | Dépôt GitHub privé prêt | Dépôt propre, versionné, reproductible |
| 1 | Stabiliser la théorie | Fixer la notation, écrire le théorème principal, clarifier le filtrage, traiter le cas des paramètres estimés | Note théorique de 5 à 8 pages | Notation stable et preuve préliminaire relue |
| 2 | Construire le prototype R minimal | Simuler un HMM simple, calculer le forward filter, les densités prédictives et l'e-process | Prototype R minimal | Exemple reproductible sous modèle simulé |
| 3 | Développer les diagnostics | Ajouter les diagnostics : nombre d'états, angles, dépendance longueur-angle, durées | Fonctions diagnostiques ciblées | Chaque diagnostic produit un e-process interprétable |
| 4 | Réaliser les simulations | Étudier nul correct, état manquant, angles mal spécifiés, dépendance, durées, échec localisé | Scripts, tables, figures | Taux de faux signal, puissance et localisation documentés |
| 5 | Traiter l'application réelle | Choisir un jeu de données, prétraiter, ajuster HMM K = 2, 3, 4, calculer les diagnostics | Analyse réelle reproductible | Figures et interprétation écologique prudente |
| 6 | Rédiger le manuscrit | Écrire méthodes, théorie, simulations, application, introduction, discussion, supplément | Version 0.1 du manuscrit | Manuscrit cohérent avec preuves, figures et bibliographie |
| 7 | Vérifier avant soumission | Audit reproductibilité, relecture statistique, relecture écologique, nettoyage du dépôt | Dépôt et manuscrit prêts | Nouvelle installation capable de reproduire les résultats |

## Phase 0 : structuration du dépôt

Statut : complétée.

Objectif : disposer d'un dépôt privé propre, versionné et prêt pour un travail reproductible.

Tâches :

- Créer l'arborescence du projet.
- Conserver le plan initial comme note source.
- Rédiger le README du projet.
- Ajouter la bibliographie initiale.
- Créer les dossiers pour le code R, les simulations, l'application réelle, les résultats et le manuscrit.
- Ignorer les données brutes, les données traitées et les résultats générés par défaut.

Livrables :

- `README.md`
- `PLAN_DE_TRAVAIL.md`
- `docs/PLAN_PAR_PHASE.md`
- `docs/BIBLIOGRAPHIE_DE_DEPART.md`
- `paper/references.bib`
- Arborescence complète du dépôt

Critère de réussite :

- Le dépôt est disponible sur GitHub en privé.
- La branche principale est propre.
- Les données sensibles ne peuvent pas être ajoutées accidentellement sans modification explicite de `.gitignore`.

## Phase 1 : stabilisation théorique

Statut : première version complétée.

Objectif : produire une note théorique courte qui fixe la base statistique du projet.

Tâches :

- Fixer les notations `Y_t`, `S_t`, `p_0`, `p_1`, `E_t`, `E_{1:t}` et `\mathcal F_t`.
- Définir clairement la trajectoire observée et les états latents.
- Écrire la densité prédictive observable du HMM avec marginalisation des états latents par filtrage.
- Énoncer le théorème principal pour le cas train/test avec modèles fixés avant validation.
- Démontrer que le ratio de densités prédictives est une e-value conditionnelle.
- Déduire que le produit cumulatif est un e-process.
- Ajouter la remarque sur les paramètres estimés : validité conditionnelle au jeu d'entraînement, prudence si les mêmes données servent à estimer et diagnostiquer.
- Clarifier que les états Viterbi peuvent aider l'interprétation, mais ne fondent pas la validité.

Livrables :

- `paper/theory_note_phase1.tex`, rédigé en anglais dans un style proche d'un article
- Note théorique de 6 pages compilée localement dans `manuscript_outputs/theory_note_phase1.pdf`
- Table de notation
- Théorème principal et preuve préliminaire
- Proposition sur la validité par filtrage
- Paragraphe sur les paramètres estimés

Critère de réussite :

- La notation est stable.
- La preuve du cas train/test est complète.
- Les limites des garanties anytime-valid sont explicitement écrites.

## Phase 2 : prototype R minimal

Objectif : obtenir une preuve de concept computationnelle avec paramètres connus.

Tâches :

- Simuler un HMM simple à deux états.
- Générer des observations de type longueur de pas et angle de virage, ou commencer avec un flux univarié simplifié si nécessaire.
- Calculer les probabilités prédictives par forward filtering.
- Calculer les log densités prédictives sous `M_0` et `M_1`.
- Calculer les incréments `log e_t` et les cumulés `log E_{1:t}`.
- Tracer une première courbe avec le seuil `log(1 / alpha)`.
- Vérifier le comportement sous le nul avec plusieurs trajectoires simulées.

Livrables :

- Fonction de simulation HMM minimale.
- Fonctions `hmm_forward_filter()`, `hmm_predictive_log_density()` et `compute_eprocess()` vérifiées.
- Script de démonstration reproductible.
- Figure prototype de `log E_{1:t}`.

Critère de réussite :

- Une nouvelle session R peut reproduire l'exemple minimal.
- Les densités prédictives utilisent les probabilités filtrées et non les états décodés.
- Le franchissement du seuil reste rare sous le nul dans une simulation simple.

## Phase 3 : diagnostics ciblés

Objectif : transformer le prototype en cadre diagnostique modulaire.

Ordre recommandé :

1. Diagnostic `K` contre `K+1`.
2. Diagnostic angulaire.
3. Diagnostic dépendance longueur-angle.
4. Diagnostic de durée.

Tâches :

- Définir pour chaque diagnostic un modèle nul, une alternative et une interprétation écologique.
- Écrire une fonction qui retourne les log densités prédictives sous `M_0` et `M_1`.
- Retourner systématiquement l'objet e-process, le seuil, le temps de franchissement et un indicateur de signal.
- Documenter les cas où le diagnostic est confirmatoire et les cas où il est exploratoire.
- Garder le diagnostic longueur-angle comme contribution méthodologique centrale du premier manuscrit.

Livrables :

- Fonction pour le diagnostic du nombre d'états.
- Fonction pour le diagnostic angulaire.
- Fonction pour le diagnostic longueur-angle.
- Fonction ou prototype pour le diagnostic de durée.
- Documentation courte de chaque diagnostic.

Critère de réussite :

- Chaque diagnostic produit un e-process interprétable.
- Les sorties ont une structure commune.
- Les diagnostics ne reposent pas sur les états Viterbi pour la validité.

## Phase 4 : simulations principales

Objectif : évaluer la calibration, la puissance, la spécificité et la localisation des diagnostics.

Scénarios :

| Scénario | Question | Résultat attendu |
|---|---|---|
| S1 : nul correct | Le taux de faux signal est-il contrôlé ? | Franchissements compatibles avec `alpha` |
| S2 : état manquant | Le diagnostic `K+1` détecte-t-il un état manquant ? | Accumulation d'évidence sous modèle sous-ajusté |
| S3 : angles mal spécifiés | Le diagnostic angulaire est-il spécifique ? | Signal surtout sur le diagnostic angulaire |
| S4 : dépendance longueur-angle | La dépendance invisible aux marges est-elle détectée ? | Signal clair du diagnostic de dépendance |
| S5 : durées non géométriques | Le HMM standard échoue-t-il sur les durées ? | Signal du diagnostic de durée |
| S6 : échec localisé | Les incréments localisent-ils le défaut ? | Incréments élevés après le changement |

Mesures à rapporter :

- Taux de faux signal.
- Puissance.
- Temps moyen de franchissement du seuil.
- Distribution de `sup_t E_{1:t}` ou de `sup_t log E_{1:t}`.
- Pente moyenne de `log E_{1:t}` sous alternative.
- Diagnostic dominant.
- Qualité de localisation de l'échec.

Livrables :

- Six scripts de simulation.
- Un script `run_all_simulations.R`.
- Tables dans `results/simulation_tables/`.
- Figures dans `results/simulation_figures/`.
- Court rapport de simulation.

Critère de réussite :

- Les simulations sont reproductibles.
- Chaque scénario génère au minimum une table et une figure.
- Les résultats soutiennent directement les claims du manuscrit.

## Phase 5 : application réelle

Objectif : démontrer l'utilité du cadre sur un jeu de données de mouvement réel, public et reproductible.

Tâches :

- Identifier des jeux de données candidats dans les écosystèmes `moveHMM` et `momentuHMM`.
- Documenter la source, la licence, les variables disponibles, le nombre d'individus et la qualité temporelle.
- Choisir un jeu simple plutôt qu'une application trop complexe.
- Prétraiter les trajectoires.
- Construire les longueurs de pas et angles de virage.
- Ajuster des HMM avec `K = 2`, `K = 3` et `K = 4`.
- Choisir un modèle courant `M_0` avec une justification prudente.
- Calculer les diagnostics développés en Phase 3.
- Produire les figures d'application.
- Rédiger l'interprétation écologique sans surinterpréter les états décodés.

Livrables :

- Fiche de sélection du jeu de données.
- Scripts `application/01_preprocess.R` à `application/04_figures_application.R` complétés.
- Figures dans `results/application_figures/`.
- Section application du manuscrit.

Critère de réussite :

- L'analyse peut être reproduite depuis les scripts.
- Les données sont légalement utilisables et documentées.
- L'interprétation distingue clairement diagnostic exploratoire et conclusion confirmatoire.

## Phase 6 : rédaction du manuscrit

Objectif : produire une version 0.1 complète du manuscrit et du supplément.

Ordre recommandé :

1. Méthodes.
2. Théorie.
3. Simulations.
4. Application.
5. Introduction.
6. Discussion.
7. Résumé.
8. Supplément.

Tâches :

- Rédiger le cadre HMM et les densités prédictives.
- Insérer le théorème principal et les propositions.
- Décrire les diagnostics mouvement-spécifiques.
- Présenter le design de simulation et les résultats.
- Présenter l'application réelle.
- Écrire une discussion proportionnée : portée, limites, paramètres estimés, extensions HMM-SSF et package R futur.
- Préparer le supplément avec preuves détaillées, détails algorithmiques et résultats additionnels.

Livrables :

- `paper/main.tex` complété.
- `paper/supplement.tex` complété.
- Figures et tables intégrées.
- Bibliographie cohérente.

Critère de réussite :

- Le manuscrit compile.
- Les claims sont appuyés par une preuve, une simulation ou une référence.
- Les limites sont explicites.

## Phase 7 : vérification avant soumission

Objectif : vérifier la reproductibilité, la validité statistique et la cohérence éditoriale avant soumission.

Tâches :

- Relancer tous les scripts depuis une session R propre.
- Vérifier que les tables et figures du manuscrit sont régénérables.
- Auditer les dépendances R.
- Vérifier que les données sensibles ne sont pas suivies par Git.
- Relire les preuves.
- Relire les simulations et leurs conclusions.
- Relire l'interprétation écologique.
- Nettoyer les fichiers temporaires.
- Préparer une archive ou une version reproductible du dépôt.

Livrables :

- Rapport d'audit interne.
- Manuscrit prêt pour soumission.
- Supplément prêt.
- Dépôt propre et reproductible.

Critère de réussite :

- Une nouvelle installation peut reproduire les résultats principaux.
- Les figures et tables correspondent au manuscrit.
- Les conclusions restent proportionnées aux résultats.

## Tests et scénarios de validation

| Test | Phase | Résultat attendu |
|---|---|---|
| Test R minimal | 2 | `compute_eprocess()` retourne les incréments, cumulés, seuil et temps de franchissement |
| Filtrage HMM | 2 | Les densités prédictives utilisent les probabilités filtrées, pas les états Viterbi |
| Nul correct | 4 | Le taux de faux signal reste contrôlé pour `alpha = 0.10`, `0.05`, `0.01` |
| État manquant | 4 | Le diagnostic `K+1` accumule de l'évidence contre le modèle sous-ajusté |
| Angles mal spécifiés | 4 | Le diagnostic angulaire réagit davantage que les diagnostics marginaux non concernés |
| Dépendance longueur-angle | 4 | Le diagnostic détecte une dépendance conditionnelle invisible aux marges |
| Durées non géométriques | 4 | Le diagnostic de durée détecte une mémoire incompatible avec le HMM standard |
| Échec localisé | 4 | Les incréments `log e_t` identifient la période problématique |
| Application réelle | 5 | Les résultats sont reproductibles et interprétés prudemment |
| Audit final | 7 | Le dépôt permet de reconstruire les résultats principaux |

## Hypothèses et choix par défaut

- Le premier manuscrit vise un style JABES par défaut.
- Le projet reste centré sur les HMM simples, pas sur les HMM-SSF complets.
- La garantie statistique principale est formulée avec séparation train/test ou validation par individus.
- Les états latents sont intégrés par filtrage dans les densités prédictives.
- Les états décodés peuvent servir à l'interprétation, mais pas à établir la validité de l'e-process.
- Le code reste sous forme de scripts R pour la première version.
- La transformation en package R est une décision ultérieure.
- Le jeu de données réel n'est pas encore identifié. Je ne sais pas.
- Si aucun jeu de données idéal n'est trouvé, utiliser un jeu public simple et reproductible plutôt qu'une application trop complexe.

## Prochaine action concrète

Commencer la Phase 2 en construisant un prototype R minimal qui simule un HMM simple, calcule les densités prédictives par filtrage et produit un premier e-process sous le nul.
