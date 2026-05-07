# Plan de travail complet

## Projet

**Titre provisoire**

*Predictive e-diagnostics for multi-state animal movement models*

ou

*Anytime-valid exploratory diagnostics for multi-state animal movement models*

## Objectif général

Développer un cadre théorique et méthodologique pour valider des modèles multi-états de mouvement animalier, en particulier les HMM, à l’aide d’e-values et d’e-process prédictifs.

L’objectif n’est pas seulement d’appliquer la théorie moderne des e-values aux HMM. Le projet vise à proposer une nouvelle façon de formaliser la validation exploratoire des modèles de mouvement comme une suite de diagnostics adaptatifs statistiquement contrôlés.

---

# 1. Positionnement scientifique du projet

## 1.1 Problème de départ

Les modèles de mouvement animalier, notamment les HMM, sont souvent évalués par :

- AIC/BIC;
- vraisemblance;
- diagnostics graphiques;
- simulations de trajectoires;
- comparaison des distributions de longueurs de pas et d’angles;
- validation écologique qualitative;
- inspection des états décodés.

Ces pratiques ont plusieurs limites :

- elles ne contrôlent pas vraiment l’exploration adaptative;
- les diagnostics sont souvent choisis après avoir vu les données;
- une bonne vraisemblance locale ne garantit pas une bonne capacité générative;
- les états latents sont parfois traités comme observés après décodage;
- les défauts du modèle sont rarement localisés dans le temps, par individu, par habitat ou par état.

## 1.2 Idée centrale

Transformer les diagnostics de modèles de mouvement en paris prédictifs valides contre le modèle courant.

Au lieu de demander seulement :

```math
\text{Le HMM a-t-il un bon AIC ?}
```

on demande :

```math
\text{Le HMM reste-t-il crédible comme générateur séquentiel de la trajectoire observée ?}
```

À chaque temps `t`, on compare la prédiction du HMM courant à celle d’une alternative diagnostique :

```math
E_t = \frac{p_1(y_t \mid y_{1:t-1})}{p_0(y_t \mid y_{1:t-1})}.
```

Puis on accumule :

```math
E_{1:T} = \prod_{t=1}^T E_t.
```

Si `E_{1:T}` devient grand, cela indique une évidence cumulative contre le modèle.

## 1.3 Contribution visée

L’article devrait revendiquer cinq contributions principales :

1. Formaliser la validation des HMM de mouvement comme un problème de prédiction séquentielle.
2. Définir des e-process prédictifs pour les HMM avec états latents intégrés par filtrage.
3. Introduire une méthode de diagnostic qui localise la mauvaise spécification dans le temps, par individu, par habitat ou par type de comportement.
4. Proposer une formalisation de l’EDA des modèles de mouvement comme une suite de diagnostics adaptatifs contrôlés.
5. Développer des diagnostics propres au mouvement animalier : nombre d’états, distribution angulaire, dépendance longueur-angle, durées d’état, diagnostics génératifs de trajectoires.

---

# 2. Décision de cadrage initial

## 2.1 Ce que le premier article doit faire

Le premier article devrait se concentrer sur :

- HMM multi-états simples;
- observations de type longueur de pas et angle de virage;
- validation train/test ou par individu;
- e-process prédictifs;
- diagnostics ciblés;
- simulations contrôlées;
- une application réelle.

## 2.2 Ce qu’il ne faut pas mettre au centre au départ

Pour éviter que le projet devienne trop large, il ne faut pas mettre au centre du premier papier :

- HMM-SSF complet;
- SSF/iSSA généralisé;
- normalizing flows;
- théorie complète des hypothèses composites;
- estimation et validation sur les mêmes données sans précaution;
- alternatives adaptatives totalement libres;
- application massive multi-espèces;
- preuve générale pour tous les modèles latents.

Ces éléments pourront apparaître en discussion ou dans un second article.

---

# 3. Structure théorique à développer

## 3.1 Définir le cadre HMM

On considère une trajectoire observée :

```math
Y_1,\ldots,Y_T,
```

où :

```math
Y_t = (\ell_t,\theta_t),
```

avec :

```math
\ell_t = \text{longueur de pas},
```

```math
\theta_t = \text{angle de virage}.
```

Les états latents sont :

```math
S_t \in \{1,\ldots,K\}.
```

Le HMM courant `M_0` est défini par :

