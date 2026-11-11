# =============================================================================
# Comparison with reference populations: recalled pre-war BMI against
# independent estimates, and published studies of adult weight change.
# Manuscript: Discussion
# Supplement: "Population comparisons" (tab-external, tab-prewar-reference,
#   tab-literature)
# Sourced after R/utils.R and R/data.R.
# =============================================================================

# Set-up ----------------------------------------------------------------------
# Participants with a recorded age
reference_set <- baseline |>
  filter(!is.na(age_years)) |>
  mutate(sex = as.character(sex))

# NCD-RisC modelled prevalence by BMI band and sex in 2022: Palestine by 5-year
# age group, and the world, age-standardised. Point estimates extracted from
# https://www.ncdrisc.org/data-downloads-adiposity.html
ncdrisc <- read_csv(
  here("data", "raw", "ncdrisc_2026_bmi_age_sex_2022.csv"),
  show_col_types = FALSE
) |>
  transmute(
    country,
    sex,
    age_group,
    underweight = 100 * bmi_under_18.5,
    obese = 100 * (bmi_30_35 + bmi_35_40 + bmi_40_plus)
  )

ncdrisc_age_group <- function(age) {
  lower <- pmin(5 * floor(age / 5), 85)
  case_when(
    age < 20 ~ "18-19",
    lower == 85 ~ "85plus",
    TRUE ~ paste0(lower, "-", lower + 4)
  )
}

# 2020 survey of adults aged 40 and over. The aggregated file carries means only
survey_2020 <- read_csv(
  here("data", "raw", "gaza_survey2020_kcal_bmi_agg.csv"),
  show_col_types = FALSE
) |>
  transmute(
    age_band = age_cat,
    sex = if_else(gender == "f", "Female", "Male"),
    bmi_2020 = weight / height^2
  )

# Analysis --------------------------------------------------------------------

## Recalled pre-war BMI against NCD-RisC estimates (tab-prewar-reference) ----
# Recall and selection check: underweight and obesity from recalled pre-war
# weight, against Palestine weighted to participants' ages by
# sex and for both sexes at participants' sex mix
prewar_reference <- reference_set |>
  mutate(age_group = ncdrisc_age_group(age_years)) |>
  group_by(sex, age_group) |>
  summarise(
    n = n(),
    underweight_recalled = 100 * mean(bmi_prewar < 18.5),
    obese_recalled = 100 * mean(bmi_prewar >= 30),
    .groups = "drop"
  ) |>
  inner_join(
    ncdrisc |>
      filter(country == "Palestine") |>
      select(
        sex,
        age_group,
        underweight_palestine = underweight,
        obese_palestine = obese
      ),
    by = c("sex", "age_group")
  ) |>
  inner_join(
    ncdrisc |>
      filter(country == "World") |>
      select(sex, underweight_world = underweight, obese_world = obese),
    by = "sex"
  )

prewar_reference <- bind_rows(
  prewar_reference,
  mutate(prewar_reference, sex = "Both")
) |>
  group_by(sex) |>
  summarise(
    across(
      c(starts_with("underweight_"), starts_with("obese_")),
      \(x) weighted.mean(x, n)
    ),
    n = sum(n)
  ) |>
  relocate(n, .after = sex)

## Recalled pre-war BMI against the 2020 survey (tab-external) ----
external_comparison <- baseline |>
  filter(age_years >= 40) |>
  mutate(
    age_band = cut(
      age_years,
      breaks = c(40, 50, 60, 70, 120),
      right = FALSE,
      labels = c("[40,50)", "[50,60)", "[60,70)", "[70,120]")
    )
  ) |>
  group_by(age_band, sex) |>
  summarise(
    n_this_study = n(),
    mean_bmi_prewar = mean(bmi_prewar),
    sd_bmi_prewar = sd(bmi_prewar),
    .groups = "drop"
  ) |>
  mutate(age_band = as.character(age_band), sex = as.character(sex)) |>
  left_join(survey_2020, by = c("age_band", "sex"))

