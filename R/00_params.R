# Reads params.yaml; sources must run with the project root as working directory.
.root <- if (file.exists("params.yaml")) "." else if (file.exists("../params.yaml")) ".." else
  stop("Run from the project root (params.yaml not found).")
.p <- yaml::read_yaml(file.path(.root, "params.yaml"))

SEED              <- .p$seed$value
BUDGET_BASE       <- .p$budget_base$value
COVERAGE_FLOOR    <- .p$coverage_floor$value
DEF_COVERED_SHARE <- .p$def_covered_share$value
LAMBDA_ROBUST     <- .p$lambda_robust$value
LAMBDA_GRID       <- unlist(.p$lambda_grid$value)
MISEST_SIGMA      <- .p$misest_sigma$value
N_MC              <- .p$n_mc$value
BUDGET_GRID       <- seq(.p$budget_grid$from, .p$budget_grid$to, by = .p$budget_grid$by)
N_STARTS          <- .p$n_starts$value
TOL               <- .p$tol$value
LOSS_SIGMA        <- .p$loss_lognormal_sigma$value
STRATEGIES        <- c("risk_ranked", "proportional", "uniform", "textbook", "robust")

PROJECT_ROOT <- normalizePath(.root)
RESULTS_DIR  <- file.path(PROJECT_ROOT, "data", "results")
