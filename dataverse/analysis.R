# Replication analysis for politician conjoint
#
# Brehm, Zhou, & Denney (2025). "From Division to Democracy: How Political
# Socialization Shapes Citizen Preferences in Germany and Korea."
# Communist and Post-Communist Studies.
# DOI: 10.1525/cpcs.2025.2636997
#
# This script derives all analysis variables from raw survey responses,
# then produces all conjoint figures from the paper and supplementary materials.

suppressPackageStartupMessages({
  library(tidyverse)
  library(cregg)
  library(ggthemes)
  library(MatchIt)
})

out_dir <- "output"
fig_dir <- file.path(out_dir, "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# =====================================================================
# Load data
# =====================================================================

ge <- read_csv("data/germany_politician.csv", show_col_types = FALSE)
sk <- read_csv("data/korea_politician.csv", show_col_types = FALSE)
nk <- read_csv("data/nk_politician.csv", show_col_types = FALSE) %>%
  mutate(ResponseId = as.character(ResponseId))

cat("Loaded: Germany", n_distinct(ge$ResponseId), "respondents,",
    nrow(ge), "rows\n")
cat("Loaded: South Korea", n_distinct(sk$ResponseId), "respondents,",
    nrow(sk), "rows\n")
cat("Loaded: North Korea", n_distinct(nk$ResponseId), "respondents,",
    nrow(nk), "rows\n")

# =====================================================================
# Translate conjoint attribute levels to English
# =====================================================================

# German labels → English
democracy_de <- c(
  "Die Demokratie mag Probleme haben, aber sie ist besser als jede andere Regierungsform" =
    "Democracy is best\ndespite problems",
  "In einer Demokratie funktioniert das Wirtschaftssystem schlecht" =
    "Democracies mismanage\nthe economy",
  "Demokratische Systeme sind unentschlossen und schlecht darin, Ordnung aufrechtzuerhalten" =
    "Democracies are indecisive\nand disorderly"
)
economy_de <- c(
  "Der Staat sollte Unternehmen mehr Freiheit geben" = "Greater freedom\nto firms",
  "Der Staat sollte Unternehmen effektiver kontrollieren" = "More state\ncontrol"
)
welfare_de <- c(
  "Die Menschen sollten mehr Verantwortung \u00fcbernehmen, um f\u00fcr sich selbst zu sorgen" =
    "Individual\nresponsibility",
  "Die Regierung sollte mehr Verantwortung \u00fcbernehmen, um sicherzustellen, dass f\u00fcr alle gesorgt ist" =
    "More state\nresponsibility"
)
gender_de <- c(
  "Das Geschlecht sollte bei der Bestimmung sozialer Rollen nicht wichtig sein" =
    "Gender\nneutral",
  "Um Gleichheit zu f\u00f6rdern, sollten Frauen bei Entscheidung bez\u00fcglich der beruflichen Anstellung gegen\u00fcber M\u00e4nnern bevorzugt werden, wenn sie gleich qualifiziert sind" =
    "Pro-gender\nequity",
  "Wenn Arbeitspl\u00e4tze knapp sind, sollten M\u00e4nner mehr Anrecht auf einen Arbeitsplatz haben als Frauen" =
    "Pro-\npatriarchy"
)
diversity_de <- c(
  "Ethnische und kulturelle Vielfalt untergr\u00e4bt die Einheit eines Landes" =
    "Diversity erodes\nunity",
  "Ethnische und kulturelle Vielfalt bereichern das Leben der Menschen in unserem Land" =
    "Diversity is\nsocially enriching",
  "Ethnische und kulturelle Diversit\u00e4t ist von \u00f6konomischem Nutzen und sollte daher akzeptiert werden" =
    "Diversity is\neconomically beneficial"
)

# Korean labels → English (shared by SK and NK)
democracy_ko <- c(
  "\ubbfc\uc8fc\uc8fc\uc758\ub294 \ubb38\uc81c\uc810\uc774 \uc788\uc9c0\ub9cc, \ub2e4\ub978 \uc5b4\ub5a4 \uc815\ubd80 \ud615\ud0dc\ubcf4\ub2e4\ub294 \ub098\uc740 \ubc29\uc2dd\uc774\ub2e4" =
    "Democracy is best\ndespite problems",
  "\ubbfc\uc8fc\uc8fc\uc758\ub294 \uacbd\uc81c\ub825\uc744 \uc545\ud654\uc2dc\ud0a8\ub2e4" =
    "Democracies mismanage\nthe economy",
  "\ubbfc\uc8fc\uc8fc\uc758\ub294 \uacb0\uc815\ub825\uc774 \ubd80\uc871\ud558\uba70 \uc9c8\uc11c\ub97c \uc720\uc9c0\ud558\uc9c0 \ubabb\ud55c\ub2e4" =
    "Democracies are indecisive\nand disorderly"
)
economy_ko <- c(
  "\uad6d\uac00\ub294 \uc0ac\uae30\uc5c5\uc744 \ud655\ub300\ud574\uc57c \ud55c\ub2e4" =
    "Greater freedom\nto firms",
  "\uad6d\uac00\ub294 \uad6d\uc601\uae30\uc5c5\uc744 \ud655\ub300\ud574\uc57c \ud55c\ub2e4" =
    "More state\ncontrol"
)
welfare_ko <- c(
  "\ub2f9\uc0ac\uc790\uac00 \uac01\uc790\uc758 \uc0dd\uacc4\uc5d0 \ucc45\uc784\uc744 \uc838\uc57c \ud55c\ub2e4" =
    "Individual\nresponsibility",
  "\uc815\ubd80\uac00 \ubcf5\uc9c0\uc5d0 \ub354 \ucc45\uc784\uc744 \uc838\uc57c \ud55c\ub2e4" =
    "More state\nresponsibility"
)
gender_ko <- c(
  "\uc0ac\ud68c\uc0dd\ud65c\uc5d0\uc11c \uc5ed\ud560\uc744 \ubd84\ub2f4\ud560 \ub54c \uc131\ubcc4\uc774 \uc911\uc694\ud558\uc9c0 \uc54a\ub2e4" =
    "Gender\nneutral",
  "\ud3c9\ub4f1\ud55c \ucc44\uc6a9\uacb0\uc815\uc744 \uc704\ud574 \uc9c0\uc6d0\uc790\ub4e4\uc758 \ub2a5\ub825\uc774 \ub3d9\uc77c\ud55c \uacbd\uc6b0\uc5d0\ub3c4 \uc5ec\uc131\uc774 \ub0a8\uc131\ubcf4\ub2e4 \uc6b0\uc120\uc801\uc73c\ub85c \uc2ec\uc0ac\ub418\uc5b4\uc57c \ud55c\ub2e4" =
    "Pro-gender\nequity",
  "\uc77c\uc790\ub9ac\uac00 \uadc0\ud560 \ub54c\uc5d0\ub294 \uc5ec\uc790\ubcf4\ub2e4 \ub0a8\uc790\uc5d0\uac8c \uc77c\uc790\ub9ac\ub97c \uc6b0\uc120 \ubd80\uc5ec\ud574\uc57c \ud55c\ub2e4" =
    "Pro-\npatriarchy"
)
diversity_ko <- c(
  "\uc778\uc885 \ubc0f \ubb38\ud654\uc758 \ub2e4\uc591\uc131\uc740 \uad6d\uac00\uc758 \uacb0\uc18d\ub825\uc744 \uc57d\ud654\uc2dc\ud0a8\ub2e4" =
    "Diversity erodes\nunity",
  "\uc778\uc885\uacfc \ubb38\ud654\uc758 \ub2e4\uc591\uc131\uc740 \uc2dc\ubbfc\ub4e4\uc758 \uc0b6\uc744 \ud5a5\uc0c1\uc2dc\ud0a8\ub2e4" =
    "Diversity is\nsocially enriching",
  "\uc778\uc885 \ubc0f \ubb38\ud654\uc758 \ub2e4\uc591\uc131\uc740 \ub098\ub77c\uc5d0 \uacbd\uc81c\uc801 \uc774\ub4dd\uc774 \ub418\uae30 \ub54c\ubb38\uc5d0 \ubc1b\uc544\ub4e4\uc5ec\uc57c \ud55c\ub2e4" =
    "Diversity is\neconomically beneficial"
)

# Apply translations
translate_attrs <- function(df, democracy_map, economy_map, welfare_map,
                            gender_map, diversity_map) {
  df %>%
    mutate(
      Democracy = factor(recode(Democracy, !!!democracy_map),
                          levels = unname(democracy_map)),
      Economy   = factor(recode(Economy, !!!economy_map),
                          levels = unname(economy_map)),
      Welfare   = factor(recode(Welfare, !!!welfare_map),
                          levels = unname(welfare_map)),
      Gender    = factor(recode(Gender, !!!gender_map),
                          levels = unname(gender_map)),
      Diversity = factor(recode(Diversity, !!!diversity_map),
                          levels = unname(diversity_map))
    )
}

ge <- translate_attrs(ge, democracy_de, economy_de, welfare_de,
                      gender_de, diversity_de)
sk <- translate_attrs(sk, democracy_ko, economy_ko, welfare_ko,
                      gender_ko, diversity_ko)
nk <- translate_attrs(nk, democracy_ko, economy_ko, welfare_ko,
                      gender_ko, diversity_ko)

attrs <- politician_choice ~ Democracy + Economy + Welfare + Gender + Diversity

# =====================================================================
# Derive analysis variables
# =====================================================================

# --- Germany ---
eastern_states <- c("Brandenburg", "Mecklenburg-Vorpommern", "Sachsen",
                     "Sachsen-Anhalt", "Th\u00fcringen",
                     "Ost-Berlin (vor der Wiedervereinigung)")

ge <- ge %>%
  mutate(
    east_germany_F = factor(east_germany_F,
                             levels = c("Western German", "Eastern German",
                                        "Post-GDR citizen")),

    # University education (binary)
    eduhigh = as.integer(education %in% c(
      "(Fach)Hochschulabschluss (Bachelor)",
      "(Fach)Hochschulabschluss (Diplom, Master oder höher)",
      "Fachhochschulreife (Abschluss einer Fachoberschule etc.)"
    )),

    # Regional classification for SI Figure D.1
    region = case_when(
      current_state %in% c("Bremen", "Hamburg", "Niedersachsen",
                            "Schleswig-Holstein",
                            "West-Berlin (vor der Wiedervereinigung)") ~ "North",
      current_state %in% c("Bayern", "Baden-W\u00fcrttemberg", "Hessen",
                            "Rheinland-Pfalz", "Saarland") ~ "South",
      current_state %in% c("Berlin", "Brandenburg", "Mecklenburg-Vorpommern",
                            "Sachsen", "Sachsen-Anhalt", "Th\u00fcringen",
                            "Nordrhein-Westfalen",
                            "Ost-Berlin (vor der Wiedervereinigung)") ~ "East",
      TRUE ~ NA_character_
    ),

    # Partisan group for SI Figure D.2
    partisan_group = case_when(
      party_vote %in% c("Sozialdemokratische Partei Deutschlands (SPD)",
                         "Bündnis 90/Die Grünen", "DIE LINKE") ~ "Left-wing",
      party_vote %in% c(
        "Christlich Demokratische Union (CDU) Christlich-Soziale Union (CSU)",
        "Freie Demokratische Partei (FDP)",
        "Ich weiß es nicht", "Eine andere Partei") ~ "Center",
      party_vote == "Alternative für Deutschland (AfD)" ~ "Right-wing",
      TRUE ~ NA_character_
    ),
    partisan_group = factor(partisan_group,
                             levels = c("Left-wing", "Center", "Right-wing"))
  )

# --- South Korea ---
sk <- sk %>%
  mutate(
    eduhigh = as.integer(education %in% c("대학교", "대학원 이상")),

    # Democratic generation cohort for SI Figure D.3
    # Democratization in 1987. Those born before 1975 spent at least 12
    # formative years under authoritarian rule (pre-democratic cohort).
    cohort = case_when(
      yob < 1975 ~ "Pre-democratic\nSouth Korea",
      yob >= 1975 ~ "Democratic\nSouth Korea",
      TRUE ~ NA_character_
    ),

    # Partisan classification for SI Figure D.4
    progressive = as.integer(political_ideology %in% c("다소 진보적", "매우 진보적")),
    conservative = as.integer(political_ideology %in% c("다소 보수적", "매우 보수적")),
    partisan = case_when(
      progressive == 1 |
        (political_ideology == "중도적" & party_vote == "더불어민주당") ~ "Progressive",
      conservative == 1 |
        (political_ideology == "중도적" & party_vote == "국민의힘") ~ "Conservative",
      political_ideology == "중도적" ~ "Centrist",
      TRUE ~ NA_character_
    ),
    partisan = factor(partisan, levels = c("Progressive", "Conservative", "Centrist"))
  )

# --- North Korea ---
nk <- nk %>%
  mutate(
    eduhigh = as.integer(education_nk %in% c(
      "대학교 (3-4년) 졸업", "대학원 졸업"
    ))
  )

# =====================================================================
# Theme
# =====================================================================

theme_conjoint <- theme_few() +
  theme(
    strip.text = element_text(size = 10, face = "bold"),
    axis.text.y = element_text(size = 8),
    axis.text.x = element_text(size = 9),
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(size = 13, face = "bold"),
    plot.subtitle = element_text(size = 10)
  )

# =====================================================================
# Figure 1: Germany Marginal Means by Subgroup
# =====================================================================
cat("\nFigure 1: Germany marginal means...\n")

mm_ge <- cj(ge, attrs, id = ~ResponseId, estimate = "mm",
            by = ~east_germany_F)

p1 <- plot(mm_ge) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Germany: Marginal Means by Subgroup",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig1_germany_mm.pdf"), p1, width = 10, height = 8)
ggsave(file.path(fig_dir, "fig1_germany_mm.png"), p1, width = 10, height = 8, dpi = 300)
write_csv(mm_ge, file.path(out_dir, "mm_germany_by_subgroup.csv"))