- une distribution initiale;
- une matrice de transition;
- des distributions d’observation conditionnelles aux états;
- éventuellement des covariables.

Typiquement :

```math
\ell_t \mid S_t=s \sim \text{Gamma}(\cdot),
```

```math
\theta_t \mid S_t=s \sim \text{von Mises}(\cdot).
```

## 3.2 Définir la densité prédictive observable

Point crucial : il ne faut pas conditionner sur les états décodés.

On doit utiliser :

```math
p_0(y_t \mid y_{1:t-1})
=
\sum_{s=1}^K
p_0(y_t \mid S_t=s)
\Pr_0(S_t=s \mid y_{1:t-1}).
```

La probabilité d’état doit être filtrée, pas simplement décodée.

À discuter :

- filtrage avant observation `y_t`;
- différence entre filtrage et lissage;
- pourquoi Viterbi n’est pas une base valide pour construire l’e-value;
- utilisation possible de Viterbi seulement comme outil interprétatif après coup.

## 3.3 Théorème principal

Théorème à démontrer :

Soit `M_0` un HMM définissant une densité prédictive `p_0(y_t | y_{1:t-1})`. Supposons qu’à chaque temps `t`, une densité alternative `p_t^1(y_t | y_{1:t-1})` est choisie avant d’observer `y_t`. On définit :

```math
E_t =
\frac{p_t^1(y_t \mid y_{1:t-1})}
{p_0(y_t \mid y_{1:t-1})}.
```

Alors, sous `M_0`,

```math
\mathbb E_0(E_t \mid \mathcal F_{t-1}) = 1.
```

Donc :

```math
E_{1:T} = \prod_{t=1}^T E_t
```

est un e-process.

Par conséquent :

```math
\mathbb P_0
\left(
\sup_T E_{1:T} \geq \frac{1}{\alpha}
\right)
\leq \alpha.
```

Interprétation : on peut surveiller l’évidence contre le modèle au fil du temps et arrêter l’analyse sans perdre le contrôle d’erreur.

## 3.4 Proposition sur les états latents

Proposition : la validité repose sur la prédiction marginale observable, pas sur les états décodés.

À inclure :

```math
p_0(y_t \mid y_{1:t-1})
=
\sum_s
p_0(y_t \mid S_t=s)
\Pr_0(S_t=s \mid y_{1:t-1}).
```

Message :

- utiliser les probabilités filtrées est valide;
- utiliser `\hat S_t` comme si l’état était observé peut briser la validité;
- les diagnostics par état peuvent être produits après coup, mais doivent être interprétés comme descriptifs.

## 3.5 Proposition sur la croissance sous alternative

Proposition : si les données viennent d’un processus `P^\star` et que :

```math
\mathbb E_{P^\star}
\left[
\log
\frac{p_1(Y_t \mid Y_{1:t-1})}
{p_0(Y_t \mid Y_{1:t-1})}
\right]
> 0,
```

alors :

```math
\log E_{1:T}
=
\sum_{t=1}^T \log E_t
```

tend à croître avec `T`.

Interprétation :

- si l’alternative cible bien le défaut du HMM, l’évidence s’accumule;
- sinon, l’e-process peut rester peu sensible;
- la méthode dépend du pari diagnostique choisi.

## 3.6 Théorème ou proposition sur l’EDA adaptative

Formuler une version plus générale :

À chaque étape `j`, l’analyste choisit un diagnostic `D_j` en fonction de ce qui a déjà été vu. Si chaque diagnostic produit une e-value `E_j` telle que :

```math
\mathbb E_0(E_j \mid \mathcal G_{j-1}) \leq 1,
```

alors :

```math
E_{\text{global},m} = \prod_{j=1}^m E_j
```

reste une e-value valide.

Message : la validation exploratoire peut être vue comme une suite de paris diagnostiques conditionnellement valides.

---

# 4. Méthode principale à développer

## 4.1 Nom possible de la méthode

Options :

- Predictive e-diagnostics;
- Movement e-diagnostics;
- HMM e-diagnostics;
- Sequential e-validation;
- Anytime-valid movement diagnostics;
- e-EDA for animal movement models.

Choix recommandé :

**Predictive e-diagnostics for multi-state movement models**

## 4.2 Algorithme général

Entrée :

