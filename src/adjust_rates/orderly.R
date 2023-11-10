# Adjust rates -----------------------------------------------------------------

# Orderly specification --------------------------------------------------------

orderly2::orderly_description(
  display = "Adjust mortality rates",
  long = "Adjusts mortality rates such that the target 
  equilibrium age-distribution is obtained in the model run. Required as the 
  model has a static population size"
)

orderly2::orderly_parameters(
  iso3c = NULL
)

orderly2::orderly_dependency(
  name = "process_data",
  query = "latest()",
  files = "demography.RDS"
)

orderly2::orderly_artefact(
  description = "Demography data with adjusted mortality rates",
  files = "adjusted_demography.RDS"
)
# ------------------------------------------------------------------------------

#  Adjusting rates -------------------------------------------------------------
demography <- readRDS("demography.RDS") |>
  dplyr::filter(
    iso3c == {{iso3c}},
    year == 2000
    ) |>
  dplyr::mutate(
    adjusted_mortality_rates = peeps::estimate_mortality_rates(
      target_age_distribution = p,
      starting_mortality_rates = qx
    ),
    .by = "year"
  )

saveRDS(demography, "adjusted_demography.RDS")
# ------------------------------------------------------------------------------
