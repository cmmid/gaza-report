# Open, 2026-10-19

Everything below "Archive" is the earlier log, kept unchanged; S-numbers there predate the current supplement.

## Facts to confirm

- Chronic-condition question: Methods say "from August". Data: 4 answers in mid-August, then none until the week of 19 October (144 asked). Check the ODK form history.
- Devices: Abstract says "personal devices"; Methods say "weight scales and mobile phones" and "mobile phones or computers".
- Advertisement dates: Figure S1 marks 25 July and 19 October (`advert_dates` in `R/participation.R`). Source for 25 July?
- ID options: Methods give two (national ID, or composite sequence). Confirm.
- Sex vs gender: form wording.
- PCBS figures in the Discussion (8% of people over 15 employed in 2025; women 12% of the employed in 2023), entered by hand.

## Text

- Return for follow-up: "in all other respects ... similar" leaves out enrolment cohort (Oct-Nov cohort much less likely to return; Table S3).
- Abstract says older participants and men lost the most weight; the Discussion does not mention sex.
- Methods: the log ratio "treats weight change as proportional". Table S6 shows larger % loss at higher pre-war BMI (normal 11.0%, overweight or obese 17.4%), so proportionality holds only partly. Qualify?
- S-numbers in both qmds are typed by hand; recheck if anything in the supplement moves.

## Statements and files