- une trajectoire;
- un HMM ajusté `M_0`;
- une ou plusieurs alternatives diagnostiques `M_1^{(j)}`;
- un niveau `\alpha`;
- un choix de validation : train/test, par individu ou validation temporelle.

Étapes :

1. Ajuster le HMM nul `M_0`.
2. Ajuster ou définir les alternatives diagnostiques `M_1^{(j)}`.
3. Sur les données de validation, calculer pour chaque temps `t` :

```math
\log e_t^{(j)}
=
\log p_1^{(j)}(y_t \mid y_{1:t-1})
-
\log p_0(y_t \mid y_{1:t-1}).
```

4. Accumuler :

```math
\log E_{1:t}^{(j)}
=
\sum_{u=1}^t \log e_u^{(j)}.
```

5. Comparer au seuil :

```math
\log(1/\alpha).
```

Pour `\alpha = 0.05` :

```math
\log(1/\alpha) = \log(20) \approx 2.996.
```

6. Produire les graphiques :

- courbe `\log E_{1:t}` dans le temps;
- contributions locales `\log e_t`;
- contributions par individu;
- contributions par habitat;
- contributions par état probabiliste;
- contributions par saison ou période biologique.

7. Interpréter :

- pas seulement “rejet / non rejet”;
- mais “où, quand et pourquoi le modèle échoue”.

---

# 5. Diagnostics à développer

## 5.1 Diagnostic 1 : nombre d’états insuffisant

Modèle nul :

```math
M_0 = \text{HMM à } K \text{ états}.
```

Alternative :

```math
M_1 = \text{HMM à } K+1 \text{ états}.
```

Objectif : détecter si un état supplémentaire prédit mieux certains segments de trajectoire.

À analyser :

- l’e-process augmente-t-il partout ?
- seulement pendant certaines périodes ?
- seulement chez certains individus ?
- seulement dans certains habitats ?

## 5.2 Diagnostic 2 : mauvaise distribution angulaire

Modèle nul :

```math
\theta_t \mid S_t=s \sim \text{von Mises}(\mu_s,\kappa_s).
```

Alternative :

```math
\theta_t \mid S_t=s \sim \text{mélange de von Mises}.
```

Objectif : détecter :

- angles multimodaux;
- asymétrie;
- mauvaise concentration;
- virages trop directionnels ou trop tortueux.

## 5.3 Diagnostic 3 : dépendance longueur-angle

Modèle nul :

```math
p(\ell_t,\theta_t \mid S_t=s)
=
p(\ell_t \mid S_t=s)
p(\theta_t \mid S_t=s).
```

Alternative :

```math
p(\ell_t,\theta_t \mid S_t=s)
=
c_s\{F_\ell(\ell_t),F_\theta(\theta_t);\rho_s\}
p(\ell_t \mid S_t=s)
p(\theta_t \mid S_t=s).
```

Objectif : tester si, même après conditionnement sur l’état, la longueur de pas et l’angle de virage restent dépendants.

Question écologique : l’animal tourne-t-il différemment lorsqu’il fait de longs déplacements ?

Ce diagnostic est probablement le plus distinctif du projet.

## 5.4 Diagnostic 4 : HMM versus HSMM

Modèle nul :

```math
M_0 = \text{HMM}.
```

Alternative :

```math
M_1 = \text{HSMM}.
```

Objectif : détecter des durées comportementales non géométriques.

Question écologique : les états comportementaux ont-ils une mémoire de durée que le HMM standard ne peut pas reproduire ?

## 5.5 Diagnostic 5 : non-stationnarité temporelle

Modèle nul : paramètres constants dans le temps.

Alternative : paramètres variant selon :

- saison;
- période de migration;
- température;
- jour/nuit;
- période de reproduction;
- phase de déplacement.

Objectif : détecter quand le modèle cesse de bien prédire.

## 5.6 Diagnostic 6 : hétérogénéité individuelle

Modèle nul : même structure pour tous les individus.

Alternative : effets individuels ou paramètres par individu.

Objectif : voir si le modèle échoue seulement pour certains animaux.

## 5.7 Diagnostic 7 : validation générative à long terme

Diagnostics possibles :

- utilization distribution;
- mean squared displacement;
- straightness index;
- barrier crossing;
- temps de retour;
- résidence;
- fragmentation spatiale;
- corridors.

Objectif : relier ce papier à un cadre plus large de validation générative.

