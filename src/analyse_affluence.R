library(readxl)
library(esquisse)
library(vcd)
library(dplyr)
library(gmodels)
library(tidyr)
library(writexl)
library(ggplot2)
library(corrplot)
library(lubridate)
library(scales)
library(caret)
library(fastDummies)

# Importation de la base de données
# Chemin a modifié pour l'import des données
#setwd("")
foot <- read.csv("Football_clean.csv")
match <- read.csv("Matches.csv")

summary(foot)
summary(match)

# garder variables utiles pour l'étude

foot1 <- foot %>% select(c(Country,League,home_team,away_team,season_year,Date_day,Date_hour,venue,capacity,attendance))
match1 <- match %>% select(c(Division,MatchDate,MatchTime,HomeTeam,AwayTeam,HomeElo,AwayElo,Form3Home,Form5Home,Form3Away,Form5Away,OddHome,OddDraw,OddAway,Over25,Under25,MaxHome,MaxDraw,MaxAway,MaxOver25,MaxUnder25))

# verifications

colSums(is.na(match))
colSums(is.na(foot1))

# filtres sur la ligue 1 uniquement

foot2 <- foot1 %>% filter(foot1$League == "Ligue-1")
match2 <- match1 %>% filter(match1$Division == "F1")

table(foot2$League) # 6888 lignes
table(match2$Division) # 8657 lignes

# changment de la date pour foot2

foot3 <- foot2 %>%
  mutate(
    annee1 = as.numeric(sub("/.*", "", season_year)),
    annee2 = as.numeric(sub(".*/", "", season_year)),
    
    jour = as.numeric(sub("\\..*", "", Date_day)),
    mois = as.numeric(sub(".*\\.", "", Date_day)),
    
    annee = ifelse(mois <= 6, annee2, annee1), # si le mois est inférieur a 6 (juin), ca correspond a la deuxième année dans season_year
    
    MatchDate = sprintf("%d-%02d-%02d", annee, mois, jour),
    
  )

foot3 <- foot3 %>% select(c(-jour,-mois,-annee,-annee1,-annee2))


# jointure des deux fichiers

foot3 <- foot3 %>% rename(HomeTeam = home_team, AwayTeam = away_team)

table(match2$HomeTeam)
table(foot3$HomeTeam)

foot4 <- foot3 %>%
  mutate(
    HomeTeam = recode(HomeTeam,
                      "AC Ajaccio" = "Ajaccio",
                      "AC Ajaccio\n2" = "Ajaccio",
                      "GFC Ajaccio" = "Ajaccio GFCO",
                      "Thonon-Evian" = "Evian Thonon Gaillard",
                      "Thonon-Evian\n2" = "Evian Thonon Gaillard",
                      "PSG" = "Paris SG",
                      "Lyon\n2" = "Lyon",
                      "Marseille\n2" = "Marseille",
                      "Metz\n2" = "Metz",
                      "Monaco\n2" = "Monaco",
                      "Montpellier\n2" = "Montpellier",
                      "Nantes\n2" = "Nantes",
                      "Nice\n2" = "Nice",
                      "Reims\n2" = "Reims",
                      "St Etienne\n2" = "St Etienne",
                      "Toulouse\n2" = "Toulouse",
                      "Lens\n2" = "Lens",
                      "Lorient\n2" = "Lorient",
                      "Caen\n2" = "Caen",
                      "Clermont\n2" = "Clermont"
    ),
    AwayTeam = recode(AwayTeam,
                      "AC Ajaccio" = "Ajaccio",
                      "AC Ajaccio\n2" = "Ajaccio",
                      "GFC Ajaccio" = "Ajaccio GFCO",
                      "Thonon-Evian" = "Evian Thonon Gaillard",
                      "Thonon-Evian\n2" = "Evian Thonon Gaillard",
                      "PSG" = "Paris SG",
                      "Lyon\n2" = "Lyon",
                      "Marseille\n2" = "Marseille",
                      "Metz\n2" = "Metz",
                      "Monaco\n2" = "Monaco",
                      "Montpellier\n2" = "Montpellier",
                      "Nantes\n2" = "Nantes",
                      "Nice\n2" = "Nice",
                      "Reims\n2" = "Reims",
                      "St Etienne\n2" = "St Etienne",
                      "Toulouse\n2" = "Toulouse",
                      "Lens\n2" = "Lens",
                      "Lorient\n2" = "Lorient",
                      "Caen\n2" = "Caen",
                      "Clermont\n2" = "Clermont"
    )
  )

data <- left_join(match2, foot4, 
                  by = c("MatchDate", "HomeTeam", "AwayTeam"))

colSums(is.na(data)) # 2803 manquantes alors qu'il est sensé en manquer 1769

data <- data %>% # on garde quand l'année est supérieur à  aout 2016 car avant pas d'affluence
  mutate(MatchDate = as.Date(MatchDate)) %>%
  filter(MatchDate >= as.Date("2015-08-01"))

