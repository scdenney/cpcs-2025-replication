# Data Dictionary: `korea_politician.csv`

South Korean politician conjoint experiment data (n = 1,994 respondents, 27,916 rows).

## Identifiers

| Variable | Description |
|----------|-------------|
| `ResponseId` | Unique respondent identifier (Qualtrics) |
| `question_profile` | Task and profile number (e.g., "1.1" = task 1, profile 1) |
| `politician_choice` | Forced-choice outcome: 1 = selected this profile, 0 = not selected |

## Conjoint Attributes (5)

All values are in Korean (original survey language). See translations below.

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
| `yob` | Year of birth | Integer |
| `female` | Sex | 1 = female (여성), 0 = male |
| `province` | Province/city of residence (Q3) | In Korean (17 administrative divisions) |
| `education` | Highest education level (Q5) | In Korean |
| `political_ideology` | Self-reported political ideology (Q12) | In Korean (매우 진보적 to 매우 보수적) |
| `party_vote` | Party support (Q13) | In Korean |

## Notes

- Overseas residents (해외) were excluded during data preparation.
- Survey administered via Qualtrics online panel (quota sample).
