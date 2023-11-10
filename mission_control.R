# Malaria model demography -----------------------------------------------------

# ---- Parameters ---- #
isos <- c("NGA", "COD", "MOZ")

# ---- Process data ---- # 
orderly2::orderly_run(
  name = "process_data"
)

# ---- Adjust mortality rates ---- #
ctx <- context::context_save("contexts")

config <- didehpc::didehpc_config()
obj <- didehpc::queue_didehpc(ctx, config = config)
obj$install_packages("mrc-ide/orderly2")
obj$install_packages("mrc-ide/peeps")
obj$install_packages("dplyr")

obj$lapply(isos, function(iso){
  orderly2::orderly_run(
    name = "adjust_rates",
    parameters = list(
      iso3c = iso
    )
  )
})

