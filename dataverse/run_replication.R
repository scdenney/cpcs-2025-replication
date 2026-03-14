# One-click replication script
# Installs required packages and runs the full analysis

cat("=== Replication: From Division to Democracy (CPCS 2025) ===\n\n")

# Install packages if needed
required <- c("tidyverse", "ggthemes", "MatchIt", "cowplot")
for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

if (!requireNamespace("cregg", quietly = TRUE)) {
  cat("Installing cregg from GitHub...\n")
  if (!requireNamespace("remotes", quietly = TRUE))
    install.packages("remotes", repos = "https://cloud.r-project.org")
  remotes::install_github("leeper/cregg")
}

cat("\nAll packages available. Running analysis...\n\n")
source("code/analysis.R")
