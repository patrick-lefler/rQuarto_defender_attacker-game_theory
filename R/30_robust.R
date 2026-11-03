# Robust (quantal-response) allocation and the strategy wrapper.

solve_robust <- function(B, assets, lambda = LAMBDA_ROBUST, n_starts = N_STARTS,
                         floor = COVERAGE_FLOOR) {
  n <- nrow(assets)
  lo <- rep(floor, n); hi <- assets$c_max
  base_cost <- sum(assets$k * lo)
  if (B < base_cost - 1e-9) stop("solve_robust: budget below the floor cost (", base_cost, ")")

  starts <- vector("list", n_starts)
  starts[[1]] <- unname(alloc_proportional(B, assets, floor))
  set.seed(SEED)
  for (i in seq_len(n_starts)[-1]) {
    x <- stats::runif(n, lo, hi)
    extra <- sum(assets$k * (x - lo))
    s <- if (extra > 0) min(1, (B - base_cost) / extra) else 1
    starts[[i]] <- lo + s * (x - lo)
  }

  eval_f <- function(x) list(
    objective = qre_loss(x, assets, lambda),
    gradient = qre_grad(x, assets, lambda)
  )
  eval_g <- function(x) sum(assets$k * x) - B
  eval_jac <- function(x) matrix(assets$k, nrow = 1)

  best <- NULL
  for (x0 in starts) {
    res <- tryCatch(
      nloptr::nloptr(
        x0 = x0, eval_f = eval_f, eval_g_ineq = eval_g, eval_jac_g_ineq = eval_jac,
        lb = lo, ub = hi,
        opts = list(algorithm = "NLOPT_LD_SLSQP", xtol_rel = 1e-8, maxeval = 2000)
      ),
      error = function(e) NULL
    )
    if (is.null(res)) next
    x <- pmin(pmax(res$solution, lo), hi)
    if (sum(assets$k * x) > B + 1e-6) next
    val <- qre_loss(x, assets, lambda)
    if (is.null(best) || val < best$value) best <- list(x = x, value = val)
  }
  if (is.null(best)) stop("solve_robust: no feasible solution found at B = ", B)
  stats::setNames(best$x, assets$asset_id)
}

build_strategies <- function(B, assets, n_starts = N_STARTS) {
  list(
    risk_ranked  = alloc_risk_ranked(B, assets),
    proportional = alloc_proportional(B, assets),
    uniform      = alloc_uniform(B, assets),
    textbook     = solve_sse(B, assets)$coverage,
    robust       = solve_robust(B, assets, n_starts = n_starts)
  )
}

strategy_table <- function(strats, assets) {
  purrr::imap(strats, \(c, nm) tibble::tibble(
    strategy = nm, asset_id = assets$asset_id,
    coverage = unname(c), spend = unname(assets$k * c)
  )) |> purrr::list_rbind()
}

main_30 <- function() {
  assets <- load_assets()
  strats <- build_strategies(BUDGET_BASE, assets)
  summ <- purrr::imap(strats, \(c, nm) tibble::tibble(
    strategy = nm,
    target = assets$asset_id[best_response(unname(c), assets)],
    loss_rational = realized_loss(unname(c), assets),
    qre2_loss = qre_loss(unname(c), assets, 2)
  )) |> purrr::list_rbind()
  sse <- solve_sse(BUDGET_BASE, assets)
  save_result(list(strategies = strategy_table(strats, assets), summary = summ,
                   textbook_attack_set = sse$attack_set), "strategies_base")
}

if (sys.nframe() == 0) {
  for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R")) source(f)
  main_30()
}