- Contributors; competing interests (Zeina's query); Declaration of Helsinki clause; patient and public involvement wording; author reflexivity statement; STROBE checklist.
- Survey forms for the Supplement (placeholder in `supplement.qmd`).
- References added to `gaza.bib` by hand, to add to Zotero or they are lost on re-export: German 2001, NGO joint statement 2025, Zenodo dashboard record, US Census Bureau IDB 2025, PCBS economic forecasts 2025, PCBS labour force survey 2023.

## Figures

- Main displays are now four (Table 1, Figures 1-3) against the self-imposed target of three; BMJ Global Health allows five.
- Figure 1 (new): A, participant flow from records received to exclusions, enrolment, then two branches: change since pre-war (all 434) and follow-up (106 returned, 104 analysed); B, weekly measurements (enrolment, linked and unlinked follow-up, hatched) with adverts, dashboard dates, famine confirmation and ceasefire. Dashboard dates are typed by hand in `R/participation.R` from the gaza-response commit history.
- Figure 2: viridis by BMI category at enrolment, triangles for underweight, threshold lines on both axes; inset cross-tabulates category pre-war by enrolment.
- Figure 3 (moved from the supplement): forest plot of the adjusted estimates in Table 1.
- Supplement figures: S1 BMI pyramid, S2 ceasefire-spanning trajectories. Former participation and unlinked figures dropped (shown in Figure 1B).

## Done 2026-10-19

- Analysis split into topic files (`R/utils.R`, `data.R`, `participation.R`, `prewar.R`, `followup.R`, `context.R`); `R/numbers.R` replaced by `numbers_<topic>` in each file.
- Summary statistic: arithmetic mean % change kept, with a Methods sentence on the log-ratio models; geometric mean and median in Table S12 (sensitivity). Table S6 now mean (95% CI).
- Follow-up: fitted change 3.9 (2.6 to 5.1) percentage points with a delta-method CI; smooth edf 1.00 (linear). Paired change now uses participants spanning the ceasefire, as in Methods (same 50). Implausible-rate filter `> 1` kg/m2 per day, as in Methods (same 2 participants).
- Text: Table 1 CIs in the risk-factor paragraph corrected (sign and order); "lost -15.6%"; typos; Figure 2B to Figure 1B; Discussion compares like-for-like loss from mean weights (16.4%; Table S13).
- Figures S2 and S4 now cited; saved figure files named by display number.
- Standardisation moved to "Comparison with reference populations" in Results, as in Methods.
- `ncdrisc-extract.R` moved from `attic/` to `R/`.
- Closed as resolved by the full draft: R5-R7, N2, N6, F1, F5, F6 (in part, see Text), C5, C8, unresolved markers except those above, ASK markers, WHO TRS 854, Hassneiah, "bootstrapped t", stale figure files, render time, `paired` vs `spans_ceasefire`, implausible filter, location labels. Uncited `gaza.bib` entries are left: they do not render, and hand edits are lost on re-export.

----

# Archive

# Review notes

Section, issue, suggested fix.
Numbers are from the current render.

## Results no longer supported by the analysis

-   R5 TODO premise "all associations null": not so. Adjusted CIs exclude zero for age (both levels), male -3.2% (-5.1 to -1.3), Deir Al Balah +3.5% (0.9 to 6.2), Oct-Nov entry +4.0% (1.8 to 6.3). Sex is not mentioned anywhere in the text and the Discussion says "sex differences were unremarkable". Fix: reconsider whether Table S4 belongs in main; report sex.
-   R6 Risk factors: "not a function of ... living with a chronic condition". Crude difference -5.8% (-9.0 to -2.3); adjusted, among the 140 asked, -3.9% (-8.2 to 0.5). Fix: report as weaker after adjustment, not as no association.
-   R7 Abstract, Discussion: "Weight restoration was evident between August and November", "moderate BMI recovery occurred from August onwards". GAM: fitted weight -17.9% of pre-war on 30 July to -14.0% on 1 December, linear (edf 1.0). Consistent, but the text should cite these numbers. \[agreed and soften the claim\]

## Numbers and facts

-   N2 Participation: "we removed 2 participants (5 observations) ... We present below analysis of the remaining 436 participants with 680 valid records". The 2 are removed from the longitudinal set only; 436/680 still includes them. Fix: reorder so the removal applies to follow-up analysis.
-   N3 Chronic condition asked "From August" (Methods, draft) vs "from September 2025" (qmd text, now in Methods scaffold). 4 answers in mid-August, then none until week of 19 October (145 of 436 answered).
-   N6 Participation paragraph and the scaffold bullets duplicate each other (single-observation share, cohort description). Merge when writing up.

## Unresolved markers

-   `[cite]` (Introduction, anecdotal weight loss), `[CITE]` (project description link), `[TODO: details on ID creation]`, `[TODO: data cleaning, pipeline production]`, dashboard Zenodo DOI as plain text, "available at:" with no URL (Methods), `[TODO: note gaza north...]` (Discussion), highlighted CoI note.
-   Supplement: survey questionnaires placeholder; Table S8 GLM still has the "do we need this as well as the balance table" TODO.
-   Abstract Background sentence is incomplete ("staff working for SCI and UNRWA.").

## Consistency and style

-   C5 Discussion IPC paragraph has two incomplete sentences ("While MUAC screening provides...", "While this single information stream provides ..., but").
-   C6 Supplementary captions render as "Table S 1" (space). Quarto limitation; fix by hand in the docx or with a Lua filter. \[ignore for now\]
-   C8 Data quality and sensitivity: "We compared our findings to a representative survey ... conducted in 2020, yielded pre-war BMI levels" is ungrammatical.

## Found 2026-10-08

-   F1 Enrolment cohorts differ by residence: Gaza City/North Gaza 47% (Aug-Sep) vs 14% (Oct-Nov); Deir Al Balah 16% vs 54%. Follow-up 33% vs 11%. Participation text claimed no differences. Cohort and governorate effects are hard to separate.
-   F5 Introduction: "mainly overweight in data from 2023" cites the 2022 paper whose survey was 2020.
-   F6 Discussion sentence "Participants who provided repeat measurements had similar enrolment characteristics" needs revising. Follow-up not balanced either (Table S4, adjusted ORs): dependent children ~2.2-2.3, Gaza City/North Gaza 0.44 (0.22-0.86), Oct-Nov cohort 0.18. Weight change since pre-war similar (-16.5% vs -15.4%). 

## Progress 2026-10-09

-   [ ] Kath to supply: N3 form date (Design sentence still says "From August"), F5, `[cite]`/`[CITE]`, confirm 2 vs 3 ID options, CoI, survey forms, nested-bracket CI format.

## Severity of weight loss, 2026-10-10

-   [x] Table S8: weight lost by pre-war BMI category (kg and %). Results scaffold: log ratio removes most, not all, dependence on starting weight (log-log slope 0.81).
-   [x] Table S12: underweight at enrolment standardised to NCD-RisC 2022 pre-war BMI distributions (Palestine; IPC Phase 5 countries in 2024 per GRFC 2025: Haiti, Mali, South Sudan, Sudan), by age and sex. Methods and Discussion scaffold bullets. Table S11 (2020 survey) renumbered from S10 to keep citation order.
-   [ ] Methods line on the outcome says it "treats weight change as proportional"; qualify given Table S7?
-   [ ] Check WHO TRS 854 wording and the 5-9% / 10-19% prevalence bands before citing grades.
-   [ ] Rendering now ~80 s longer per qmd (2000-resample bootstrap of the standardisation); reduce resamples if it matters.

## Underweight prevalence, 2026-10-12

-   [x] Underweight table (was S7) dropped; reported in text as a relative risk. Tables S8-S12 are now S7-S11; numbers in the notes above predate this.

----

# structure

## Full draft, 2026-10-13

`manuscript.qmd` is now complete prose under the paragraph headers, with no scaffold bullets.
Kath's edits of 13 October (title option, abstract, I1, I2, Methods wording) were kept and tidied; the copy before the rewrite is not in the repo.
Label used: participatory surveillance, panel study. "Real-time" is kept in the abstract and the M4 heading; Results give the cadence (hourly from 17 August).

### To confirm

Marked `CONFIRM` in the qmd.

| Statement | Where | Why |
|---|---|---|
| Protocol co-designed with SCI and UNRWA | M1, M11 | from the 13 October abstract; who took part is not stated |
| Devices: "mobile phones or computers" | M3 | abstract says standard-issue phones, the earlier draft said personal devices |
| Advertisement months, no dates | M3, Figure 1 | dates not found |
| Chronic condition question "added during the study" | M3 | review note N3; form history not checked |
| "Both forms are in the Supplement" | M3 | the Supplement still has a placeholder |
| Sex reported, gender not collected | M6 | form wording not checked |
| Conformed to the Declaration of Helsinki | Ethics | required by the journal; an attestation for the authors |
| Patient and public involvement: whether staff shaped the questions or the interpretation | M11 | not known, so not stated |
| About 8% of people aged 15 and over employed in 2025; women 12% of the employed in 2023 | D6 | PCBS figures entered by hand on 13 October |
| Contributors statement | end | not written |
| Competing interests, Zeina | end | open query |

### New in the analysis text

- Timeliness of submission: days from the date recorded on each form to `SubmissionDate`, computed in the manuscript setup chunk from the raw forms (all forms received, not only those analysed). `SubmissionDate` is server time; the recorded date is local.
- Odds of return (Table S4) refitted in the manuscript setup chunk for the inline odds ratios.
- Dashboard dates in R4 (first published 2 August, hourly from 17 August) are typed by hand from the commit history of `../gaza-response`.
- Famine confirmation, 22 August 2025: checked against the IPC release and the Food Security Cluster notice.
- Nine references added to `gaza.bib` by hand: McNeil 2022, Paolotti 2014, Ratnayake 2020, McGowan 2022, Meng 2018, Badker 2021 (all from Zotero, same citation keys), German 2001 (CDC guidelines), the NGO joint statement of 23 July 2025 (ReliefWeb), and the Zenodo record for the dashboard. Add the last three to Zotero or they are lost on re-export; the six from Zotero need adding to the `11-gaza` collection.

### Dropped, as possible extensions

| Idea | Why dropped | What it would need |
|---|---|---|
| Usefulness: who used the dashboard and for what | no record kept | agency focal points; GoatCounter referrers |
| Dashboard reach (page views) | no access to the analytics | GoatCounter login, `gaza-response.goatcounter.com` |
| Uptake as a proportion of staff invited | no denominator | staff in post at each agency during the study |
| Time from SCI's request to first measurement | request date not found | email thread, July 2025 |
| Advertisement dates on Figure 1 | dates not found | emails; ODK Central form history |
| Rule for small cells in the public aggregates | none found in `../gaza-response/R/data-pipeline` | confirm with Kevin |
| WHO grading of adult underweight prevalence (TRS 854) | wording not verified | the report itself |
| Claim that this is the first use for nutritional status in conflict | cannot be supported from the library | literature search (OpenAlex) |
| Economy, poverty line and pay in the Gaza Strip | sources unverified (parked below) | PCBS tables; agency pay scales |
| Reasons for low retention | not asked | exit question or interviews in a future round |
| Pre-war BMI against the world for underweight | cut for length; obesity kept in D4 | Table S12 has it |

## Restructure for BMJ Global Health, 2026-10-13

Target: Original research, held to 4000 words and 3 main displays (journal allows 5000 words, 5 displays, 100 references, 300-word abstract).
Method-led: participatory surveillance is the subject, weight change the proof of concept.
Each paragraph in `manuscript.qmd` sits under a header, `<!-- ID | words | job -->`.
Existing sentences were moved, not reworded; `CUT` comments mark text over budget.

| Section | Budget |
|---|---|
| Introduction (I1-I4) | 420 |
| Methods (M1-M11) | 1100 |
| Results (R1-R10) | 1110 |
| Discussion (D1-D8) and Conclusion | 1210 |
| Total | 3840 |

Displays: Figure 1 participation (was Figure S1); Table 1; Figure 2, A pre-war against enrolment BMI, B follow-up trajectory.
The ceasefire-spanning trajectory is now Figure S4.

Supplement renumbered to first citation in the Results.
S-numbers in the notes above this section predate it.

| Now | Was | Content |
|---|---|---|
| Figure S1 | Figure S2 | unlinked follow-up weights |
| Figure S2, S3 | Figure S3, S4 | BMI pyramid, change by characteristic; neither is cited in the manuscript |
| Figure S4 | Figure 2B | ceasefire-spanning trajectory |
| Table S8 | Table S11 | standardised to adults in the Gaza Strip |
| Table S9 | Table S8 | chronic condition |
| Table S10 | Table S9 | paired change |
| Table S11 | Table S10 | 2020 survey |
| Table S12 | Table S12 | NCD-RisC |

### To supply, and where from

| Gap | Used in | Source | Who |
|---|---|---|---|
| Request date from SCI | R4 | email thread, July 2025; protocol date in `attic/protocol.docx`; ethics letter, ID 32766 | Kath, Francesco |
| Advertisement dates | M3, Figure 1 | emails to agency focal points; ODK Central form version history | Kath, Kevin |
| Chronic-condition question date (N3) | M3 | ODK Central form version history | Kevin |
| Famine classification date | Figure 1 | set to 22 August 2025 in the figure chunk; check against the Famine Review Committee report | Kath |
| Where the update scheduler ran | M4 | not in `../gaza-response/.github/workflows/` (all manual triggers) | Kevin |
| Small-cell rule in published aggregates | M4 | `../gaza-response/R/data-pipeline` | Kath, Kevin |
| Measurement-to-submission lag | R4 | `SubmissionDate` in the raw forms; `R/clean.R` does not carry it into `participants.csv` | add to `clean.R` if wanted |
| Dashboard reach | R4 | GoatCounter, `gaza-response.goatcounter.com`, on the site since 31 July 2025; Zenodo record 10.5281/zenodo.21406638 | whoever holds the login |
| Use of outputs | R4, D2 | SCI and UNRWA focal points; GoatCounter referrers; ReliefWeb and news search for the dashboard URL (`attic/lit-search-reliefweb.R`); `FSSDashboard2025` and `GazaStripCritical` are in `gaza.bib`, uncited | Francesco, focal points |
| Participatory surveillance literature | I3, D8 | in `gaza.bib`, uncited: `qadirCrisisAnalyticsBig2016`, `degroeveChapter16KnowledgeBased2020`, `MSFSurveyStaff`. To verify: Smolinski et al 2017, JMIR Public Health Surveill; Wójcik et al 2014, Emerg Themes Epidemiol. OpenAlex search not yet run | Kath |
| Surveillance evaluation framework | M5, R1-R4 | CDC, MMWR 2001;50(RR-13); not in `gaza.bib` | Kath decides |
| `[cite]`, weight loss among aid workers | I2 | `outputs/lit-search/reliefweb_2026-10-09.csv`; `MSFSurveyStaff` | Kath |
| `[CITE]`, project description | M3 | https://cmmid.github.io/gaza-response/about.html | paste in |
| Dashboard citation | M4 | Zenodo BibTeX export, into Zotero | Kath |
| Patient and public involvement statement | M11 | facts scaffolded in the qmd; wording guide on the BMJ Global Health author page | Kath |
| Declaration of Helsinki clause | Ethics | LSHTM approval letter | Kath |
| Author reflexivity statement | supplemental file | BMJ Global Health Word template; has to address an all-LSHTM author list | Francesco |
| Competing interests | end statements | ICMJE forms; Zeina's query | each author |
| STROBE cohort checklist | supplemental file | strobe-statement.org; assumed, not in the journal text pasted | Kath |

Derived from the commit history of `../gaza-response` ("Update data"), 2026-10-13: first data update 2 August 2025; irregular until 17 August (gaps of 24 to 96 hours); hourly from then, 2,572 updates to 1 December.
Repository created 30 July 2025.

### Flags

-   [x] Title, abstract, objectives, captions without colour words, referents in R2, D4, D5: resolved in the full draft, 2026-10-13.
-   [ ] Figure 1 has no advertisement dates marked.
-   [ ] Figures S2 and S3 are uncited; cite or drop.
-   [ ] Stale figure files in `outputs/figures/` under the old names (`fig1-bmi`, `fig2-followup`, `figS1-participation`, `figS2-unlinked-weights`, `figS4-change-by-characteristic`).

### Parked from the Discussion

Bullets from the "who salaried staff represent" scaffold, out of the manuscript until the checks listed under 2026-10-13 below are done.
The two employment bullets stay in D6.

- Economy of the Gaza Strip in 2025 [@pcbsEconomicForecasts2025]: GDP 84% and total consumption 81% below 2023; prices about 22% above 2024.
  PCBS's baseline for 2026 expects economic activity "confined to a narrow scope linked to humanitarian assistance and relief operations".
- Poverty: above 63% in the Gaza Strip before the war, on a poverty line of about NIS 2,717 and an extreme poverty line of about NIS 2,170 [@pcbsEconomicForecasts2025].
  Unit not stated in the release; PCBS lines are monthly for a household of two adults and three children.
  Check.
- Pay before the war, Gaza Strip, July-September 2023 [@pcbsLabourForceSurvey2023]: average daily wage NIS 90.4 in PCBS's "other sector" (outside government and private; check that it covers UNRWA and NGOs), NIS 94.2 in the public sector, NIS 30.6 in the private sector.
  At 22.6 paid days a month, NIS 90.4 is about NIS 2,040 a month.
- UNRWA and SCI salary scales for Gaza: no public source found.
  [TODO: ask UNRWA and SCI]

## Standardisation reference, 2026-10-12

-   [x] IPC Phase 5 countries dropped as references. Table S11 now: Palestine's NCD-RisC 2022 BMI weighted to its adult population aged 18-64 (WPP 2024), the same weighted to participants' age and sex (check), and the world (age-standardised). Results scaffold added; Discussion scaffold cut to interpretation.
-   [x] Population weights are for Palestine as a whole, as is the NCD-RisC reference. Replaced 2026-10-13 with Gaza Strip weights (US Census Bureau IDB).
-   [ ] `@fsinGlobalReportFood2025` is no longer cited; remove from `gaza.bib` if not needed elsewhere.
-   [ ] `attic/ncdrisc-extract.R` builds two tracked data files but sits in `attic/`; move back to `R/`?

## Standardisation and representativeness, 2026-10-13

-   [x] Underweight standardised to NCD-RisC reference BMI dropped (was Table S11). Code, WPP extract and removed scaffold text in `attic/ncdrisc-standardisation-2026-10/`.
-   [x] Table S11 now: weight change, BMI change and underweight at enrolment by sex and age, observed and standardised to adults aged 18-65 in the Gaza Strip (IDB, projected mid-2025).
-   [x] Table S12 new: recalled pre-war underweight and obesity vs NCD-RisC 2022, Palestine at participants' ages and world. NCD-RisC is now a comparison only.
-   [x] "≈60% of UNRWA's Health Section" claim dropped. UNRWA Health Department Annual Report 2024 lists 1,010 programme-budget health posts in Gaza (Table 34), no count of staff in post.
-   [x] Discussion scaffold "who salaried staff represent": employment, economy, poverty line, pre-war pay.
-   [ ] `@uscensusbureauInternationalDatabase2025`, `@pcbsEconomicForecasts2025`, `@pcbsLabourForceSurvey2023` added to `gaza.bib` by hand; add to Zotero or they are lost on re-export.
-   [ ] `@rosePopulationMeanPredicts1990` and `@unWorldPopulationProspects2024` are no longer cited.
-   [ ] `data/context/WPP2024_PopulationByAge5GroupSex_Medium.csv.gz` is no longer read.
-   [ ] PCBS Labour Force Survey Q3 2023, Table 29: figures read from extracted PDF text of a right-to-left table. Check column order (other sector 90.4, private 30.6, public 94.2) against the PDF, and what "other sector" covers.
-   [ ] Poverty line NIS 2,717: unit and reference household not stated in the PCBS release.
-   [ ] No Gaza Strip labour force release found for Q3 or Q4 2025; the scaffold uses PCBS's 2025 annual figures. Quarterly 2025 microdata is listed in the PCBS catalogue.
-   [ ] UNRWA and SCI pay scales for Gaza not found in public sources; ask both. Not verified, not in the manuscript: job adverts on jobs.ps list UNRWA clerical posts in Gaza at about USD 830-960 a month basic (undated; page not opened).
-   [ ] Context after the study period, not in the manuscript: UNRWA announced a 20% pay cut for local staff in Gaza in January 2026 (Al Jazeera, 30 January 2026). Whether pay was full during July-December 2025 not established.
-   [ ] Not verified: cash-out commissions of 20-40% on bank balances in Gaza in 2025 (The New Humanitarian, April 2025; page not opened). Would reduce the value of a salary paid by transfer.

## Mean, median or geometric mean, 2026-10-14

-   [x] Table S13 new: each mean reported in the manuscript, with median and geometric mean (`centre_comparison` in `R/analysis.R`). Placed last so S1-S12 keep their numbers.
-   [ ] Decide which summary to report for weight change. The geometric mean and median are on the scale of the log-ratio models; the arithmetic mean of % change is not. Then cite Table S13 in Methods and update the hard-coded numbers (Results change from pre-war, cohorts, standardisation, follow-up; Abstract and Plain summary are inline).
-   [ ] Methods "Change from pre-war to enrolment" says "bootstrapped t-distribution 95% confidence intervals", but `tbl_change` and `loss_ci` use `t.test` with no bootstrap.

## Discussion restructure, 2026-10-18

Findings-led. Paragraph order, each opening on its point:
key findings → timeline of adult weight evidence → adult vs child signals (earlier, cumulative record; pre-IPC loss) → representativeness (bias direction: likely understates population loss) → recall of pre-war weight (male recall explains doubtful sex difference) → individual follow-up vs cohorts → design trade-offs (retention, anonymity, linkage) → conclusion and recommendations (from Plain summary).
Backups of earlier versions in the session scratchpad only; not needed.

Evidence used, checked against full text in Zotero:

- Davis 2026: deprivation Nov 2023-Feb 2024, Oct-Dec 2024, worst May-Jul 2025; relative abundance Mar-Jul 2024, Feb 2025; consumption 2,165 (Feb 2025) to 1,054 kcal/pp/day (Jun 2025).
- Horino 2025: child wasting (MUAC) 5-7% Jan-Jun 2024; 8.8% to 14.3% over Sep 2024-Jan 2025 restrictions; 5.5% by Mar 2025; 15.8% early Aug 2025.
- Alnabih 2024: north, Apr 2024, n 497, convenience; pre-war self-reported, current measured; 84.9 to 66.2 kg (22.0%); no sex difference (22.06% vs 22.03%); largest loss 41-50.
- Faris 2025: May-Jul 2024, 1209 households, convenience; all self-reported; 74.8 to 64.8 kg, BMI 26.4 to 22.8, underweight 15.6%; mean age 38.0, 53.5% women (ours 38.8, 55%).
- Checchi 2024 child model includes adult caloric sacrifice (cited with Howe).

-   [x] Table S14 new (`tbl-literature`, supplement): Alnabih, Faris, this study. Loss as ratio of means for comparability (ours 16.4%, vs 15.6% mean of individual changes in the manuscript).
-   [x] Supplement 2020-survey citation fixed (was Faris, now Abu Hamad).
-   [ ] Discussion `<!-- ASK 2 -->`, `<!-- ASK 3 -->`, `<!-- ASK 5 -->` markers still in place: Kath to confirm or remove.
-   [ ] Abstract still says "Older participants and men had lost the most weight"; Discussion now plays down sex.
-   [ ] Hassneiah 2025 (SAM 15.7% north vs 0.4% south, May-Nov 2024) not used; available if needed.
-   [x] Decision 2026-10-18: all inline-R numbers in the qmds are plain text. Numbers no table shows are printed with their location by `R/numbers.R` (run by hand). Dead code dropped from `R/analysis.R` (inline helpers, `bmi_bands`, `tbl_underweight`, `bmi_long`, `loss_r2`, `proportional_slope`, `gam_edf*`, `n_obs_cat`, `faris2025`; packages broom, gratia, knitr, scales, contingencytables) and from the manuscript setup chunk. Both qmds render.
-   [x] Results "678 (68%)" corrected to 63% (678 of 1083 records).
-   [ ] `paired` (Aug-Sep cohort measured after the ceasefire) and `longitudinal_spanning` (`spans_ceasefire`) are defined differently; both give 50 now, but Methods describes one set. Use `spans_ceasefire` for both?
-   [ ] Implausible-rate filter is `abs(bmi_daily_change) >= 1`; Methods says BMI > 1 kg/m2 per day.
-   [ ] `centre_comparison` location labels ("Results, comparative performance") predate the current section names.