À mettre possiblement dans une section secondaire ou en discussion, pour ne pas trop élargir le premier article.

---

# 6. Simulations à planifier

## 6.1 Objectifs des simulations

Les simulations doivent démontrer quatre choses :

1. Sous le modèle nul correct, l’e-process reste contrôlé.
2. Sous mauvaise spécification, l’e-process détecte l’échec.
3. Le diagnostic identifie le bon type d’échec.
4. La méthode localise où l’échec se produit.

## 6.2 Simulation 1 : contrôle sous le nul

Données simulées sous un HMM à 2 états.

Ajuster le bon modèle.

Calculer les e-process pour différentes alternatives.

Attendu :

```math
\mathbb P_0
\left(
\sup_T E_{1:T} \geq 1/\alpha
\right)
\leq \alpha.
```

À produire :

- taux de faux signal pour `\alpha = 0.10, 0.05, 0.01`;
- distribution de `\sup_T E_{1:T}`;
- courbes typiques de `\log E_{1:t}`.

## 6.3 Simulation 2 : nombre d’états insuffisant

Données simulées sous HMM à 3 états.

Modèle nul ajusté :

```math
K=2.
```

Alternative :

```math
K=3.
```

Attendu :

- l’e-process `K+1` augmente;
- détection plus rapide quand le troisième état est fréquent;
- détection plus difficile si le troisième état ressemble aux deux autres.

Facteurs à varier :

- séparation entre états;
- fréquence du troisième état;
- longueur de trajectoire;
- nombre d’individus.

## 6.4 Simulation 3 : mauvaise distribution angulaire

Données simulées avec angles multimodaux ou mélange de von Mises.

Modèle nul : von Mises simple par état.

Alternative : mélange de von Mises.

Attendu :

- e-process angulaire augmente;
- diagnostics step-length ne devraient pas forcément augmenter;
- localisation dans les états concernés.

## 6.5 Simulation 4 : dépendance longueur-angle

Données simulées avec dépendance conditionnelle entre `\ell_t` et `\theta_t`.

Modèle nul : indépendance conditionnelle.

Alternative : copule circulaire-linéaire ou dépendance paramétrique simple.

Attendu :

- e-process copule augmente;
- les marges peuvent sembler correctes;
- le défaut est invisible ou moins visible avec des diagnostics marginaux.

Cette simulation est importante, car elle montre l’intérêt d’aller au-delà des diagnostics classiques.

## 6.6 Simulation 5 : durées non géométriques

Données simulées sous HSMM.

Modèle nul : HMM standard.

Alternative : HSMM ou approximation de durée.

Attendu :

- e-process durée augmente;
- défaut surtout visible dans les séquences d’états;
- lien avec comportement écologique prolongé.

## 6.7 Simulation 6 : échec localisé

Données simulées avec un changement au milieu de la trajectoire.

Exemple :

- première moitié : HMM correct;
- deuxième moitié : dépendance longueur-angle;
- ou changement de concentration angulaire;
- ou transition différente.

Attendu :

- `\log E_{1:t}` reste stable au début;
- puis augmente après le point de changement;
- les contributions `\log e_t` localisent la période problématique.

## 6.8 Mesures à rapporter

Pour chaque scénario :

- taux de faux signal;
- puissance;
- temps moyen jusqu’au franchissement du seuil;
- aire ou pente moyenne de `\log E_{1:t}`;
- diagnostic dominant;
- localisation correcte de l’échec;
- robustesse à la longueur de trajectoire;
- robustesse au nombre d’individus.

---

# 7. Application réelle

## 7.1 Choix de l’application

Il faut une application claire, pas trop complexe, avec données reproductibles.

Options possibles :

1. Données déjà utilisées dans `moveHMM`.
2. Données publiques de mouvement animalier avec trajectoires GPS.
3. Données issues d’un article ou package existant.
4. Données liées à des projets actuels si elles sont disponibles et partageables.

Le meilleur choix serait une application où :

- les HMM sont naturellement pertinents;
- les états comportementaux ont une interprétation claire;
- les longueurs de pas et angles sont disponibles;
- il y a plusieurs individus;
- les diagnostics peuvent révéler quelque chose d’écologique.

## 7.2 Analyse à faire

1. Prétraitement des trajectoires.
2. Construction des pas :

