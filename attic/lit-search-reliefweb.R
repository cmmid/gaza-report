# Grey-literature search: ReliefWeb reports on nutrition/anthropometry in Gaza since 7 Oct 2023.
# Needs RELIEFWEB_APPNAME in ~/.Renviron. Writes the results and a search log to outputs/lit-search/.
pacman::p_load(httr2, dplyr, purrr, readr, tibble)

appname <- Sys.getenv("RELIEFWEB_APPNAME")
stopifnot(nzchar(appname))

out_dir <- here::here("outputs", "lit-search")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

search_date <- Sys.Date()
date_from <- "2023-10-07T00:00:00+00:00"
# Two tiers: broad terms must be in the title (body mentions are near-universal);
# measurement terms may be anywhere in the body, as these flag primary data.
broad <- "(malnutrition OR undernutrition OR malnourished OR starvation OR famine OR hunger OR nutrition)"
measurement <- paste0(
  '(MUAC OR "mid-upper arm" OR anthropometric OR anthropometry OR "weight loss" OR "lost weight" OR ',
  '"body weight" OR BMI OR "body mass index" OR "SMART survey" OR "weight-for-height")'
)
query_all <- paste0("Gaza AND (title:", broad, " OR body:", measurement, ")")
query_measurement <- paste0("Gaza AND body:", measurement)

# Country filter oPt (iso3 pse) + "Gaza" required in the text, so West Bank-only reports drop out
query_body <- function(query, offset, limit = 1000) {
  list(
    query = list(value = query, fields = list("title", "body")),
    filter = list(operator = "AND", conditions = list(
      list(field = "country.iso3", value = "pse"),
      list(field = "date.original", value = list(from = date_from))
    )),
    fields = list(include = list(
      "title", "date.original", "source.shortname", "source.name", "source.type.name",
      "format.name", "theme.name", "language.code", "url_alias", "origin", "file.url"
    )),
    sort = list("date.original:desc"),
    offset = offset,
    limit = limit
  )
}

fetch_page <- function(query, offset) {
  request("https://api.reliefweb.int/v2/reports") |>
    req_url_query(appname = appname) |>
    req_body_json(query_body(query, offset)) |>
    req_retry(max_tries = 3) |>
    req_perform() |>
    resp_body_json()
}

fetch_all <- function(query) {
  first <- fetch_page(query, 0)
  total <- first$totalCount
  offsets <- if (total > 1000) seq(1000, total - 1, by = 1000) else integer(0)
  records <- flatten(map(c(list(first), map(offsets, \(o) fetch_page(query, o))), "data"))
  stopifnot(length(records) == total)
  records
}

records <- fetch_all(query_all)
measurement_ids <- map_chr(fetch_all(query_measurement), "id")

collapse <- function(x, field) paste(unique(map_chr(x %||% list(), field)), collapse = "; ")

reports <- map_dfr(records, \(r) {
  f <- r$fields
  tibble(
    id = r$id,
    match_measurement = r$id %in% measurement_ids,
    date = as.Date(substr(f$date$original %||% NA_character_, 1, 10)),
    title = f$title,
    source = collapse(f$source, "shortname"),
    source_name = collapse(f$source, "name"),
    source_type = paste(unique(unlist(map(f$source %||% list(), \(s) s$type$name))), collapse = "; "),
    format = collapse(f$format, "name"),
    theme = collapse(f$theme, "name"),
    language = paste(unlist(f$language %||% list()) |> unique(), collapse = "; "),
    reliefweb_url = f$url_alias %||% NA_character_,
    origin_url = f$origin %||% NA_character_,
    file_url = collapse(f$file, "url")
  )
})

stamp <- format(search_date, "%Y-%m-%d")
reports <- arrange(reports, desc(match_measurement), desc(date))
write_csv(reports, file.path(out_dir, paste0("reliefweb_", stamp, ".csv")))

# PRISMA-S style log: one row per search run
log_row <- tibble(
  source = "ReliefWeb API v2 /reports",
  searched_on = stamp,
  query = c(query_all, query_measurement),
  fields = "title, body",
  filters = paste("country.iso3 = pse; date.original >=", date_from),
  hits = c(nrow(reports), length(measurement_ids))
)
log_file <- file.path(out_dir, "search-log.csv")
write_csv(log_row, log_file, append = file.exists(log_file))

message("ReliefWeb: ", nrow(reports), " reports (", length(measurement_ids), " with measurement terms) written to ", out_dir)
