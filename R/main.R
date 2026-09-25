# =============================================================================
# Signals of famine: citizen science tracking of adult weight in
# the Gaza Strip, 2025
# =============================================================================

# =============================================================================
# Runs the pipeline from raw ODK forms to the rendered report.
# Run from the repo root (paths are anchored by here::here).
# =============================================================================

pacman::p_load(here)

# Raw ODK forms to one long dataset, data/processed/participants.csv, plus the
# record-level exclusion counts in data/processed/data-quality.csv.
source(here("R", "clean.R"))

# Tables and figures for the manuscript
# rendered to report/results.html (for review) and report/results.docx (for draft)
# Figures are also written to outputs/figures/.
quarto::quarto_render(here("report", "results.qmd"))