# =====================================================================
# Figure 2: Korea Marginal Means (SK + NK)
# =====================================================================
cat("Figure 2: Korea marginal means...\n")

kor <- bind_rows(
  sk %>% mutate(group = "Native South Korean"),
  nk %>% mutate(group = "Post-DPRK citizen")
) %>%
  mutate(group = factor(group, levels = c("Native South Korean",
                                           "Post-DPRK citizen")))

mm_kor <- cj(kor, attrs, id = ~ResponseId, estimate = "mm", by = ~group)

p2 <- plot(mm_kor) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Korea: Marginal Means",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig2_korea_mm.pdf"), p2, width = 10, height = 8)
ggsave(file.path(fig_dir, "fig2_korea_mm.png"), p2, width = 10, height = 8, dpi = 300)
write_csv(mm_kor, file.path(out_dir, "mm_korea_by_group.csv"))

# =====================================================================
# Figure 3: Matched Samples
# =====================================================================
cat("Figure 3: Matched samples...\n")

# --- Korea matching: Post-DPRK (NK) vs Native South Korean ---
kor_match_data <- kor %>%
  filter(!is.na(age), !is.na(female), !is.na(eduhigh)) %>%
  distinct(ResponseId, .keep_all = TRUE) %>%
  mutate(treated = as.integer(group == "Post-DPRK citizen"))

