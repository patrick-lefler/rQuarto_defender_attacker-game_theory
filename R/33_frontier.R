# Budget frontier: re-solve every strategy at each budget, evaluate rational and MC loss.
main_33 <- function(n_starts = N_STARTS) {
  assets <- load_assets()
  mult <- misest_multipliers()
  rows <- vector("list", length(BUDGET_GRID))
  covs <- vector("list", length(BUDGET_GRID))
  sse_ok <- logical(length(BUDGET_GRID))

  for (i in seq_along(BUDGET_GRID)) {
    B <- BUDGET_GRID[i]
    sse <- solve_sse(B, assets)
    sse_ok[i] <- all(sse$status %in% c("Optimal", "Infeasible"))
    strats <- list(
      risk_ranked = alloc_risk_ranked(B, assets),
      proportional = alloc_proportional(B, assets),
      uniform = alloc_uniform(B, assets),
      textbook = sse$coverage,
      robust = solve_robust(B, assets, n_starts = n_starts)
    )
    mc <- run_misestimation(strats, assets, mult = mult)$summary
    rows[[i]] <- purrr::imap(strats, \(c, nm) tibble::tibble(
      budget = B, strategy = nm,
      loss_rational = realized_loss(unname(c), assets),
      target_rational = assets$asset_id[best_response(unname(c), assets)],
      br_consistent = TRUE,
      spend = spend(c, assets),
      mc_mean = mc$mean[mc$strategy == nm],
      mc_p95 = mc$p95[mc$strategy == nm]
    )) |> purrr::list_rbind()
    covs[[i]] <- purrr::imap(strats, \(c, nm) tibble::tibble(
      budget = B, strategy = nm, asset_id = assets$asset_id, coverage = unname(c)
    )) |> purrr::list_rbind()
  }
  frontier <- purrr::list_rbind(rows)
  cov_long <- purrr::list_rbind(covs)
  slider <- cov_long |>
    dplyr::filter(strategy %in% c("risk_ranked", "robust")) |>
    dplyr::left_join(
      frontier |> dplyr::select(budget, strategy, target_rational, mc_mean),
      by = dplyr::join_by(budget, strategy)
    )
  save_result(list(frontier = frontier, coverage = cov_long, sse_ok = all(sse_ok)), "frontier")
  save_result(slider, "slider_data")
}
if (sys.nframe() == 0) {
  for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R",
              "R/30_robust.R", "R/32_misestimation.R")) source(f)
  main_33()
}