```math
\ell_t, \theta_t.
```

3. Ajustement de HMM avec `K=2,3,4`.
4. Choix d’un modèle courant `M_0`.
5. Construction des diagnostics :

- `K` versus `K+1`;
- von Mises versus mélange de von Mises;
- indépendance longueur-angle versus dépendance;
- HMM versus diagnostic de durée;
- éventuellement diagnostic spatial.

6. Calcul des e-process.
7. Visualisations :

- trajectoire;
- états filtrés;
- `\log E_{1:t}`;
- seuil `\log(1/\alpha)`;
- contributions locales;
- contributions par individu;
- contributions par habitat ou période.

8. Interprétation écologique.

## 7.3 Ce qu’il faut éviter dans l’application

- ne pas surinterpréter les états;
- ne pas dire que l’e-process “prouve” que le modèle est faux;
- ne pas présenter l’application comme confirmatoire si elle est exploratoire;
- ne pas utiliser les mêmes données pour tout ajuster et tester sans discussion;
- ne pas multiplier les diagnostics sans expliquer la logique e-value.

---

# 8. Code et implémentation

## 8.1 Structure de dépôt recommandée

```text
predictive-e-diagnostics-hmm/
├── README.md
├── paper/
│   ├── main.tex
│   ├── supplement.tex
│   ├── references.bib
│   └── figures/
├── R/
│   ├── hmm_forward_filter.R
│   ├── predictive_density_hmm.R
│   ├── eprocess.R
│   ├── diagnostics_states.R
│   ├── diagnostics_angles.R
│   ├── diagnostics_copula.R
│   ├── diagnostics_duration.R
│   ├── plotting.R
│   └── utilities.R
├── simulations/
│   ├── 01_null_control.R
│   ├── 02_underfit_states.R
│   ├── 03_angle_misspecification.R
│   ├── 04_step_angle_dependence.R
│   ├── 05_duration_misspecification.R
│   ├── 06_local_failure.R
│   └── run_all_simulations.R
├── application/
│   ├── data_raw/
│   ├── data_processed/
│   ├── 01_preprocess.R
│   ├── 02_fit_hmm.R
│   ├── 03_compute_eprocess.R
│   └── 04_figures_application.R
├── results/
│   ├── simulation_tables/
│   ├── simulation_figures/
│   └── application_figures/
├── manuscript_outputs/
│   ├── main.pdf
│   └── supplement.pdf
└── renv.lock
```

## 8.2 Fonctions essentielles

### Filtrage HMM

Fonction :

```r
hmm_filter()
```

But :

- calculer les probabilités filtrées;
- calculer la densité prédictive;
- éviter d’utiliser les états Viterbi.

Sorties :

- `filtered_probs`;
- `predictive_density`;
- `log_predictive_density`.

### E-process

Fonction :

```r
compute_eprocess()
```

Entrées :

- `log_p0`;
- `log_p1`;
- `alpha`.

Sorties :

- `log_e_increment`;
- `log_e_cumulative`;
- `threshold`;
- `crossing_time`;
- `signal`.

### Diagnostic nombre d’états

Fonction :

```r
diagnostic_extra_state()
```

Entrées :

- modèle `K`;
- modèle `K+1`;
- validation data.

Sortie :

- e-process `K+1` contre `K`.

### Diagnostic angulaire

Fonction :

```r
diagnostic_angle()
```

Comparer :

- von Mises;
- mélange de von Mises;
- ou alternative flexible.

### Diagnostic longueur-angle

Fonction :

```r
diagnostic_step_angle_dependence()
```

Comparer :

- indépendance conditionnelle;
- dépendance copule ou alternative paramétrique.

### Diagnostic durée

Fonction :

```r
diagnostic_duration()
```

Comparer :

- HMM;
- HSMM ou approximation de durée.

## 8.3 Figures standard à générer

Chaque simulation et application devrait produire :

1. Courbe `\log E_{1:t}` avec seuil.
2. Incréments `\log e_t`.
3. Contributions par individu.
4. Contributions par état filtré.
5. Comparaison entre diagnostics.
6. Trajectoires observées et simulées.
7. Figure conceptuelle du workflow.

---

# 9. Plan de l’article

## Abstract

À faire ressortir :

