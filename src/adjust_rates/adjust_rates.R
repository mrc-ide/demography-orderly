adjust_rates <- function(x, save_output = FALSE){
  name <- paste(x[1, c("region", "iso3c", "year")], collapse = "_")
  
  x$adjusted_mortality_rates <- peeps::estimate_mortality_rates(
    target_age_distribution = x$p,
    starting_mortality_rates = x$qx
  )
 
  if(save_output){
    saveRDS(x, name)
  } else {
    return(x)
  }
}