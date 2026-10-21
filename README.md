**Analysis of nutritional status among humanitarian aid staff in the Gaza Strip**

Based on work in: https://github.com/cmmid/gaza-response 

---

Repo structure:

- [data/](data/): individual-level files excluded from public repo
  - [raw/](data/raw/): csv files are .gitignored, except three public or aggregate extracts: the 2020 survey comparison table, NCD-RisC reference BMI prevalences, and the US Census Bureau IDB population of the Gaza Strip
  - [processed/](data/processed/): all csv files are .gitignored
  - `context/`: public source files for the extracts (ignored)
- [R/](R/): data processing and analysis code. See [Quickstart](R/README.md) for how to run it
  - [main.R](R/main.R): runs the pipeline, from raw forms to rendered manuscript and supplement
  - [clean.R](R/clean.R): raw ODK forms to one long dataset
  - [utils.R](R/utils.R), [data.R](R/data.R): shared helpers and the analysis set
  - [ncdrisc-extract.R](R/ncdrisc-extract.R): builds the NCD-RisC and IDB extracts in `data/raw/` from `data/context/`; run by hand
  - [participation.R](R/participation.R), [prewar.R](R/prewar.R), [followup.R](R/followup.R), [context.R](R/context.R): one file per topic, each ending with the numbers quoted in the text
- [report/](report/)
  - [manuscript.qmd](report/manuscript.qmd): manuscript text, main tables and figures
  - [supplement.qmd](report/supplement.qmd): supplementary tables and figures
  - [TODO-report.md](report/TODO-report.md): outstanding edits and review notes
  - [gaza.bib](report/gaza.bib): bib file for referencing
- [outputs/figures/](outputs/): figures at print size, written by the qmds (ignored)
- [attic/](attic/)
  - [protocol.docx](attic/protocol.docx): study protocol
  - [fc-draft-2025.qmd](attic/fc-draft-2025.qmd): previous draft write-up
  - [fc-gaza-report-2026-09/](attic/fc-gaza-report-2026-09/): superseded Bayesian analysis and earlier results report
  - [ncdrisc-standardisation-2026-10/](attic/ncdrisc-standardisation-2026-10/): superseded standardisation of underweight to NCD-RisC reference BMI
