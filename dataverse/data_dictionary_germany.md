# Data Dictionary: `germany_politician.csv`

German politician conjoint experiment data (n = 2,071 respondents, 33,136 rows).

## Identifiers

| Variable | Description |
|----------|-------------|
| `ResponseId` | Unique respondent identifier (Qualtrics) |
| `question_profile` | Task and profile number (e.g., "1.1" = task 1, profile 1) |
| `politician_choice` | Forced-choice outcome: 1 = selected this profile, 0 = not selected |

## Conjoint Attributes (5)

All values are in German (original survey language). See translations below.

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
| `east_germany_F` | Regional-historical classification | "Western German", "Eastern German", "Post-GDR citizen" |
| `age` | Age in 2023 (= 2023 − yob) | Integer |
| `yob` | Year of birth | Integer |
| `female` | Sex | 1 = female, 0 = male |
| `state_at_18` | German state of residence at age 18 (Q5) | German state names (in German) |
| `current_state` | Current German state (Q6) | German state names (in German) |
| `birth_country` | Country of birth (Q3) | In German |
| `education` | Highest education level (Q8) | In German |
| `party_vote` | Party vote intention (Q11) | In German |

## Classification Logic

**Western German**: Q5 (state at age 18) is a western state and not born in GDR or does not meet Post-GDR criteria.

**Eastern German**: Q5 is Berlin or an eastern state (Brandenburg, Mecklenburg-Vorpommern, Sachsen, Sachsen-Anhalt, Thüringen, Ost-Berlin), without Post-GDR socialization.

**Post-GDR citizen**: Born in "Deutsche Demokratische Republik" (Q3), currently resides in an eastern state (Q5), and born between 1937–1978 (spent at least 12 formative years in the GDR).
