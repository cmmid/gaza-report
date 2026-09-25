**Analysis of nutritional status among humanitarian aid staff in the Gaza Strip**

Based on work in: https://github.com/cmmid/gaza-response 

---

Repo structure:

- [data/](data/): files excluded from public repo
  - [raw/](data/raw/): all csv files are .gitignored
  - [processed/](data/processed/): all csv files are .gitignored
- [R/](R/): data processing code
  - [main.R](R/main.R): runs the pipeline, from raw forms to rendered report
  - [clean.R](R/clean.R): raw ODK forms to one long dataset
  - See [Quickstart](R/README.md) for how to run it
- [report/](report/)
  - [results.qmd](report/results.qmd): the analysis. Data quality and exclusions, participant characteristics, change since pre-war, associations, recovery during follow-up, and the selection checks, in one document, rendered to `results.html` and `results.docx`. Descriptive statistics with simple frequentist models: `t.test`, `lm`, `glm` and one `lmer`
  - [gaza.bib](report/gaza.bib): bib file for referencing
- [outputs/figures/](outputs/): manuscript figures at print size, written by the report
- [attic/](attic/)
  - [protocol.docx/](attic/protocol.docx): study protocol
  - [fc-draft-2025.qmd](attic/fc-draft-2025.qmd): previous draft write-up
