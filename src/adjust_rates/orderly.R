# Adjust rates -----------------------------------------------------------------

# Orderly specification --------------------------------------------------------
orderly2::orderly_dependency(
  name = "process_data",
  query = "latest()",
  files = "demography.RDS"
)

orderly2::orderly_resource("adjust_rates.R")

orderly2::orderly_artefact(
  description = "Demography data with adjusted mortality rates",
  files = "adjusted_demography.RDS"
)
# ------------------------------------------------------------------------------

# Prepare data for parallel processing -----------------------------------------
demography <- readRDS("demography.RDS")
demography_split <- split(demography, demography[,c("iso3c", "year")])

source("adjust_rates.R")

cores <- 4 # parallel::detectCores()
cluster <- parallel::makeCluster(cores)
adjusted_demography_split <- parallel::parLapply(
  cl = cluster,
  X = demography_split,
  fun = adjust_rates
)
parallel::stopCluster(cl = cluster)

adjusted_demography <- dplyr::bind_rows(adjusted_demography_split)
saveRDS(adjusted_demography, "adjusted_demography.RDS")
# ------------------------------------------------------------------------------