- HMM largement utilisés en mouvement animalier;
- diagnostics actuels souvent exploratoires et non contrôlés;
- proposition : predictive e-diagnostics;
- validité anytime par e-process;
- intégration des états latents par filtrage;
- simulations;
- application réelle;
- valeur écologique : localiser les échecs génératifs.

## 1. Introduction

Structure :

1. Importance des HMM en écologie du mouvement.
2. Limites des diagnostics actuels.
3. Problème de l’exploration adaptative.
4. Intérêt des e-values et e-process.
5. Gap : pas de cadre e-value dédié aux HMM de mouvement.
6. Contributions du papier.

## 2. Background

Sections possibles :

- 2.1 Multi-state movement models
- 2.2 Predictive distributions in HMMs
- 2.3 E-values and e-processes
- 2.4 Exploratory diagnostics and model validation

## 3. Predictive e-diagnostics

Sections :

- 3.1 HMM as a sequential generator
- 3.2 Predictive e-values
- 3.3 Latent-state filtering
- 3.4 Anytime-valid diagnostic monitoring
- 3.5 Adaptive diagnostic workflows
- 3.6 Localizing model failure

## 4. Movement-specific diagnostics

Sections :

- 4.1 Number of states
- 4.2 Angular distribution
- 4.3 Step length and turning angle dependence
- 4.4 State-duration misspecification
- 4.5 Long-term generative diagnostics

## 5. Simulation study

Sections :

- 5.1 Design
- 5.2 Null calibration
- 5.3 Underfitted states
- 5.4 Angular misspecification
- 5.5 Step-angle dependence
- 5.6 Duration misspecification
- 5.7 Localized failure
- 5.8 Summary of simulation findings

## 6. Application

Sections :

- 6.1 Data
- 6.2 Fitted HMM
- 6.3 Predictive e-diagnostics
- 6.4 Localizing failures
- 6.5 Ecological interpretation

## 7. Discussion

À inclure :

- ce que la méthode apporte;
- limites;
- paramètres estimés;
- train/test versus même trajectoire;
- états latents;
- extensions HMM-SSF;
- extensions SSF/iSSA;
- visual inference;
- prediction-powered e-values;
- package R futur.

## Supplement

À mettre en supplément :

- preuves détaillées;
- détails algorithmiques;
- simulations additionnelles;
- robustesse;
- détails de calcul;
- tables complètes.

---

# 10. Résultats théoriques à écrire proprement

## Théorème 1

Predictive e-process for HMMs.

## Proposition 1

Filtering-based validity under latent states.

## Proposition 2

Growth under misspecification.

## Proposition 3

Adaptive diagnostic combination.

## Corollaire possible

Seuil anytime-valid :

```math
\mathbb P_0
\left(
\exists t : E_{1:t} \geq 1/\alpha
\right)
\leq \alpha.
```

## Remarque importante

Ajouter une remarque sur les paramètres estimés :

- exact si modèle fixé avant validation;
- conditionnel au jeu d’entraînement;
- approximatif ou nécessitant précautions si même jeu de données.

---

# 11. Stratégie de validation statistique

## 11.1 Version exacte

Utiliser séparation train/test :

```math
\text{train} : \text{ajustement},
```

```math
\text{test} : \text{e-process}.
```

Avantage :

- preuve simple;
- reviewers rassurés.

## 11.2 Version multi-individus

Train sur certains animaux, test sur d’autres.

Avantage :

- très écologique;
- bon test de généralisation;
- évite la dépendance directe entre estimation et validation.

## 11.3 Version exploratoire

Même trajectoire, diagnostics adaptatifs.

À présenter avec prudence :

- utile;
- plus proche de la pratique;
- garanties plus délicates;
- à encadrer par split, cross-fitting ou validation conditionnelle.

---

# 12. Questions à résoudre pendant le projet

## Question 1

Quelle alternative `M_1` utiliser pour chaque diagnostic ?

Il faut choisir des alternatives simples, interprétables et calculables.

## Question 2

Comment éviter que `M_1` soit juste “plus gros donc toujours meilleur” ?

Réponses possibles :

- validation sur données séparées;
- complexité contrôlée;
- alternatives ciblées;
- interprétation diagnostique plutôt que sélection automatique.

## Question 3

Comment calculer `p_1(y_t | y_{1:t-1})` efficacement ?

Il faudra développer :

- forward algorithm;
- calculs sur l’échelle logarithmique;
- gestion des zéros numériques;
- stabilité.