# formats
data$attendance <- as.numeric(gsub(" ", "", data$attendance))
data$capacity <- as.numeric(gsub(" ", "", data$capacity))
data$MatchDate <- as.Date(data$MatchDate, format = "%Y-%m-%d")

colSums(is.na(data)) # 784 manquantes

# si on n'a pas la donnée on supprime car on peut pas la prédire
data <- data %>%
  filter(!is.na(Country)) # ca supprime les données pas join
data <- data %>%
  filter(!is.na(HomeElo))
data <- data %>%
  filter(!is.na(AwayElo))
data <- data %>%
  filter(!is.na(OddHome))
data <- data %>%
  filter(!is.na(OddDraw))
data <- data %>%
  filter(!is.na(OddAway))
data <- data %>%
  filter(!is.na(attendance))

colSums(is.na(data)) # plus de données manaquantes

# enlever les variables inutiles (qui se repetent)

data <- data %>% select(c(-Division,-MatchTime,-Date_day))

data <- data %>%
  filter(attendance <= capacity)

# Ajout de nouvelles variables pour améliorer le futur modèle
data <- data %>%
  mutate(
    MatchDay = weekdays(as.Date(MatchDate)),       # Permet de récuperer le jour de la semaine 
    MatchMonth = month(as.Date(MatchDate)),        # Permet de récuperer le numéro du mois 
    MatchYear = year(as.Date(MatchDate)),          # Permet de récuperer l'année mêm si un peu redondant avec season_year
    MatchHour = as.numeric(substr(Date_hour, 1, 2)), # Permet de garder seulement l'heure du match et pas les minutes
    IsWeekend = ifelse(weekdays(as.Date(MatchDate)) %in% c("samedi", "dimanche"), 1, 0), # Permet de savoir si le match est le week-end
    EloDiff = HomeElo - AwayElo, # Permet de connaître la différence d'elo entre les deux équipes
    occupancy_rate = attendance / capacity # % de la capacité occupé
  )

data <- data %>% select(c(-MatchDate,-Date_hour,-Country,-League))

# Données aberrantes

data <- data %>% # On retire seulement les données de l'année 2020/2021 en raison du covid
  filter(season_year != "2020/2021")

# Remarque, aucune données en octobre car dans notre source de données pas d'affluence a ce mois ci.

data$MatchDay <- factor(data$MatchDay,
                        levels = c("lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"),
                        ordered = TRUE)


# stats descriptives

# Stats univariées
# Distribution de l'affluence
ggplot(data) + aes(x = attendance) + geom_histogram(bins = 25, fill = "#1f77b4") + theme_minimal() +
  labs(title = "Distribution de l'Affluence",
    x = "Nombre de Specateurs",
    y = "Nombre de Matchs")

# Diagramme de densité sur la différence d'elo
ggplot(data) + aes(x = EloDiff) + geom_density(fill = "#1f77b4") + theme_minimal() +
  labs(title = "Diagramme de Densité",
       x = "Différences d'elo entre les deux équipes",
       y = "Densité")

# Diagramme en barres du nombre de matchs par jour de la semaine
ggplot(data) + aes(x = MatchDay) + geom_bar(fill = "#1f77b4") + theme_minimal() +
  labs(title = "Distribution du nombre de matchs par jour de la semaine",
       x = "",
       y = "")


# Stats bivariées

attendance_moyenne_saison <- data %>%
  group_by(season_year) %>%
  summarize(moyenne_attendance = mean(attendance, na.rm = TRUE))

ggplot(attendance_moyenne_saison, aes(x = factor(season_year), y = moyenne_attendance)) +
  geom_col(fill = "#1f77b4") +
  geom_text(aes(label = round(moyenne_attendance, 0)), 
            vjust = -0.3, color = "black") +  # Add labels
  theme_minimal(base_size = 14) +
  labs(
    title = "Affluence moyenne par Saison",
    x = "",
    y="")

attendance_moyenne_heure <- data %>%
  group_by(MatchHour) %>%
  summarize(moyenne_attendance = mean(attendance, na.rm = TRUE))

ggplot(attendance_moyenne_heure) +
  aes(x = MatchHour, y = moyenne_attendance) +
  geom_col(fill = "#1f77b4", color = "white", width = 0.7) +
  geom_text(
    aes(label = round(moyenne_attendance, 0)),  # Round to whole number
    vjust = -0.3, color = "black") +
  theme_minimal(base_size = 14) +
  labs(
    title = "Affluence moyenne par Heure de Match",
    x = "",
    y = ""
  )

attendance_moyenne_month <- data %>%
  group_by(MatchMonth) %>%
  summarize(moyenne_attendance = mean(attendance, na.rm = TRUE))

