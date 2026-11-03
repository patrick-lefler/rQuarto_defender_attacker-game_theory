root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
old_wd <- setwd(root)
for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R",
            "R/30_robust.R", "R/32_misestimation.R")) source(f)
assets <- load_assets()
