# One-at-a-time sensitivity of the base-budget comparison (assumptions A6, A7, A10),
# plus a lateral-movement scenario (A11). Every case re-builds all five strategies
# and re-runs the misestimation Monte Carlo with the same seed (common random numbers).

with_assets <- function(L_override = NULL) {
  a <- load_assets()
  if (!is.null(L_override)) {
    a$L[match(names(L_override), a$asset_id)] <- L_override
    a <- dplyr::mutate(a, Ud_u = -L, Ud_c = -DEF_COVERED_SHARE * L, EL_heat = p_heat * L)
  }
  a
}

run_case <- function(assumption, setting, covered = DEF_COVERED_SHARE,
                     floor = COVERAGE_FLOOR, sigma = MISEST_SIGMA, L_override = NULL) {
  old <- list(cs = DEF_COVERED_SHARE, fl = COVERAGE_FLOOR)
  on.exit({ DEF_COVERED_SHARE <<- old$cs; COVERAGE_FLOOR <<- old$fl }, add = TRUE)
  DEF_COVERED_SHARE <<- covered
  COVERAGE_FLOOR <<- floor

  assets <- with_assets(L_override)
  strats <- build_strategies(BUDGET_BASE, assets)
  s <- run_misestimation(strats, assets, sigma = sigma)$summary
  others <- s[s$strategy != "robust", ]
  tibble::tibble(
    assumption = assumption, setting = setting,
    best = s$strategy[which.min(s$mean)],
    robust_mean = s$mean[s$strategy == "robust"],
    next_best = others$strategy[which.min(others$mean)],
    next_mean = min(others$mean),
    robust_p95 = s$p95[s$strategy == "robust"],
    textbook_p95 = s$p95[s$strategy == "textbook"]
  )
}

main_35 <- function() {
  cases <- list(
    list("Base case", "As published"),
    list("A6 covered-attack share", "5%", covered = 0.05),
    list("A6 covered-attack share", "20%", covered = 0.20),
    list("A7 coverage floor", "15%", floor = 0.15),
    list("A7 coverage floor", "35%", floor = 0.35),
    list("A10 misjudgment size (sigma)", "0.20", sigma = 0.20),
    list("A10 misjudgment size (sigma)", "0.50", sigma = 0.50),
    list("A11 lateral movement", "Identity loss 30, corporate IT loss 22",
         L_override = c(IDP = 30, CORP = 22))
  )
  tbl <- purrr::map(cases, \(x) do.call(run_case, x)) |> purrr::list_rbind()
  save_result(tbl, "sensitivity")
  invisible(tbl)
}

if (sys.nframe() == 0) {
  for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R",
              "R/30_robust.R", "R/32_misestimation.R")) source(f)
  print(as.data.frame(main_35()), digits = 3)
}
