# prepare_data.R
# Builds replication CSVs for the CPCS politician conjoint from original
# Qualtrics exports and pre-processed merged conjoint files.
#
# Input:  Raw Qualtrics CSVs + merged conjoint CSVs (from IFES2023 project)
# Output: data/germany_politician.csv
#         data/korea_politician.csv
#         data/nk_politician.csv

suppressPackageStartupMessages(library(tidyverse))

base <- "/Users/scdenney/Documents/GitHub/IFES2023"
out_dir <- file.path(dirname(base), "cpcs-2025-replication/data")

# ---- Helper: read Qualtrics CSV (3 header rows) ----
read_qualtrics <- function(path) {
  read_csv(path, skip = 3,
           col_names = read_csv(path, n_max = 0, show_col_types = FALSE) %>% names(),
           show_col_types = FALSE)
}

# ===========================================================================
# GERMANY
# ===========================================================================
cat("Processing Germany...\n")

# 1. Read merged politician conjoint (already in long format with English labels)
ge_conjoint <- read_csv(
  file.path(base, "Germans/Data/merged_german.pol.csv"),
  show_col_types = FALSE
) %>%
  select(ResponseId, question_profile, politician_choice,
         Democracy, Economy, Welfare, Gender, Diversity)

ge_conjoint_ids <- unique(ge_conjoint$ResponseId)
cat("  Conjoint respondents:", length(ge_conjoint_ids), "\n")

# 2. Read Qualtrics files
# February file (all respondents including oversampling)
ge_feb <- read_qualtrics(
  file.path(base, "Germans/Data/IFES 2023 - German_February 12, 2024_18.11-choice_text.csv")
)
cat("  February Qualtrics rows:", nrow(ge_feb), "\n")

# January file (quota sample only)
ge_jan <- read_qualtrics(
  file.path(base, "Germans/Data/IFES 2023 - German_January 11, 2024_18.44.csv")
)
cat("  January Qualtrics rows:", nrow(ge_jan), "\n")

# 3. Helper: extract demographics and derive binary East/West flag
# QMD uses TWO-level east.germany.F (Western/Eastern based on Q5 alone)
# for the combining/filtering step. The three-level classification (Post-GDR)
# is derived only AFTER combining the two data streams.
eastern_states <- c("Brandenburg", "Mecklenburg-Vorpommern", "Sachsen",
                     "Sachsen-Anhalt", "Thüringen",
                     "Ost-Berlin (vor der Wiedervereinigung)")

extract_demographics <- function(df) {
  df %>%
    select(
      ResponseId,
      gender_raw = Q7, yob = Q2, birth_country = Q3,
      state_at_18 = Q5, current_state = Q6,
      education = Q8, party_vote = Q11,
      attention_check = Q114
    ) %>%
    mutate(
      yob = as.numeric(yob),
      age = 2023 - yob,
      female = as.integer(gender_raw == "Weiblich"),
      # Binary: matches QMD's east.germany.F (two-level)
      east_german = as.integer(state_at_18 %in% c(eastern_states, "Berlin"))
    )
}

# 4. Process each file independently (matching QMD pipeline exactly)

# a) QUOTA stream from January file: attention check applied, remove Eastern Germans
# Note: the QMD applies the attention check before removing Qualtrics sub-header rows,
# then removes rows 1-2 afterward. Since the attention check already filters out the
# sub-header rows, the subsequent [-c(1,2),] removes 2 actual data rows. We replicate
# this behavior by reading the January file without skipping headers, applying the
# attention check, then removing the first 2 surviving rows.
ge_jan_raw <- read_csv(
  file.path(base, "Germans/Data/IFES 2023 - German_January 11, 2024_18.44.csv"),
  show_col_types = FALSE
)
ge_jan_raw <- ge_jan_raw %>% filter(Q114 == "Stimme überhaupt nicht zu")
ge_jan_raw <- ge_jan_raw[-c(1, 2), ]

ge_quota <- ge_jan_raw %>%
  filter(ResponseId %in% ge_conjoint_ids) %>%
  extract_demographics() %>%
  mutate(sample = "Quota")
cat("  Quota after attention check:", nrow(ge_quota), "\n")

quota_adjusted <- ge_quota %>%
  filter(east_german == 0)
cat("  Quota after removing Eastern Germans:", nrow(quota_adjusted), "\n")

# b) OVERSAMPLING stream from February file: NO attention check
ge_over <- ge_feb %>%
  filter(ResponseId %in% ge_conjoint_ids) %>%
  extract_demographics() %>%
  mutate(sample = "Over")