m_kor <- matchit(treated ~ age + female + eduhigh,
                 data = kor_match_data,
                 method = "nearest", ratio = 2, replace = FALSE)

kor_matched_ids <- match.data(m_kor)$ResponseId
kor_matched <- kor %>% filter(ResponseId %in% kor_matched_ids)

mm_kor_matched <- cj(kor_matched, attrs, id = ~ResponseId,
                     estimate = "mm", by = ~group)

p3_kor <- plot(mm_kor_matched) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Korea: Matched Sample",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig3_korea_matched.pdf"), p3_kor, width = 10, height = 8)
ggsave(file.path(fig_dir, "fig3_korea_matched.png"), p3_kor, width = 10, height = 8, dpi = 300)

# --- Germany matching: Post-GDR vs Western German ---
ge_match_data <- ge %>%
  filter(east_germany_F %in% c("Post-GDR citizen", "Western German")) %>%
  distinct(ResponseId, .keep_all = TRUE) %>%
  mutate(treated = as.integer(east_germany_F == "Post-GDR citizen"))

m_ge <- matchit(treated ~ age + female + eduhigh,
                data = ge_match_data,
                method = "nearest", ratio = 2, replace = FALSE)

ge_matched_ids <- match.data(m_ge)$ResponseId
ge_matched <- ge %>%
  filter(ResponseId %in% ge_matched_ids) %>%
  filter(east_germany_F %in% c("Post-GDR citizen", "Western German")) %>%
  mutate(east_germany_F = droplevels(east_germany_F))

