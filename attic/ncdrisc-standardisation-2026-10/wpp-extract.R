# Superseded 2026-10-13: WPP 2024 population extract. Was attic/ncdrisc-extract.R
# lines 80-127; needs population_year <- 2023 and the NCD-RisC extract above it.

# -----------------------------------------------------------------------------
# Population of Palestine by sex and age group
# -----------------------------------------------------------------------------

wpp <- read_csv(
  here("data", "context", "WPP2024_PopulationByAge5GroupSex_Medium.csv.gz"),
  col_select = c(ISO3_code, Time, AgeGrpStart, PopMale, PopFemale),
  show_col_types = FALSE
)

# WPP counts are in thousands. NCD-RisC starts at 18, so ages 18-19 take two
# fifths of WPP's 15-19, and 85 and over are pooled.
population <- wpp |>
  filter(ISO3_code == "PSE", Time == population_year, AgeGrpStart >= 15) |>
  transmute(
    age_lower = pmin(if_else(AgeGrpStart == 15, 18, AgeGrpStart), 85),
    share = if_else(AgeGrpStart == 15, 2 / 5, 1),
    Female = share * PopFemale,
    Male = share * PopMale
  ) |>
  group_by(age_lower) |>
  summarise(across(c(Female, Male), sum)) |>
  tidyr::pivot_longer(
    c(Female, Male),
    names_to = "sex",
    values_to = "population_thousands"
  ) |>
  transmute(
    year = population_year,
    sex,
    age_group = case_when(
      age_lower == 18 ~ "18-19",
      age_lower == 85 ~ "85plus",
      TRUE ~ paste0(age_lower, "-", age_lower + 4)
    ),
    age_lower,
    population_thousands
  )

stopifnot(
  nrow(population) == 2 * 15,
  setequal(population$age_group, extract$age_group[extract$country == "Palestine"])
)

write_csv(
  population,
  here("data", "raw", "wpp2024_palestine_pop_age_sex_2023.csv")
)
