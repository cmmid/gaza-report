# Superseded 2026-11-11 with standardisation.R in this folder. Was the
# population half of R/ncdrisc-extract.R.
#
# Population. US Census Bureau International Database, December 2025 release,
# population by single year of age and sex. Downloaded 2026-10-13 from
# https://www.census.gov/data-tools/demo/data/idb/dataset/idbzip.zip into
# data/context/:
#   IDB_2025-12_idbzip.zip
#
# Keeps the Gaza Strip, mid-2025, ages 18 and over. Projected from the 2017
# census: not adjusted for deaths or displacement during the war. Writes
# idb2025_gaza_pop_age_sex_2025.csv.

pacman::p_load(here, readr, dplyr)

population_year <- 2025

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
  here("attic", "gaza-standardisation-2026-11", "idb2025_gaza_pop_age_sex_2025.csv")
)
