# ⚽ Analyse et prédiction de l'affluence en Ligue 1

Projet de data science visant à **prédire l'affluence** (nombre de spectateurs) d'un match de Ligue 1 à partir d'informations connues **avant** la rencontre : équipes, niveau des clubs (Elo), forme récente, cotes des bookmakers, capacité du stade, date et horaire.

Réalisé en **R**

📄 **[Lire le rapport complet (PDF)](./rapport/Affluence_Ligue1.pdf)**

## 🎯 Objectif

Identifier les facteurs qui influencent la fréquentation des stades de Ligue 1, puis construire un modèle capable d'estimer l'affluence attendue d'un match. Un tel modèle peut servir à planifier les ressources d'un stade, adapter la stratégie tarifaire ou dimensionner les dispositifs d'accueil.

## 🗂️ Données

Deux jeux de données open source issus de **Kaggle**, couvrant de nombreuses ligues depuis les années 2000 :

- **Base « Match »** — [Club Football Match Data 2000-2025](https://www.kaggle.com/datasets/adamgbor/club-football-match-data-2000-2025) : résultats, cotes de paris, indices Elo et forme des équipes (~226 000 matchs, 27 pays, 42 ligues).
- **Base « Foot »** — [Football Match Statistics](https://www.kaggle.com/datasets/gokhanergul/football-match-statistics) : statistiques détaillées de match, dont le **stade, la capacité et l'affluence** (~100 000 lignes, 91 variables).

L'étude se concentre sur la **Ligue 1**, mais le pipeline est adaptable à n'importe quel championnat présent dans ces bases.

## 🔧 Démarche

1. **Nettoyage & préparation** : filtrage sur la Ligue 1, harmonisation des noms d'équipes entre les deux bases, jointure sur (date, équipe domicile, équipe extérieur).
2. **Gestion des valeurs manquantes et aberrantes** : suppression des lignes sans affluence (surtout avant 2015), retrait de la saison 2020/2021 (COVID, affluences non représentatives), correction des incohérences (affluence > capacité).
3. **Enrichissement** : création de nouvelles variables — `MatchDay`, `MatchMonth`, `MatchYear`, `MatchHour`, `IsWeekend`, `EloDiff`, `occupancy_rate`.
4. **Analyse exploratoire** : études univariée, bivariée et matrices de corrélation pour sélectionner les variables les plus pertinentes et éviter les redondances.
5. **Modélisation** : régression linéaire multiple, simple et interprétable.
6. **Validation** : test du modèle sur un échantillon de 80 matchs de la saison 2024/2025, comparaison affluence prédite vs réelle.

## 📈 Résultats

- Le modèle explique **≈ 88 % de la variance** de l'affluence (**R² = 0,878**).
- Effets marquants : les grands clubs (PSG, OM, OL) attirent nettement plus de public ; les matchs du **week-end** (+~4 500 spectateurs) et en **soirée** (+~5 200 à 21h) sont plus suivis ; l'affluence est plus forte en fin de saison (mai).
- Limites : certains écarts s'expliquent par des événements non modélisables (huis clos partiel, sanctions, grèves de supporters), comme le match Saint-Étienne – Le Havre où deux tribunes étaient fermées.

## 🛠️ Technologies

**R** · dplyr · tidyr · ggplot2 · corrplot · lubridate · scales · caret · fastDummies · readxl · writexl

## 📁 Structure du dépôt

```
.
├── README.md
├── rapport/
│   └── Affluence_Ligue1.pdf
├── data/
│   ├── Football_clean.csv
│   └── Matches.csv
├── src/
│   └── analyse_affluence.R
└── output/
    └── Resultat_Prediction_Match.xlsx
```

## ▶️ Utilisation

1. Installer les packages nécessaires :
```r
   install.packages(c("readxl","dplyr","tidyr","ggplot2","corrplot",
                      "lubridate","scales","caret","fastDummies","writexl"))
```
2. Placer les fichiers de données dans le dossier `data/` et adapter le chemin en début de script (`setwd(...)`).
3. Lancer `src/analyse_affluence.R`. Le script effectue le nettoyage, l'analyse, l'entraînement du modèle et génère les prédictions dans `output/`.

## ⚠️ Note sur les données

La base « Foot » contient des colonnes très riches (buteurs, passeurs, remplacements) remplies de listes avec virgules et guillemets, qui peuvent casser la lecture par `read.csv()` et faire disparaître une partie des lignes. Le fichier `data/Football_clean.csv` fourni ici ne conserve que les colonnes utiles à l'étude, dans un format propre lisible directement par R.

---

*Auteur : BART François *
