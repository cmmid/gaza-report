# =============================================================================
# Variable definitions and the analysis set shared by every topic file.
# Sourced after R/utils.R.
#   included: every valid measurement
#   baseline: one row per participant at enrolment, with change since pre-war
#   longitudinal: every measurement of participants with 2+ measurements
# =============================================================================

# Variable definitions --------------------------------------------------------
age_levels <- c("Age under 30", "Age 30-45", "Age over 45")
sex_levels <- c("Female", "Male")
organisation_levels <- c("UNRWA", "Save the Children International")
governorate_levels <- c(
  "Deir Al Balah",
  "Gaza City, North Gaza",
  "Khan Yunis, Rafah"
)
role_levels <- c("National staff", "Casual worker", "Other")
chronic_levels <- c("No chronic condition", "Chronic condition")
children_levels <- c("0", "1", "2", "3+")
cohort_levels <- c("Aug-Sep 2025", "Oct-Nov 2025")
bmi_levels <- c("Underweight", "Normal", "Overweight", "Obese")
characteristic_order <- c(
  "age",
  "sex",
  "governorate_cat",
  "children",
  "role_cat",
  "organisation",
  "chronic",
  "entry_cohort"
)

variable_labels <- c(
  age = "Age group",
  sex = "Sex",
  governorate_cat = "Residence",
  children = "Dependent children",
  role_cat = "Professional role",
  organisation = "Organisation",
  chronic = "Chronic condition",
  entry_cohort = "Enrolment cohort",
  # measured quantities, used by the supplementary tables only
  age_years = "Age (years)",
  bmi_prewar = "Pre-war BMI (kg/m2)",
  bmi_entry = "BMI at enrolment (kg/m2)",
  pct_weight_change = "Weight change since pre-war (%)",
  bmi_change = "BMI change since pre-war (kg/m2)",
  underweight_prewar = "Pre-war (Oct 2023)",
  underweight_entry = "At enrolment (measured)"
)
labels_for <- function(variables) as.list(variable_labels[variables])

# 10 October 2025 ceasefire, marked on the follow-up and timeline figures
ceasefire_date <- as_date("2025-10-10")

# Read ------------------------------------------------------------------------
data_processed <- read_csv(
  here("data", "processed", "participants.csv"),
  show_col_types = FALSE
)

exclusions <- read_csv(
  here("data", "processed", "data-quality.csv"),
  show_col_types = FALSE
)

# Valid measurements ----------------------------------------------------------
included <- data_processed |>
  filter(record_remove == "include", !is.na(weight)) |>
  mutate(
    record_date = as_date(record_date),
    date_entry = as_date(date_entry),
    entry_cohort = if_else(
      date_entry < as_date("2025-10-01"),
      "Aug-Sep 2025",
      "Oct-Nov 2025"
    ),
    # North Gaza (n = 20) and Rafah (n = 8) are combined with a neighbour
    governorate_cat = case_when(
      governorate %in% c("Gaza City", "North Gaza") ~ "Gaza City, North Gaza",
      governorate %in% c("Khan Yunis", "Rafah") ~ "Khan Yunis, Rafah",
      governorate == "Deir Al Balah" ~ "Deir Al Balah"
    ),
    role_cat = case_when(
      role == "National staff" ~ "National staff",
      role == "Casual/daily worker" ~ "Casual worker",
      is.na(role) ~ NA_character_,
      TRUE ~ "Other"
    ),
    # ODK multi-select: "0" = no condition reported, any code = at least one.
    chronic = case_when(
      is.na(chronic_condition) ~ NA_character_,
      chronic_condition == "0" ~ "No chronic condition",
      TRUE ~ "Chronic condition"
    )
  ) |>
  mutate(
    age = factor(age, levels = age_levels),
    sex = factor(sex, levels = sex_levels),
    organisation = factor(organisation, levels = organisation_levels),
    governorate_cat = factor(governorate_cat, levels = governorate_levels),
    role_cat = factor(role_cat, levels = role_levels),
    chronic = factor(chronic, levels = chronic_levels),
    children = factor(children, levels = children_levels),
    entry_cohort = factor(entry_cohort, levels = cohort_levels)
  ) |>
  add_count(id, name = "n_obs")

study_start <- min(included$record_date)

# Cross-sectional set ---------------------------------------------------------
# One row per participant at entry.
# Outcome = change from pre-war to first measured weight
baseline <- included |>
  filter(record_number == 1) |>
  mutate(
    pct_weight_change = 100 * (weight_entry - weight_prewar) / weight_prewar,
    log_weight_ratio = log(weight_entry / weight_prewar),
    bmi_change = bmi_entry - bmi_prewar,
    underweight_prewar = bmi_prewar < 18.5,
    underweight_entry = bmi_entry < 18.5,
    has_followup = n_obs >= 2
  )

# Longitudinal set ------------------------------------------------------------
# Participants with 2+ records, less those with an implausible rate of BMI
# change (> 1 kg/m2 per day).
longitudinal_all <- included |>
  filter(n_obs >= 2) |>
  arrange(id, record_date) |>
  group_by(id) |>
  mutate(
    bmi_daily_change = c(NA, diff(bmi)) / c(NA, as.numeric(diff(record_date)))
  ) |>
  ungroup()

implausible_ids <- longitudinal_all |>
  filter(abs(bmi_daily_change) > 1) |>
  pull(id) |>
  unique()

longitudinal <- longitudinal_all |>
  filter(!id %in% implausible_ids) |>
  mutate(
    id = factor(id),
    log_weight_ratio = log(weight / weight_prewar),
    pct_weight_change = 100 * (exp(log_weight_ratio) - 1),
    calendar_day = as.numeric(record_date - study_start),
    entry_day = as.numeric(date_entry - study_start)
  ) |>
  group_by(id) |>
  mutate(
    is_first = record_date == min(record_date),
    spans_ceasefire = any(record_date <= ceasefire_date) &
      any(record_date > ceasefire_date)
  ) |>
  ungroup()