mm_ge_matched <- cj(ge_matched, attrs, id = ~ResponseId,
                    estimate = "mm", by = ~east_germany_F)

p3_ge <- plot(mm_ge_matched) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Germany: Matched Sample",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig3_germany_matched.pdf"), p3_ge, width = 10, height = 8)
ggsave(file.path(fig_dir, "fig3_germany_matched.png"), p3_ge, width = 10, height = 8, dpi = 300)

write_csv(bind_rows(mm_kor_matched, mm_ge_matched),
          file.path(out_dir, "mm_matched_samples.csv"))

# =====================================================================
# SI Figure D.1: German Regions
# =====================================================================
cat("SI Figure D.1: German regions...\n")

ge_regions <- ge %>% filter(!is.na(region)) %>%
  mutate(region = factor(region, levels = c("North", "South", "East")))

mm_ge_region <- cj(ge_regions, attrs, id = ~ResponseId,
                   estimate = "mm", by = ~region)

p_d1 <- plot(mm_ge_region) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Germany: Marginal Means by Region",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig_D1_german_regions.pdf"), p_d1,
       width = 10, height = 8)
ggsave(file.path(fig_dir, "fig_D1_german_regions.png"), p_d1,
       width = 10, height = 8, dpi = 300)

write_csv(mm_ge_region, file.path(out_dir, "mm_germany_by_region.csv"))

