# Data Dictionary: `nk_politician.csv`

North Korean migrant politician conjoint experiment data (n = 311 respondents, 6,220 rows).

## Identifiers

| Variable | Description |
|----------|-------------|
| `ResponseId` | Row-based respondent ID (numeric, assigned during QMD processing) |
| `question_profile` | Task and profile number (e.g., "1.1" = task 1, profile 1) |
| `politician_choice` | Forced-choice outcome: 1 = selected this profile, 0 = not selected |

## Conjoint Attributes (5)

All values are in Korean (original survey language). Identical attribute levels as the South Korean sample.

| Variable | Levels | English Translation |
|----------|--------|---------------------|
| `Democracy` | 3 | "Democracy is best despite problems" / "Democracies mismanage the economy" / "Democracies are indecisive and disorderly" |
| `Economy` | 2 | "Greater freedom to firms" / "More state control" |
| `Welfare` | 2 | "Individual responsibility" / "More state responsibility" |
| `Gender` | 3 | "Gender neutral" / "Pro-gender equity" / "Pro-patriarchy" |
| `Diversity` | 3 | "Diversity erodes unity" / "Diversity is socially enriching" / "Diversity is economically beneficial" |

## Respondent-Level Variables

| Variable | Description | Values |
|----------|-------------|--------|
| `age` | Age in 2023 (= 2023 − yob) | Integer |
| `yob` | Year of birth (Q2) | Integer |
| `female` | Sex (Q6) | 1 = female (여성), 0 = male |
| `province_birth` | Province of birth in North Korea (Q3) | In Korean (NK provinces) |
| `education_nk` | Highest education in North Korea (Q7) | In Korean |
| `year_defection` | Year of defection from NK (Q4) | Integer |
| `year_arrived_sk` | Year arrived in South Korea (Q18) | Integer |
| `years_in_nk` | Years lived in NK (= year_defection − yob) | Integer |
| `years_in_sk` | Years lived in SK (= 2023 − year_arrived_sk) | Integer |
| `current_residence` | Current residence in South Korea (Q20) | In Korean |

## Notes

- Recruited via Woorion NGO (North Korean migrant resettlement organization).
- Sample is predominantly female (~77%) and Seoul-based (~83%), reflecting the NK migrant population in South Korea.
- Some demographic variables may have missing values due to survey non-response.