cat("  February respondents matched to conjoint:", nrow(ge_over), "\n")

# c) Combine: quota_adjusted + all February, then keep Quota OR Eastern German
combined <- bind_rows(quota_adjusted, ge_over)
ge_survey <- combined %>%
  filter(sample == "Quota" | east_german == 1)
cat("  Combined (Quota Western + all Eastern):", nrow(ge_survey), "\n")

# d) Remove duplicates (quota Eastern Germans appear in both streams — keep Over version)
ge_survey <- ge_survey %>%
  arrange(ResponseId, desc(sample == "Over")) %>%
  distinct(ResponseId, .keep_all = TRUE)
cat("  After deduplication:", nrow(ge_survey), "\n")

# e) Age and missing data filters
ge_survey <- ge_survey %>%
  filter(age >= 18, age <= 99,
         !is.na(current_state),
         !is.na(age),
         state_at_18 != "Keine Angabe" | is.na(state_at_18))
cat("  After age/missing filters:", nrow(ge_survey), "\n")

# f) Now derive three-level classification (Post-GDR) after combining
ge_survey <- ge_survey %>%
  mutate(
    gdr_birth = as.integer(birth_country == "Deutsche Demokratische Republik"),
    lived_12_gdr = as.integer(yob >= 1937 & yob <= 1978),
    gdr_continue = as.integer(gdr_birth == 1 & east_german == 1),
    gdr_true = as.integer(lived_12_gdr == 1 & gdr_continue == 1),
    east_germany_F = case_when(
      east_german == 0 & gdr_true == 0 ~ "Western German",
      east_german == 1 & gdr_true == 0 ~ "Eastern German",
      gdr_true == 1 ~ "Post-GDR citizen",
      TRUE ~ NA_character_
    )
  )

# 7. Join conjoint data with survey data
ge_new <- ge_conjoint %>%
  inner_join(
    ge_survey %>% select(
      ResponseId, age, yob, female,
      state_at_18, current_state, birth_country,
      education, party_vote, east_germany_F
    ),
    by = "ResponseId"
  )

n_ge <- n_distinct(ge_new$ResponseId)
cat("  Final respondents:", n_ge, "\n")
cat("  Final rows:", nrow(ge_new), "\n")

# Reorder columns
ge_new <- ge_new %>%
  select(
    ResponseId, question_profile, politician_choice,
    Democracy, Economy, Welfare, Gender, Diversity,
    east_germany_F, age, yob, female,
    state_at_18, current_state, birth_country,
    education, party_vote
  )

write_csv(ge_new, file.path(out_dir, "germany_politician.csv"), na = "")

# ===========================================================================
# SOUTH KOREA
# ===========================================================================
cat("\nProcessing South Korea...\n")

# 1. Read merged politician conjoint
sk_conjoint <- read_csv(
  file.path(base, "South Koreans/Data/merged_df.sk.pol.csv"),
  show_col_types = FALSE
) %>%
  select(ResponseId, question_profile, politician_choice,
         Democracy, Economy, Welfare, Gender, Diversity)

sk_conjoint_ids <- unique(sk_conjoint$ResponseId)
cat("  Conjoint respondents:", length(sk_conjoint_ids), "\n")

# 2. Read Qualtrics files
# February file (CBC export)
sk_feb <- read_qualtrics(
  file.path(base, "South Koreans/Data/IFES 2023 - ROK_February 12, 2024_16.45.csv")
)

# January file (quota/direct questions)
sk_jan <- read_qualtrics(
  file.path(base, "South Koreans/Data/IFES 2023 - ROK_January 11, 2024_18.44.csv")
)
cat("  January Qualtrics rows:", nrow(sk_jan), "\n")

# 3. Extract survey variables from January file
sk_survey <- sk_jan %>%
  filter(ResponseId %in% sk_conjoint_ids) %>%
  select(
    ResponseId,
    gender_raw = Q2,
    province = Q3,
    yob = Q4,
    education = Q5,
    political_ideology = Q12,
    party_vote = Q13
  ) %>%
  mutate(
    yob = as.numeric(yob),
    age = 2023 - yob,
    female = as.integer(gender_raw == "여성")
  ) %>%
  select(-gender_raw)

cat("  Matched survey respondents:", nrow(sk_survey), "\n")

# 4. Filter: remove overseas residents
sk_survey <- sk_survey %>%
  filter(province != "해외" | is.na(province))
cat("  After removing overseas:", nrow(sk_survey), "\n")