# =====================================================================
# SI Figure D.2: German Regions x Partisanship
# =====================================================================
cat("SI Figure D.2: German regions x partisanship...\n")

# Western Germans by partisanship
ge_west <- ge %>%
  filter(east_germany_F == "Western German", !is.na(partisan_group))
mm_ge_west_party <- cj(ge_west, attrs, id = ~ResponseId,
                       estimate = "mm", by = ~partisan_group)

p_d2_west <- plot(mm_ge_west_party) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Western German by Partisanship",
       x = "Marginal Mean", y = NULL)

# Eastern Germans by partisanship
ge_east <- ge %>%
  filter(east_germany_F == "Eastern German", !is.na(partisan_group))
mm_ge_east_party <- cj(ge_east, attrs, id = ~ResponseId,
                       estimate = "mm", by = ~partisan_group)

p_d2_east <- plot(mm_ge_east_party) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Eastern German by Partisanship",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig_D2_german_partisanship.pdf"),
       cowplot::plot_grid(p_d2_west, p_d2_east, ncol = 2),
       width = 14, height = 8)
ggsave(file.path(fig_dir, "fig_D2_german_partisanship.png"),
       cowplot::plot_grid(p_d2_west, p_d2_east, ncol = 2),
       width = 14, height = 8, dpi = 300)

# =====================================================================
# SI Figure D.3: Korean Cohorts
# =====================================================================
cat("SI Figure D.3: Korean cohorts...\n")

kor_cohort <- bind_rows(
  sk %>% mutate(cohort_group = cohort),
  nk %>% mutate(cohort_group = "Post-DPRK\ncitizen")
) %>%
  filter(!is.na(cohort_group)) %>%
  mutate(cohort_group = factor(cohort_group,
    levels = c("Pre-democratic\nSouth Korea", "Post-DPRK\ncitizen",
               "Democratic\nSouth Korea")))

mm_kor_cohort <- cj(kor_cohort, attrs, id = ~ResponseId,
                    estimate = "mm", by = ~cohort_group)

p_d3 <- plot(mm_kor_cohort) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Korea: Marginal Means by Cohort",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig_D3_korean_cohorts.pdf"), p_d3,
       width = 10, height = 8)
