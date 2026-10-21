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

# Manuscript and supplement, each rendered to html and docx in report/.
# Each sources R/utils.R, R/data.R and the topic files it uses.
# Figures are also written to outputs/figures/.
quarto::quarto_render(here("report", "manuscript.qmd"))
quarto::quarto_render(here("report", "supplement.qmd"))
