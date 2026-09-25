# Restructure results.qmd into a coauthor-ready Results report

---

\
Pick up the plan file (\`the-code-here...\`) - review; we want a simple, clear, and best-practice analysis, as simple as possible and no less.
Move recall bias up to a sensitivity check, and drop the baseline adjustment (as long as we are using log difference).

---

## Context

`report/results.qmd` is now the single analysis document, but it is organised around how the analysis was built rather than around what the paper claims.
The draft manuscript (`report/gaza_adult_weight_draft.docx`) has a Results section whose tables and figures are hand-maintained and were written against an older version of the analysis: its Table 1 is not produced by any current code, its Table 3 sits in the Discussion with a coauthor margin note asking for it to move, and its category definitions no longer match the code.

Goal: one document a coauthor can read and paste into the Word draft, with the requested analysis improvements, ordered as the manuscript is ordered.
Diagnostics and sensitivity work go to a Supplementary section — which is what the coauthor's own margin note asks for.

`report/results_bayes.qmd` is retired and folded back in.
It currently fails to render anyway (fix below).

## Deliverable

`report/results.qmd` rendering to two formats:

-   `results.docx` — for pasting into the draft
-   `results.html` — for review

`flextable` for every table, in both formats: it renders to real editable Word tables and to HTML, so no format dispatcher is needed.
Table 1 comes from `gtsummary::tbl_summary(by = organisation) |> add_overall() |> as_flex_table()`, matching the draft's SCI / UNRWA / Total columns.
SCI is n = 13 against UNRWA n = 423, so it stays descriptive; no modelling by organisation.

Note: `results.md` stops being produced.
Nothing reads it.

## Work, in your priority order

### A. Improvements to existing work

#### 6. Calendar time with a ceasefire breakpoint

You are right that a single linear within-person slope is wrong, and the data show why.

The current model uses time-in-study (`days_since_entry`).
Under a ceasefire breakpoint that axis is actively misleading: someone entering in August reaches their day 30 in September, while the war is still on; someone entering in late October reaches their day 30 in November, after the ceasefire.
Averaging those into one slope mixes decline and recovery, which is exactly the artefact the current model is meant to avoid.

Replace with a piecewise-linear calendar model, break fixed at 10 October 2025:

``` r
bmi ~ t_pre + t_post + entry_day + (1 | id)
# t_pre  = pmin(record_day, ceasefire_day) - study_start_day
# t_post = pmax(record_day - ceasefire_day, 0)
```

`t_pre` is the pre-ceasefire slope, `t_post` the post-ceasefire slope.
Both are estimated within-person because of the participant random intercept.

Data support, checked before proposing this:

| Longitudinal participants            | n   |
|--------------------------------------|-----|
| Observations entirely pre-ceasefire  | 36  |
| Observations entirely post-ceasefire | 20  |
| Spanning the ceasefire               | 50  |

219 records fall before the break and 131 after.
The 50 spanners are what identify the change in slope, and because they are the same people either side, that estimate cannot be confounded by composition.

The identification constraint to state plainly in the text: only 2 participants entered between the 1 October re-advertisement and the 10 October ceasefire.
Entry wave and ceasefire period are therefore near-perfectly confounded between people — no between-person contrast can separate "the ceasefire improved food access" from "different people joined in October".
Only within-person change across the break separates them.

That finding reorders the results by itself: the paired within-person analysis is essentially those 50 spanners, which is why it should lead (your item 2) rather than appear as a companion.

`entry_day` stays as a continuous person-level term to test for composition drift within each recruitment window, but it cannot resolve the confounding above and the text should not imply it does.
Random slopes are not attempted — most participants have two or three observations.

Fixed break at the ceasefire date is the primary specification.
An estimated changepoint goes in the Supplement if it is worth the fit; the existing calendar-date GAM already serves as the smooth-trend check.

`entry_cohort` stays as-is for the descriptive tables.
Only the longitudinal models change.

#### 4. Partial pooling instead of hand-collapsed categories

Restore the original categories — five governorates, the full role list — and let a hierarchical prior do the shrinking:

``` r
brm(bmi_change ~ age + sex + children + (1 | governorate) + (1 | role), ...)
```

Rafah (n = 8), North Gaza (n = 20) and the single-person role levels shrink toward the mean rather than being merged by hand.
This also makes the tables match the draft's Table 1 instead of diverging from it.

Caveat for the text: with five governorates and six roles the group-level standard deviation is weakly identified, so the prior matters.
Use a half-normal prior on it, report the prior beside the estimate, and show the pooled and current collapsed estimates side by side so the shrinkage is visible.

### B. Useful additions

#### 7. Model who returns

1.  Return model: `has_followup ~ bmi_entry + pct_weight_change + age + sex + governorate + role + entry_day`, logistic. Answers whether returning depends on nutritional state — the informative-dropout question the current selection check only approaches sideways.
2.  Sensitivity: refit the recovery model with inverse-probability-of-return weights from (1). If the slopes are unchanged, dropout is not generating the recovery.

The existing follow-up comparison table stays; this turns it from a nuisance check into an analysis with a stated conclusion.

#### 2 and 1. Reorder

| Section | Content |
|------------------------------------|------------------------------------|
| Participation and characteristics | Table 1 (gtsummary), observations over time |
| Nutritional status at entry | Measured BMI distribution, categories, thresholds — new lead |
| Change since pre-war | Recall-based |
| Associations | BMI change in the text, both outcomes in tables and figures |
| Recovery during follow-up | Paired within-person first, then the piecewise calendar model |
| Comparison with the 2020 survey | Unchanged |
| Selection and measurement checks | Return model, equivalence tests, digit preference |
| Supplementary | Diagnostics, sensitivity fits, GAM |

### C. Deferred to a later pass, both into the Supplement

Stopping to review the report before these.
Recorded here so they are not lost.

-   Recall error. Rounding granularity is observable per record: rounding to the nearest `k` implies a standard deviation of `k/sqrt(12)`, so 1.44 kg for 5 kg rounding and 0.29 kg for 1 kg. Monte Carlo propagation for the headline; `brms::me()` for the associations. Widens intervals, does not move estimates — systematic recall bias is not identifiable without a gold standard, and that must be said rather than implied away.
-   Baseline adjustment and the mediator question. Percent weight change is already a proportional scale, and `log(weight_entry / weight_prewar)` is its cleaner form; that is the standard way to handle "someone heavier has more to lose", by construction rather than by conditioning. Conditioning on a recalled baseline on top is a different and contested operation. Test with five specifications — change score unadjusted, change score plus baseline, ANCOVA, log ratio, ANCOVA with measurement error — and tabulate the coefficients. References to check before citing: Vickers and Altman BMJ 2001; Glymour et al. Am J Epidemiol 2005; Tu and Gilthorpe on mathematical coupling.

### D. Not doing

-   Item 3 (dropping an outcome): both were preregistered. BMI change leads the text, both appear in every table and figure.
-   Item 5 (imputing chronic condition): deferred as agreed.

## Fix required first

`results_bayes.qmd` fails at `tbl-cohort-equivalence`.
`bayestestR::equivalence_test()` returns `HDI_low` and `HDI_high`, not `CI_low` and `CI_high`.
One-line fix, carried across when the file is folded in.

## Model inventory and runtime

Around a dozen fitted models.
`brms` for the new and structurally complex ones — hierarchical exposures, piecewise calendar, weighted sensitivity — each cached to disk with `file =` so a compile is paid once and survives a cache clear.
`rstanarm` stays for the eight two-group equivalence fits: precompiled, and no reason to pay a compile for `y ~ group`.

Cold render likely 20 to 30 minutes, dominated by Stan compiles.
Render detached with a log per the long-job convention.
Add `report/_brms/` to `.gitignore` alongside the existing `*_cache/` rule.

## Sequencing

Each step renders and is reviewable alone.

1.  Fold in `results_bayes.qmd` with the `HDI_low` fix; switch to html plus docx with flextable; retire the parallel file.
2.  Reorder into manuscript order; add Table 1; move diagnostics to the Supplement.
3.  Item 6, piecewise calendar model.
4.  Item 4, partial pooling.
5.  Item 7, return model and weighted sensitivity.
6.  Stop. Review the report.

## State at handover (17 August 2026)

Nothing is committed.
All work is in the git working tree on branch `refactor-analysis`, so it survives closing the session.

Done and verified in the previous session:

-   `R/analyse.R` deleted; its contents folded into `report/results.qmd`, which is now the single analysis document. Every result table was checked against a baseline run of the old script and matched to zero difference.
-   `data/processed/results/` removed — nothing read it. `R/main.R`, `README.md` and `R/README.md` updated to point at `results.qmd`.
-   `report/results.qmd` renders clean from an empty cache. `styler` reports no changes needed.

Done but not yet verified:

-   `report/results_bayes.qmd` — copy of `results.qmd` with three inference steps re-fitted by posterior sampling (longitudinal slope, age interaction, selection equivalence tests). It does not render: `bayestestR::equivalence_test()` returns `HDI_low`/`HDI_high`, not `CI_low`/`CI_high`, so `table_equivalence()` fails at `tbl-cohort-equivalence`. This file is folded into `results.qmd` and retired at step 1 above, so fix it there rather than repairing it in place.
-   A factual correction applied to both `results.qmd` and `results_bayes.qmd`: the prose claiming digit heaping is "absent in the measured value" was contradicted by its own table (measured 47.8% whole kg against recalled 56.1%). Reworded to say the excess, not the presence, is what quantifies recall coarseness. `results.qmd` has not been re-rendered since this edit.

Facts established by data checks, so they do not need repeating:

| Check | Value |
|------------------------------------|------------------------------------|
| `cor(pct_weight_change, bmi_change)` | 0.948 |
| Chronic condition missing | 290 of 435 |
| Digit heaping, whole kg | recalled 56.1%, measured 47.8% |
| Longitudinal participants spanning the 10 Oct ceasefire | 50 (36 entirely pre, 20 entirely post) |
| Records either side of the ceasefire | 219 pre, 131 post |
| Entered between 1 Oct re-advertisement and 10 Oct ceasefire | 2 |
| Organisation split | SCI 13, UNRWA 423 |
| Role levels | National staff 290, Casual/daily worker 129, Other 12, Prefer not to answer 3, Consultant 1, Expatriate 1 |
| Entry date range | 30 Jul to 13 Nov 2025 |

Installed and confirmed: brms 2.23.1, rstanarm 2.32.2, cmdstan 2.39.0, bayestestR 0.17.0, tidybayes, posterior, loo, gtsummary, flextable, broom.helpers 1.22.0.

First action tomorrow: the verification baselines from the previous session lived in a session-scoped scratchpad and are gone.
Re-establish one by rendering `report/results.qmd` detached and keeping the output before making any changes.

## Verification

1.  Snapshot the current rendered numbers before starting.
2.  After each step, render detached and diff against the previous render. Every number a step should not touch must be unchanged; steps 3 to 5 change specific models and nothing else.
3.  Check sampler diagnostics for every Stan fit: R-hat at or below 1.01, no divergent transitions, bulk ESS in the thousands. These go in the Supplement as a table, so a bad fit is visible rather than silent.
4.  Confirm the `stopifnot()` participant-set guards still pass — they are what catches a data refresh changing the analytic sets.
5.  Open the docx and confirm tables paste into Word as tables, not as text.
6.  Sanity check on the hierarchical models: partial pooling should reproduce the collapsed-category results when the group variance is near zero.
7.  Sanity check on the piecewise model: the post-ceasefire slope should agree with the paired within-person estimate from the 50 spanners, since they use the same contrast.