ggsave(file.path(fig_dir, "fig_D3_korean_cohorts.png"), p_d3,
       width = 10, height = 8, dpi = 300)

# =====================================================================
# SI Figure D.4: Korean Partisanship
# =====================================================================
cat("SI Figure D.4: Korean partisanship...\n")

kor_partisan <- bind_rows(
  sk %>% filter(!is.na(partisan)) %>%
    mutate(partisan_group = as.character(partisan)),
  nk %>% mutate(partisan_group = "Post-DPRK citizen")
) %>%
  mutate(partisan_group = factor(partisan_group,
    levels = c("Progressive", "Post-DPRK citizen",
               "Conservative", "Centrist")))

mm_kor_partisan <- cj(kor_partisan, attrs, id = ~ResponseId,
                      estimate = "mm", by = ~partisan_group)

p_d4 <- plot(mm_kor_partisan) +
  theme_conjoint +
  geom_vline(xintercept = 0.5, linetype = "dashed", color = "gray60") +
  labs(title = "Korea: Marginal Means by Partisanship",
       x = "Marginal Mean", y = NULL)

ggsave(file.path(fig_dir, "fig_D4_korean_partisanship.pdf"), p_d4,
       width = 10, height = 8)
ggsave(file.path(fig_dir, "fig_D4_korean_partisanship.png"), p_d4,
       width = 10, height = 8, dpi = 300)

# =====================================================================
# Tables A.1-A.3: Sample Summaries
# =====================================================================
cat("\nSample summary tables...\n")

# Germany
ge_summary <- ge %>%
  distinct(ResponseId, .keep_all = TRUE) %>%
  summarise(
    n = n(),
    mean_age = mean(age, na.rm = TRUE),
    pct_female = mean(female, na.rm = TRUE) * 100,
    pct_university = mean(eduhigh, na.rm = TRUE) * 100,
    n_western = sum(east_germany_F == "Western German", na.rm = TRUE),
    n_eastern = sum(east_germany_F == "Eastern German", na.rm = TRUE),
    n_postgdr = sum(east_germany_F == "Post-GDR citizen", na.rm = TRUE)
  )
write_csv(ge_summary, file.path(out_dir, "table_A1_germany_sample.csv"))

# South Korea
sk_summary <- sk %>%
  distinct(ResponseId, .keep_all = TRUE) %>%
  summarise(
    n = n(),
    mean_age = mean(age, na.rm = TRUE),
    pct_female = mean(female, na.rm = TRUE) * 100,
    pct_university = mean(eduhigh, na.rm = TRUE) * 100
  )
write_csv(sk_summary, file.path(out_dir, "table_A2_korea_sample.csv"))

# North Korea
nk_summary <- nk %>%
  distinct(ResponseId, .keep_all = TRUE) %>%
  summarise(
    n = n(),
    mean_age = mean(age, na.rm = TRUE),
    pct_female = mean(female, na.rm = TRUE) * 100,
    pct_university = mean(eduhigh, na.rm = TRUE) * 100
  )
write_csv(nk_summary, file.path(out_dir, "table_A3_nk_sample.csv"))

# =====================================================================
# Tables B.1-B.3: Balance Tests
# =====================================================================
cat("Balance test tables...\n")

balance_test <- function(df, label) {
  df %>%
    pivot_longer(c(Democracy, Economy, Welfare, Gender, Diversity),
                 names_to = "attribute", values_to = "level") %>%
    count(attribute, level) %>%
    group_by(attribute) %>%
    mutate(proportion = n / sum(n)) %>%
    ungroup() %>%
    mutate(sample = label)
}

write_csv(balance_test(ge, "Germany"),
          file.path(out_dir, "table_B1_balance_germany.csv"))
write_csv(balance_test(sk, "South Korea"),
          file.path(out_dir, "table_B2_balance_korea.csv"))
write_csv(balance_test(nk, "North Korea"),
          file.path(out_dir, "table_B3_balance_nk.csv"))

# =====================================================================
# Session info
# =====================================================================
writeLines(capture.output(sessionInfo()),
           file.path(out_dir, "session_info.txt"))

cat("\n=== Done ===\n")
cat("Figures saved to", fig_dir, "\n")
cat("Tables saved to", out_dir, "\n")
