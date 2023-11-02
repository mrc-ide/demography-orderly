# Process data -----------------------------------------------------------------

# Orderly specification --------------------------------------------------------

orderly2::orderly_description(
  display = "Process raw UN and UNICEF data",
  long = "Processes and combines population and mortality data and projections"
)

# Single age life table historical estimates
## https://population.un.org/wpp/Download/Standard/Mortality/
## Accessed: 2023/08/01
orderly2::orderly_resource("data-raw/WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_ESTIMATES_BOTH_SEXES.csv")

# Single age life table future projections
## https://population.un.org/wpp/Download/Standard/Mortality/
## Accessed: 2023/08/01
orderly2::orderly_resource("data-raw/WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_ESTIMATES_BOTH_SEXES.csv")

# Single age population age structure historical estimates
## https://population.un.org/wpp/Download/Standard/Population/
## Accessed: 2023/08/01
orderly2::orderly_resource("data-raw/WPP2022_POP_F01_1_POPULATION_SINGLE_AGE_BOTH_SEXES.csv")

# Single age population age structure future projections
## https://population.un.org/wpp/Download/Standard/Population/
## Accessed: 2023/08/01
orderly2::orderly_resource("data-raw/WPP2022_POP_F01_1_POPULATION_SINGLE_AGE_BOTH_SEXES_PROJECTIONS.csv")

# Neonatal mortality rates
## https://data.unicef.org/topic/child-survival/neonatal-mortality/
## Accessed: 2023/08/01
orderly2::orderly_resource("data-raw/Neonatal_Mortality_Rates_2022.csv")

orderly2::orderly_artefact(
  description = "Combined mortality and age structure data",
  files = "demography.RDS"
)

orderly2::orderly_artefact(
  description = "Neonatal mortality data",
  files = "neonatal_mortality.RDS"
)
# ------------------------------------------------------------------------------

# Life tables ------------------------------------------------------------------
life_table_estimates_raw <- read.csv(
  file = "data-raw/WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_ESTIMATES_BOTH_SEXES.csv"
)
life_table_projections_raw <- read.csv(
  file = "data-raw/WPP2022_MORT_F06_1_SINGLE_AGE_LIFE_TABLE_PROJECTIONS_BOTH_SEXES.csv"
)

life_table <- life_table_estimates_raw |>
  dplyr::bind_rows(life_table_projections_raw) |>
  dplyr::rename(
    region = Region..subregion..country.or.area..,
    iso3c = ISO3.Alpha.code,
    year = Year,
    age_lower = Age..x.,
    mx = Central.death.rate.m.x.n.,
    qx = Probability.of.dying.q.x.n.,
    px = Probability.of.surviving.p.x.n.,
    lx = Number.of.survivors.l.x.,
    dx = Number.of.deaths.d.x.n.,
    Lx = Number.of.person.years.lived.L.x.n.,
    Sx = Survival.ratio.S.x.n.,
    Tx = Person.years.lived.T.x.,
    ex = Expectation.of.life.e.x.,
    ax = Average.number.of.years.lived.a.x.n.
  ) |>
  dplyr::mutate(
    dplyr::across(c("year", "age_lower", "Age.interval..n."), as.integer),
    dplyr::across(c("mx", "qx", "px", "lx", "dx", "Lx", "Sx", "Tx", "ex", "ax"), as.numeric),
    Age.interval..n. = ifelse(Age.interval..n. < 0, 100, Age.interval..n.),
    age_upper = age_lower + Age.interval..n.) |>
  dplyr::select(region, iso3c, year, age_lower, age_upper, mx, qx, px, lx, dx, Lx, Sx, Tx, ex, ax)
# ------------------------------------------------------------------------------

# Age structure ----------------------------------------------------------------
age_structure_estimates_raw <- read.csv(
  file = "data-raw/WPP2022_POP_F01_1_POPULATION_SINGLE_AGE_BOTH_SEXES.csv"
)
age_structure_projections_raw <- read.csv(
  file = "data-raw/WPP2022_POP_F01_1_POPULATION_SINGLE_AGE_BOTH_SEXES_PROJECTIONS.csv"
)

age_structure <- age_structure_estimates_raw |>
  dplyr::bind_rows(age_structure_projections_raw) |>
  dplyr::rename(
    region = Region..subregion..country.or.area..,
    iso3c = ISO3.Alpha.code,
    year = Year
  ) |>
  dplyr::select(-c("Notes", "Location.code", "ISO2.Alpha.code", "SDMX.code..", "Type", "Parent.code")) |>
  tidyr::pivot_longer(
    cols = -c("region", "iso3c", "year"),
    names_to = "age_lower",
    values_to = "n",
    names_prefix = "X"
  ) |>
  dplyr::mutate(
    age_lower = as.integer(age_lower),
    n = as.numeric(n),
    age_upper = ifelse(age_lower == 100, 200, age_lower + 1)
  ) |>
  dplyr::mutate(p = n / sum(n), .by = c("region", "iso3c", "year")) |>
  dplyr::select(region, iso3c, year, age_lower, age_upper, p) |>
  unique()
# ------------------------------------------------------------------------------

# Demography output ------------------------------------------------------------
demography <- life_table |>
  dplyr::left_join(
    age_structure,
    by = c("region", "iso3c", "year", "age_lower", "age_upper")
  )

saveRDS(demography, "demography.RDS")
# ------------------------------------------------------------------------------

# Neonatal mortality -----------------------------------------------------------
neonatal_mortality_raw <- read.csv("data-raw/Neonatal_Mortality_Rates_2022.csv")

neonatal_mortality <- neonatal_mortality_raw |>
  dplyr::filter(
    Uncertainty.Bounds. == "Median",
    Country.Name %in% codelist$country.name.en
  ) |>
  dplyr::mutate(iso3c = countrycode(Country.Name, "country.name", "iso3c")) |>
  dplyr::filter(!is.na(iso3c)) |>
  dplyr::select(-c("Country.Name", "Uncertainty.Bounds.")) |>
  tidyr::pivot_longer(
    cols = -"iso3c",
    names_to = "year",
    values_to = "nnm",
    names_prefix = "X"
  ) |>
  dplyr::mutate(
    year = as.integer(year),
    nnm = nnm / 1000
  )

saveRDS(neonatal_mortality, "neonatal_mortality.RDS")
# ------------------------------------------------------------------------------