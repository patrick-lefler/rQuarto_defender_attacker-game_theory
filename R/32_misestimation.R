# Misestimation Monte Carlo with common random numbers.

misest_multipliers <- function(n = N_MC, sigma = MISEST_SIGMA, seed = SEED, p = 6) {
  set.seed(seed)
  matrix(exp(stats::rnorm(n * p, 0, sigma)), nrow = n, ncol = p)
}

# strategies: named list of coverage vectors built on the firm's belief V
run_misestimation <- function(strategies, assets, n = N_MC, sigma = MISEST_SIGMA,
                              seed = SEED, mult = NULL) {
  if (is.null(mult)) mult <- misest_multipliers(n, sigma, seed, nrow(assets))
  Vtrue <- sweep(mult, 2, assets$V, `*`)
  draws <- purrr::imap(strategies, \(c, nm) {
    c <- unname(c)
    t <- best_response(c, assets, Vtrue)
    tibble::tibble(draw = seq_len(nrow(mult)), strategy = nm,
                   target = assets$asset_id[t], loss = -def_util(c, assets)[t])
  }) |> purrr::list_rbind()
  list(draws = draws, summary = summarise_misest(draws, assets))
}

summarise_misest <- function(draws, assets) {
  draws |>
    dplyr::summarise(
      mean = mean(loss), p50 = stats::median(loss),
      p90 = stats::quantile(loss, 0.90, names = FALSE),
      p95 = stats::quantile(loss, 0.95, names = FALSE),
      p99 = stats::quantile(loss, 0.99, names = FALSE),
      share_attacked_by_asset = list({
        tb <- table(factor(target, levels = assets$asset_id)) / dplyr::n()
        stats::setNames(as.numeric(tb), assets$asset_id)
      }),
      .by = strategy
    ) |>
    dplyr::mutate(top_target = purrr::map_chr(share_attacked_by_asset, \(s) names(s)[which.max(s)]),
                  top_share = purrr::map_dbl(share_attacked_by_asset, max))
}

main_32 <- function() {
  assets <- load_assets()
  base <- read_result("strategies_base")$strategies
  strats <- split(base, factor(base$strategy, levels = STRATEGIES)) |>
    purrr::map(\(d) d$coverage)
  res <- run_misestimation(strats, assets)
  save_result(res$draws, "misest_draws")
  save_result(res$summary, "misest_summary")
}
if (sys.nframe() == 0) {
  for (f in c("R/00_params.R", "R/01_utils.R")) source(f)
  main_32()
}