## Question 4

Comment traiter les paramètres estimés ?

Réponse recommandée :

- commencer avec train/test;
- mentionner que la garantie est conditionnelle au train;
- discuter cross-fitting comme extension.

## Question 5

Comment combiner plusieurs diagnostics ?

Options :

- produit simple;
- produit pondéré;
- mixture e-value;
- correction par choix séquentiel;
- garder d’abord la version simple.

## Question 6

Comment éviter une interprétation trop binaire ?

Il faut présenter l’e-process comme :

- mesure d’évidence;
- outil de localisation;
- outil de comparaison diagnostique;
- pas seulement un test oui/non.

---

# 13. Figures à prévoir dans l’article

## Figure 1 : schéma conceptuel

Workflow :

1. données de mouvement;
2. ajustement HMM;
3. prédiction séquentielle;
4. alternatives diagnostiques;
5. e-process;
6. localisation de l’échec;
7. interprétation écologique.

## Figure 2 : illustration du HMM

Montrer :

- trajectoire;
- états latents;
- longueurs de pas;
- angles;
- densité prédictive.

## Figure 3 : comportement sous le nul

Courbes `\log E_{1:t}` sous modèle correct.

## Figure 4 : mauvaise spécification

Courbes qui franchissent le seuil.

## Figure 5 : diagnostics comparés

Plusieurs e-process sur le même scénario :

- `K+1`;
- angle;
- copule;
- durée.

## Figure 6 : localisation

Heatmap ou courbe montrant où les incréments `\log e_t` sont forts.

## Figure 7 : application réelle

Trajectoire + e-process + interprétation écologique.

---

# 14. Tables à prévoir

## Table 1 : notation

Inclure :

- `Y_t`;
- `\ell_t`;
- `\theta_t`;
- `S_t`;
- `p_0`;
- `p_1`;
- `E_t`;
- `E_{1:T}`;
- `\mathcal F_t`;
- `\alpha`.

## Table 2 : diagnostics proposés

Colonnes :

- diagnostic;
- modèle nul;
- alternative;
- défaut détecté;
- interprétation écologique.

## Table 3 : scénarios de simulation

Colonnes :

- scénario;
- modèle générateur;
- modèle nul;
- alternative;
- objectif.

## Table 4 : résultats de simulation

Colonnes :

- scénario;
- taux de faux signal;
- puissance;
- temps de détection;
- diagnostic dominant.

## Table 5 : application réelle

Colonnes :

- diagnostic;
- signal;
- crossing time;
- période concernée;
- interprétation.

---

# 15. Plan de développement en phases

## Phase 1 : cadrage théorique

Livrables :

- note de 5 à 8 pages;
- définition du cadre;
- théorème principal;
- preuve préliminaire;
- liste des diagnostics.

À faire :

1. écrire le modèle HMM;
2. écrire la densité prédictive;
3. formaliser l’e-process;
4. clarifier les états latents;
5. écrire le théorème principal;
6. décider des diagnostics du premier papier.

## Phase 2 : prototype R minimal

Livrables :

- code simulant un HMM à 2 états;
- code calculant `p_0(y_t | y_{1:t-1})`;
- code calculant `p_1/p_0`;
- premier graphique `\log E_{1:t}`.

À faire :

1. simuler HMM;
2. ajuster HMM ou utiliser paramètres connus;
3. calculer forward probabilities;
4. calculer densité prédictive;
5. calculer e-process;
6. vérifier sous nul.

Objectif : avoir une première preuve de concept.

## Phase 3 : simulations principales

Livrables :

- scripts complets;
- figures de simulation;
- tables de résultats;
- rapport de simulation.

Scénarios :

1. nul correct;
2. état manquant;
3. mauvaise distribution angulaire;
4. dépendance longueur-angle;
5. durée non géométrique;
6. échec localisé.

Objectif : montrer que la méthode fonctionne et qu’elle diagnostique correctement.

## Phase 4 : application réelle

Livrables :

- jeu de données propre;
- HMM ajusté;
- diagnostics calculés;
- figures finales;
- interprétation écologique.

À faire :

1. choisir le jeu de données;
2. prétraiter;
3. ajuster HMM;
4. calculer e-process;
5. localiser les défauts;
6. rédiger l’interprétation.

## Phase 5 : rédaction du manuscrit

