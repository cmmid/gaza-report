# =============================================================================
# Extract reference BMI prevalences and population structure for
# R/context.R
# =============================================================================
# BMI. NCD Risk Factor Collaboration, Nature 2026, adult BMI by sex. Downloaded
# from https://www.ncdrisc.org/data-downloads-adiposity.html into data/context/:
#   NCD_RisC_Nature_2026_BMI_female_age_specific_country.zip   (2026-10-10)
#   NCD_RisC_Nature_2026_BMI_male_age_specific_country.zip     (2026-10-10)
#   NCD_RisC_Nature_2026_BMI_age_standardised_world.csv        (2026-10-12)
#
# Keeps 2022 (before the war in Gaza) for Palestine, by 5-year age group, and
# for the world, age-standardised. Point estimates of the BMI band prevalences
# only. Writes data/raw/ncdrisc_2026_bmi_age_sex_2022.csv.
#
# Population. US Census Bureau International Database, December 2025 release,
# population by single year of age and sex. Downloaded 2026-10-13 from
# https://www.census.gov/data-tools/demo/data/idb/dataset/idbzip.zip into
# data/context/:
#   IDB_2025-12_idbzip.zip
#
# Keeps the Gaza Strip, mid-2025, ages 18 and over. Projected from the 2017
# census: not adjusted for deaths or displacement during the war. Writes
# data/raw/idb2025_gaza_pop_age_sex_2025.csv.

pacman::p_load(here, readr, dplyr)

reference_year <- 2022
population_year <- 2025

# -----------------------------------------------------------------------------
# NCD-RisC BMI band prevalences
# -----------------------------------------------------------------------------

read_ncdrisc_country <- function(sex) {
  name <- paste0("NCD_RisC_Nature_2026_BMI_", sex, "_age_specific_country")
  read_csv(
    unz(here("data", "context", paste0(name, ".zip")), paste0(name, ".csv")),
    show_col_types = FALSE
  )
}

ncdrisc_world <- read_csv(
  here("data", "context", "NCD_RisC_Nature_2026_BMI_age_standardised_world.csv"),
  show_col_types = FALSE
) |>
  mutate(`Age group` = "age-standardised")

ncdrisc <- bind_rows(
  read_ncdrisc_country("female"),
  read_ncdrisc_country("male"),
  ncdrisc_world
)
names(ncdrisc)[1] <- "Year" # first column name carries a byte-order mark

extract <- ncdrisc |>
  filter(
    Year == reference_year,
    `Country/Region/World` %in% c("Palestine", "World")
  ) |>
  transmute(
    year = Year,
    sex = recode(Sex, Women = "Female", Men = "Male"),
    country = `Country/Region/World`,
    iso = ISO,
    age_group = `Age group`,
    bmi_under_18.5 = `Prevalence of BMI<18.5 kg/m² (underweight)`,
    bmi_18.5_20 = `Prevalence of BMI 18.5 kg/m² to <20 kg/m²`,
    bmi_20_25 = `Prevalence of BMI 20 kg/m² to <25 kg/m²`,
    bmi_25_30 = `Prevalence of BMI 25 kg/m² to <30 kg/m²`,
    bmi_30_35 = `Prevalence of BMI 30 kg/m² to <35 kg/m²`,
    bmi_35_40 = `Prevalence of BMI 35 kg/m² to <40 kg/m²`,
    bmi_40_plus = `Prevalence of BMI >=40 kg/m² (morbid obesity)`
  )

stopifnot(
  nrow(extract) == 2 * 15 + 2,
  all(abs(rowSums(select(extract, starts_with("bmi_"))) - 1) < 1e-6)
)

write_csv(extract, here("data", "raw", "ncdrisc_2026_bmi_age_sex_2022.csv"))

# -----------------------------------------------------------------------------
# Population of the Gaza Strip by sex and single year of age
# -----------------------------------------------------------------------------

# Pipe-delimited; the header row starts with "#". GEO_ID ends in the GENC code
# (XG = Gaza Strip). SEX: 0 = both, 1 = male, 2 = female.
idb <- read_delim(
  unz(here("data", "context", "IDB_2025-12_idbzip.zip"), "idbsingleyear.txt"),
  delim = "|",
  show_col_types = FALSE
)
names(idb)[1] <- "YR"

population <- idb |>
  filter(
    YR == population_year,
    GEO_ID == "W140000WOXG",
    SEX %in% 1:2,
    AGE >= 18
  ) |>
  transmute(
    year = YR,
    sex = if_else(SEX == 1, "Male", "Female"),
    age_years = AGE,
    population = POP
  ) |>
  arrange(sex, age_years)

stopifnot(
  nrow(population) == 2 * length(18:100),
  !anyNA(population$population)
)

write_csv(
  population,
  here("data", "raw", "idb2025_gaza_pop_age_sex_2025.csv")
)
