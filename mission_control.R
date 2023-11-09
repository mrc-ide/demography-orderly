# Malaria model demography -----------------------------------------------------

# ---- Process data ---- # 
orderly2::orderly_run(name = "process_data")

# ---- Adjust mortality rates ---- #
orderly2::orderly_run(name = "adjust_rates")