Livrables :

- version 0.1 du manuscrit;
- supplément;
- figures propres;
- bibliographie.

Ordre recommandé :

1. Méthodes;
2. Théorie;
3. Simulations;
4. Application;
5. Introduction;
6. Discussion;
7. Abstract.

## Phase 6 : vérification avant soumission

Livrables :

- audit interne;
- relecture statistique;
- relecture écologique;
- code reproductible;
- dépôt GitHub ou archive.

Checklist :

- preuves correctes;
- simulations reproductibles;
- figures lisibles;
- application non surinterprétée;
- claims proportionnés;
- journal bien ciblé;
- format conforme.

---

# 16. Risques scientifiques et solutions

## Risque 1 : “Ce n’est qu’un ratio de vraisemblance”

Réponse : insister sur :

- validité anytime;
- diagnostic adaptatif;
- intégration des états latents;
- localisation de l’échec;
- diagnostics spécifiques mouvement.

## Risque 2 : “Les paramètres sont estimés”

Réponse : utiliser train/test ou validation par individu.

## Risque 3 : “Les alternatives sont arbitraires”

Réponse : les présenter comme diagnostics ciblés, pas comme modèles universels.

## Risque 4 : “Trop théorique pour les écologues”

Réponse : figures claires, interprétation écologique, application réelle, package R.

## Risque 5 : “Trop appliqué pour une revue statistique”

Réponse : théorème principal, propositions, simulations calibrées, preuves en supplément.

---

# 17. Ce qui rendrait le papier vraiment original

Le papier sera fort si ces quatre idées sont développées explicitement.

## Idée 1

Un HMM de mouvement doit être validé comme générateur séquentiel, pas seulement comme modèle ajusté.

## Idée 2

Les états latents doivent être intégrés par filtrage dans les diagnostics, pas traités comme observés.

## Idée 3

L’EDA des modèles de mouvement peut être formalisée comme une suite de paris diagnostiques valides.

## Idée 4

L’e-process permet non seulement de détecter une mauvaise spécification, mais aussi de la localiser écologiquement.

---

# 18. Journal cible

## Cible 1 : JABES

Meilleur équilibre théorie statistique et application écologique.

## Cible 2 : Methods in Ecology and Evolution

Si l’objectif est de viser les écologues du mouvement et d’insister sur l’outil pratique.

## Cible 3 : Biometrics

Si le papier devient plus général aux modèles multi-états latents en biosciences.

Recommandation actuelle : préparer le manuscrit avec un style JABES, puis ajuster selon la force finale de la théorie et de l’application.

---

# 19. Checklist complète

Avant d’écrire l’article, il faut avoir :

- question scientifique centrale;
- titre provisoire;
- notation fixée;
- théorème principal;
- preuve du théorème;
- choix des diagnostics;
- stratégie pour paramètres estimés;
- simulation sous le nul;
- simulation état manquant;
- simulation angle mal spécifié;
- simulation dépendance longueur-angle;
- simulation durée non géométrique;
- simulation échec localisé;
- jeu de données réel;
- code de filtrage;
- code de densité prédictive;
- code e-process;
- figures standards;
- tables standards;
- bibliographie e-values;
- bibliographie HMM mouvement;
- bibliographie diagnostics mouvement;
- discussion sur limites;
- discussion sur extensions HMM-SSF;
- dépôt reproductible.

---

# 20. Première tâche concrète à lancer

La toute première chose à faire serait de créer un prototype minimal avec paramètres connus.

1. Simuler un HMM à 2 états.
2. Calculer la densité prédictive exacte sous le vrai modèle.
3. Définir une alternative simple.
4. Calculer :

```math
\log E_{1:t}
=
\sum_{u=1}^t
\left[
\log p_1(y_u \mid y_{1:u-1})
-
\log p_0(y_u \mid y_{1:u-1})
\right].
```

5. Vérifier que sous le nul, le seuil est rarement franchi.
6. Vérifier que sous mauvaise spécification, la courbe augmente.

Si ce prototype fonctionne, le projet devient très concret.

---

# 21. Résumé du projet en une phrase

Le projet consiste à construire une théorie et une méthode de validation exploratoire contrôlée pour HMM de mouvement animalier, où chaque diagnostic devient un e-process prédictif permettant de détecter, combiner et localiser les échecs génératifs du modèle.