# 5. Join conjoint with survey (inner join keeps only matched)
sk_new <- sk_conjoint %>%
  inner_join(sk_survey, by = "ResponseId")

n_sk <- n_distinct(sk_new$ResponseId)
cat("  Final respondents:", n_sk, "\n")
cat("  Final rows:", nrow(sk_new), "\n")

# Reorder columns
sk_new <- sk_new %>%
  select(
    ResponseId, question_profile, politician_choice,
    Democracy, Economy, Welfare, Gender, Diversity,
    age, yob, female,
    province, education, political_ideology, party_vote
  )

write_csv(sk_new, file.path(out_dir, "korea_politician.csv"), na = "")

# ===========================================================================
# NORTH KOREA
# ===========================================================================
cat("\nProcessing North Korea...\n")

# 1. Read merged politician conjoint
nk_conjoint <- read_csv(
  file.path(base, "North Koreans/Data/merged_df.nk.pol.csv"),
  show_col_types = FALSE
) %>%
  rename(ResponseId = id) %>%
  select(ResponseId, question_profile, politician_choice,
         Democracy, Economy, Welfare, Gender, Diversity)

nk_conjoint_ids <- unique(nk_conjoint$ResponseId)
cat("  Conjoint respondents:", length(nk_conjoint_ids), "\n")

# 2. Read NK Qualtrics (choice-text version for readable responses)
# The QMD assigns IDs BEFORE removing header rows: id = 1:nrow(raw), then removes
# rows 1-2 (Qualtrics sub-headers). This file has only 2 header rows (no import ID
# row), so we use skip=2 and offset IDs by 2 to match the QMD's numbering.
nk_raw <- read_csv(
  file.path(base, "North Koreans/Data/choice-text_IFES+2023+-+North+Koreans_October+23,+2023_09.46.csv"),
  skip = 2,
  col_names = read_csv(
    file.path(base, "North Koreans/Data/choice-text_IFES+2023+-+North+Koreans_October+23,+2023_09.46.csv"),
    n_max = 0, show_col_types = FALSE
  ) %>% names(),
  show_col_types = FALSE
)
# NK data uses row number as ID (assigned before header removal in QMD, so offset by 2)
nk_raw$nk_id <- 2 + (1:nrow(nk_raw))

# Filter to conjoint respondents
# Note: NK Qualtrics has duplicate column names (Q2, Q3, Q4 appear twice).
# read_csv auto-suffixes: Q2...20 (yob), Q3...21 (birthplace), Q4...28 (defection year).
# Q7 = education, Q20 = current residence.
nk_survey <- nk_raw %>%
  filter(nk_id %in% nk_conjoint_ids) %>%
  select(
    ResponseId = nk_id,
    gender_raw = Q6,
    yob = `Q2...20`,
    education_nk = Q7,
    province_birth = `Q3...21`,
    year_defection = `Q4...28`,
    year_arrived_sk = Q18,
    current_residence = Q20
  ) %>%
  mutate(
    yob = as.numeric(yob),
    age = 2023 - yob,
    female = as.integer(gender_raw == "여성"),
    year_defection = as.numeric(year_defection),
    year_arrived_sk = as.numeric(year_arrived_sk),
    years_in_nk = year_defection - yob,
    years_in_sk = 2023 - year_arrived_sk
  ) %>%
  select(-gender_raw)

cat("  Matched survey respondents:", nrow(nk_survey), "\n")

# 3. Join conjoint with survey
nk_new <- nk_conjoint %>%
  inner_join(nk_survey, by = "ResponseId")

n_nk <- n_distinct(nk_new$ResponseId)
cat("  Final respondents:", n_nk, "\n")
cat("  Final rows:", nrow(nk_new), "\n")

# Reorder columns
nk_new <- nk_new %>%
  select(
    ResponseId, question_profile, politician_choice,
    Democracy, Economy, Welfare, Gender, Diversity,
    age, yob, female,
    province_birth, education_nk,
    year_defection, year_arrived_sk, years_in_nk, years_in_sk,
    current_residence
  )

write_csv(nk_new, file.path(out_dir, "nk_politician.csv"), na = "")

# ===========================================================================
cat("\n=== Summary ===\n")
cat("Germany:", n_ge, "respondents,", nrow(ge_new), "rows\n")
cat("South Korea:", n_sk, "respondents,", nrow(sk_new), "rows\n")
cat("North Korea:", n_nk, "respondents,", nrow(nk_new), "rows\n")
cat("Files written to", out_dir, "\n")
