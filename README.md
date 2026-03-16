<div align="center">

<img alt="From Division to Democracy" src="https://img.shields.io/badge/%F0%9F%87%A9%F0%9F%87%AA_%F0%9F%87%B0%F0%9F%87%B7-From_Division_to_Democracy-2c3e50?style=for-the-badge&labelColor=1a1a2e">

**How Political Socialization Shapes Citizen Preferences in Germany and Korea**

*Brehm, Zhou, & Denney (2025) &mdash; Communist and Post-Communist Studies (UC Press)*

[![DOI: Paper](https://img.shields.io/badge/DOI-10.1525%2Fcpcs.2025.2636997-blue?style=flat-square)](https://doi.org/10.1525/cpcs.2025.2636997) [![Open Science](https://img.shields.io/badge/Open_Science-Replication_Materials-brightgreen?style=flat-square&logo=opensourceinitiative&logoColor=white)](https://github.com/scdenney/cpcs-2025-replication) [![R](https://img.shields.io/badge/R-%E2%89%A5_4.0-276DC3?style=flat-square&logo=r&logoColor=white)](#requirements)

</div>

---

## Overview

This package replicates the **politician conjoint experiment** from:

> Brehm, Robin, Zhou, Tianzi, and Steven Denney. 2025. "From Division to Democracy: How Political Socialization Shapes Citizen Preferences in Germany and Korea." *Communist and Post-Communist Studies*. DOI: [10.1525/cpcs.2025.2636997](https://doi.org/10.1525/cpcs.2025.2636997)

The experiment investigates how political socialization under divided-nation regimes shapes citizen preferences for emerging politicians. Respondents evaluate hypothetical politician profiles characterized by five political attributes (views on democracy, economy, welfare, gender, and diversity). Three populations are studied: Germans (Western, Eastern, Post-GDR citizens), South Koreans, and North Korean migrants living in South Korea.

Replication materials are also archived on Harvard Dataverse.

> Denney, Steven. 2026. “Replication Data for: From Division to Democracy: Integrating Post-Socialist Citizens in Germany and South Korea.” Harvard Dataverse. [https://doi.org/10.7910/DVN/8GUUP5](https://doi.org/10.7910/DVN/8GUUP5)

## Repository Structure

```
.
├── README.md
├── run_replication.R        # One-click: installs packages + runs analysis
├── Makefile                 # make → runs analysis from command line
├── code/
│   ├── analysis.R           # Full analysis (variable derivation → models → figures)
│   └── prepare_data.R       # Data provenance (requires original Qualtrics; not needed to replicate)
├── data/
│   ├── germany_politician.csv
│   ├── korea_politician.csv
│   └── nk_politician.csv
└── docs/
    ├── data_dictionary_germany.md
    ├── data_dictionary_korea.md
    └── data_dictionary_nk.md
```

## Data

Each CSV contains **raw survey responses** in the original language (German/Korean) alongside conjoint task data. One row = one candidate profile shown in a forced-choice task.

| Category | Variables |
|----------|-----------|
| **Identifiers** | `ResponseId`, `question_profile`, `politician_choice` |
| **Conjoint attributes** | `Democracy`, `Economy`, `Welfare`, `Gender`, `Diversity` |
| **Demographics** | `age`, `yob`, `female`, `education`, `state_at_18`/`province`, `current_state` |
| **Sample-specific** | `east_germany_F`, `birth_country` (DE), `political_ideology`, `party_vote` (KOR), `year_defection`, `year_arrived_sk` (NK) |

All derived analysis variables (subgroup classifications, cohort definitions, partisan groups) are constructed transparently in `code/analysis.R` from these raw inputs. See `docs/` for complete variable definitions and response value translations.

## Quickstart

```r
# Option 1: One-click (installs dependencies automatically)
source("run_replication.R")

# Option 2: Manual
install.packages(c("tidyverse", "ggthemes", "MatchIt", "cowplot", "remotes"))
remotes::install_github("leeper/cregg")
source("code/analysis.R")
```

```sh
# Option 3: Command line
make
```

Outputs: `output/` (CSVs + session info) and `output/figures/` (PDF + PNG).

## Figure Mapping

### Main paper figures

| Paper Figure | Description | Output files |
|:------------:|-------------|--------------|
| 1 | Germany: Marginal means by subgroup (Western, Eastern, Post-GDR) | `fig1_germany_mm` |
| 2 | Korea: Marginal means (Native SK vs Post-DPRK citizen) | `fig2_korea_mm` |
| 3 | Matched samples (nearest-neighbor on age, sex, education) | `fig3_korea_matched`, `fig3_germany_matched` |

### Supplementary Information (Appendix D)

| SI Figure | Description | Output files |
|:---------:|-------------|--------------|
| D.1 | German regional subgroups (North, South, East) | `fig_D1_german_regions` |
| D.2 | German regions × partisanship | `fig_D2_german_partisanship` |
| D.3 | Korean generational cohorts | `fig_D3_korean_cohorts` |
| D.4 | Korean partisanship subgroups | `fig_D4_korean_partisanship` |

## Samples

| Country | Respondents | Tasks per respondent | Rows |
|---------|:-----------:|:--------------------:|:----:|
| Germany | 2,071 | 8 tasks × 2 profiles | 33,136 |
| South Korea | 1,994 | 7 tasks × 2 profiles | 27,916 |
| North Korean migrants | 311 | 10 tasks × 2 profiles | 6,220 |

## Requirements

- **R** >= 4.0 (tested with 4.5.1)
- [`tidyverse`](https://tidyverse.tidyverse.org/), [`cregg`](https://github.com/leeper/cregg), [`ggthemes`](https://jrnold.github.io/ggthemes/), [`MatchIt`](https://kosukeimai.github.io/MatchIt/), [`cowplot`](https://wilkelab.org/cowplot/)

## License

These materials are distributed under the terms of the [Creative Commons Attribution License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/), which permits unrestricted reuse, distribution, and reproduction in any medium, provided the original work is properly cited.