## Published studies of adult weight change (tab-literature) ----
literature_weight <- tribble(
  ~Study, ~Period, ~Population, ~n, ~`Women, %`, ~Age, ~`Pre-war weight`, ~`Current weight`, ~`Mean weight, kg`, ~`Mean BMI, kg/m2`, ~`Underweight now, %`,
  "Alnabih et al. 2024", "April 2024", "Residents of North Gaza and Gaza City, recruited in shelters and markets (convenience)", "497", "33.6", "13-83 years", "Self-reported", "Measured by study team", "84.9 to 66.2", "-", "-",
  "Faris et al. 2025", "May-July 2024", "Households in all five governorates (convenience)", "1209", "53.5", "mean 38.0 years", "Self-reported", "Self-reported", "74.8 to 64.8", "26.4 to 22.8", "15.6"
)

this_study_weight <- baseline |>
  summarise(
    n = as.character(n()),
    women = sprintf("%.1f", 100 * mean(sex == "Female")),
    age = sprintf("mean %.1f years", mean(age_years, na.rm = TRUE)),
    weight = sprintf("%.1f to %.1f", mean(weight_prewar), mean(weight_entry)),
    loss = 100 * (1 - mean(weight_entry) / mean(weight_prewar)),
    bmi = sprintf("%.1f to %.1f", mean(bmi_prewar), mean(bmi_entry)),
    underweight = sprintf("%.1f", 100 * mean(bmi_entry < 18.5))
  )

literature_comparison <- literature_weight |>
  mutate(`Loss, %` = c(
    100 * (1 - 66.22 / 84.94),
    100 * (1 - 64.8 / 74.8)
  )) |>
  bind_rows(tibble(
    Study = "This study",
    Period = sprintf(
      "%s to %s",
      format(min(baseline$record_date), "%e %B"),
      format(max(baseline$record_date), "%e %B %Y")
    ),
    Population = "Staff of UNRWA and SCI (self-selected)",
    n = this_study_weight$n,
    `Women, %` = this_study_weight$women,
    Age = this_study_weight$age,
    `Pre-war weight` = "Self-reported",
    `Current weight` = "Self-measured on calibrated scales",
    `Mean weight, kg` = this_study_weight$weight,
    `Loss, %` = this_study_weight$loss,
    `Mean BMI, kg/m2` = this_study_weight$bmi,
    `Underweight now, %` = this_study_weight$underweight
  )) |>
  mutate(`Loss, %` = sprintf("%.1f", `Loss, %`)) |>
  relocate(`Loss, %`, .after = `Mean weight, kg`)

# Numbers in the text ---------------------------------------------------------
# Recalled pre-war BMI minus the 2020 survey mean, range across age bands with
# 10 or more participants (ages 40-59), by sex
bmi_gap <- external_comparison |>
  filter(n_this_study >= 10) |>
  mutate(gap = abs(mean_bmi_prewar - bmi_2020)) |>
  group_by(sex) |>
  summarise(range = sprintf("%.1f-%.1f", min(gap), max(gap))) |>
  tibble::deframe()

# One percentage from the NCD-RisC comparison, by column and sex
reference_pct <- function(column, sex = "Both", digits = 0) {
  fmt_pct(prewar_reference[[column]][prewar_reference$sex == sex], digits)
}

numbers_context <- tribble(
  ~location, ~quantity, ~value,
  "Supplement, 2020 survey", "Pre-war BMI gap, ages 40-59: women; men",
  paste(bmi_gap[["Female"]], bmi_gap[["Male"]], sep = "; "),
  "Supplement, NCD-RisC", "Underweight, women: recalled; Palestine",
  paste(reference_pct("underweight_recalled", "Female", 1),
        reference_pct("underweight_palestine", "Female", 1), sep = "; "),
  "Supplement, NCD-RisC", "Obese, women: recalled; Palestine",
  paste(reference_pct("obese_recalled", "Female"),
        reference_pct("obese_palestine", "Female"), sep = "; "),
  "Supplement, NCD-RisC", "Underweight, men: recalled; Palestine",
  paste(reference_pct("underweight_recalled", "Male"),
        reference_pct("underweight_palestine", "Male"), sep = "; "),
  "Supplement, NCD-RisC", "Obese, men: recalled; Palestine",
  paste(reference_pct("obese_recalled", "Male"),
        reference_pct("obese_palestine", "Male"), sep = "; ")
)
