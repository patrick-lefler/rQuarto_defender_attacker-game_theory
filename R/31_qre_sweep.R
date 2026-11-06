# Expected loss against a noisy crew over the lambda grid (strategies fixed at BUDGET_BASE).
main_31 <- function() {
  assets <- load_assets()
  base <- read_result("strategies_base")$strategies
  out <- tidyr::expand_grid(strategy = STRATEGIES, lambda = LAMBDA_GRID) |>
    dplyr::mutate(expected_loss = purrr::map2_dbl(strategy, lambda, \(s, l) {
      cov <- base$coverage[base$strategy == s]
      qre_loss(cov, assets, l)
    }))
  save_result(out, "qre_sweep")

  # Which lambda to optimize the robust strategy at? Compare misestimation MC means.
  mult <- misest_multipliers(seed = SEED + 100)   # choose lambda on draws not used for reporting
  choice <- purrr::map(c(1, 2, 3, 5), \(l) {
    cov <- solve_robust(BUDGET_BASE, assets, lambda = l)
    mc <- run_misestimation(list(robust = cov), assets, mult = mult)$summary
    tibble::tibble(lambda = l, mc_mean = mc$mean, mc_p95 = mc$p95)
  }) |> purrr::list_rbind()
  save_result(choice, "lambda_choice")
}
if (sys.nframe() == 0) {
  for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R",
              "R/30_robust.R", "R/32_misestimation.R")) source(f)
  main_31()
}