ggplot(attendance_moyenne_month) +
  aes(x = MatchMonth, y = moyenne_attendance) +
  geom_col(fill = "#1f77b4", color = "white", width = 0.7) +
  geom_text(
    aes(label = round(moyenne_attendance, 0)),  # Round to whole number
    vjust = -0.3, color = "black") +
  theme_minimal(base_size = 14) +
  labs(
    title = "Affluence moyenne par Mois",
    x = "",
    y = ""
  ) +
  scale_x_discrete(drop = FALSE, 
                   limits = month.name)


attendance_moyenne_day <- data %>%
  group_by(season_year) %>%
  summarise(moyenne_attendance = mean(occupancy_rate, na.rm = TRUE))

ggplot(attendance_moyenne_day) +
  aes(x = season_year, y = moyenne_attendance) +
  geom_col(fill = "#1f77b4", color = "white", width = 0.7) +
  geom_text(
    aes(label = percent(moyenne_attendance, accuracy = 1)),  # Show % label
    vjust = -0.3, color = "black", size = 4
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 10)) +  # Y-axis in %
  theme_minimal(base_size = 14) +
  labs(
    title = "Taux de Remplissage Moyen par Saison",
    x = "",
    y = ""
  )


# Corrélation des variables
numeric_features <- data %>% # Selection des vars quantitatives
  select(
    HomeElo, AwayElo, Form3Home, Form5Home, Form3Away, Form5Away,
    OddHome, OddDraw, OddAway, Over25, Under25,
    MaxHome, MaxDraw, MaxAway, MaxOver25, MaxUnder25,
    capacity, attendance, MatchMonth, MatchYear, MatchHour, 
    IsWeekend, EloDiff, occupancy_rate)

cor_matrix <- cor(numeric_features, use = "complete.obs", method = "pearson")
round(cor_matrix, 2)

corrplot(cor_matrix, method = "color", type = "upper",
         addCoef.col = "black", tl.col = "black", number.cex = 0.7,
         title = "📈 Corrélation entre les variables numériques", mar = c(0,0,1,0))

cor_df <- as.data.frame(cor_matrix)
write_xlsx(cor_df, path = "correlation.xlsx")

data2 <- data %>% select(c(-MaxHome, -MaxDraw, -MaxAway, -Under25, -Over25, -MaxUnder25, -Form3Home, -Form3Away, -EloDiff, -occupancy_rate))

numeric_features <- data2 %>% # Selection des vars quantitatives
  select(
    HomeElo, AwayElo, Form5Home, Form5Away,
    OddHome, OddDraw, OddAway, MaxOver25,
    capacity, MatchMonth, MatchYear, MatchHour, 
    IsWeekend)

cor_matrix <- cor(numeric_features, use = "complete.obs", method = "pearson")
round(cor_matrix, 2)

cor_df <- as.data.frame(cor_matrix)
write_xlsx(cor_df, path = "correlation2.xlsx")
# Donc avec les correlations je supprimme MaxHome, MaxDraw, MaxAway, 
# Under25, Over25, MaxUnder25, Form3Home, Form3Away
# Je retire aussi EloDiff et occupancy_rate car ce sont des vars crée pour les stats


# modelisation

data2$MatchMonth <- as.factor(data2$MatchMonth)
data2$IsWeekend <- as.factor(data2$IsWeekend)
data2$HomeTeam <- as.factor(data2$HomeTeam)
data2$AwayTeam  <- as.factor(data2$AwayTeam)
data2$MatchDay  <- as.factor(data2$MatchDay)


model <- lm(attendance ~ HomeTeam + AwayTeam + HomeElo + AwayElo + Form5Home + Form5Away +
              OddHome + OddDraw + OddAway + MaxOver25 +
              capacity + MatchMonth + MatchYear + MatchHour + IsWeekend,
            data = data2)

summary(model)


# Test du modele sur les matchs de la saison 2024/2025 du début d'année

# Fichier excel à predire
matches_a_predire <- read_excel("Data_Match_Prediction.xlsx")

# Transforme en factor certaines variables pour la prediction
matches_a_predire <- matches_a_predire %>%
  mutate(
    HomeTeam = factor(HomeTeam, levels = levels(data2$HomeTeam)),
    AwayTeam = factor(AwayTeam, levels = levels(data2$AwayTeam)),
    MatchMonth = factor(MatchMonth, levels = levels(data2$MatchMonth)),
    IsWeekend = factor(IsWeekend, levels = levels(data2$IsWeekend))
  )

# Prediction de l'affluence
matches_a_predire$PredictedAttendance <- predict(model, newdata = matches_a_predire)
matches_a_predire$PredictedAttendance <- round(matches_a_predire$PredictedAttendance, 0)

# Renvoie d'un fichier Excel avec la prediction
write_xlsx(matches_a_predire, "Resultat_Prediction_Match.xlsx")


# ENFIN !!!!!


