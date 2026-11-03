# Textbook (Strong Stackelberg) equilibrium via multiple LPs. Defines solve_sse();
# when run as a script, also produces data/results/two_asset.rds.

solve_sse <- function(B, assets, V = assets$V, floor = COVERAGE_FLOOR) {
  n <- nrow(assets)
  ids <- assets$asset_id
  a <- assets$A_c - V
  gain <- assets$Ud_c - assets$Ud_u
  lower <- rep(floor, n)
  upper <- assets$c_max
  sols <- vector("list", n)
  status <- rep(NA_character_, n)

  for (ts in seq_len(n)) {
    others <- setdiff(seq_len(n), ts)
    A <- matrix(0, nrow = length(others) + 1, ncol = n)
    rhs <- numeric(length(others) + 1)
    for (i in seq_along(others)) {
      s <- others[i]
      A[i, s] <- a[s]
      A[i, ts] <- -a[ts]
      rhs[i] <- V[ts] - V[s]
    }
    A[nrow(A), ] <- assets$k
    rhs[nrow(A)] <- B
    obj <- numeric(n); obj[ts] <- gain[ts]
    res <- highs::highs_solve(
      L = obj, lower = lower, upper = upper, A = A,
      lhs = rep(-Inf, nrow(A)), rhs = rhs, maximum = TRUE
    )
    status[ts] <- as.character(res$status_message)
    if (identical(res$status, 7L) || grepl("optimal", status[ts], ignore.case = TRUE)) {
      sols[[ts]] <- res$primal_solution
    }
  }

  feas <- which(!vapply(sols, is.null, logical(1)))
  if (length(feas) == 0) stop("solve_sse: no feasible LP at B = ", B, " (status: ", paste(status, collapse = "; "), ")")

  ud_best <- vapply(feas, function(t) def_util(sols[[t]], assets)[t], numeric(1))
  best <- feas[which.max(ud_best)]
  cov <- stats::setNames(sols[[best]], ids)
  ua <- att_util(cov, assets, V)

  list(
    coverage = cov,
    target = ids[best],
    loss = -max(ud_best),
    status = stats::setNames(status, ids),
    attack_set = ids[ua >= max(ua) - TOL]
  )
}

# Two-asset worked example (PLAT vs IDP), unit cost 1 each, budget 1, no floor, c_max = 1
two_asset_assets <- function(assets) {
  a2 <- assets[assets$asset_id %in% c("PLAT", "IDP"), ]
  a2$k <- 1; a2$c_max <- 1
  a2
}

two_asset_plan <- function(cp, a2) {
  c2 <- c(PLAT = cp, IDP = 1 - cp)
  t <- best_response(unname(c2), a2)
  list(coverage = c2, target = a2$asset_id[t], loss = realized_loss(unname(c2), a2))
}

run_two_asset <- function(assets) {
  a2 <- two_asset_assets(assets)
  eq <- solve_sse(B = 1, assets = a2, floor = 0)
  grid <- tibble::tibble(c_PLAT = seq(0, 1, by = 0.005)) |>
    dplyr::mutate(
      PLAT = c_PLAT * a2$A_c[1] + (1 - c_PLAT) * a2$V[1],
      IDP = (1 - c_PLAT) * a2$A_c[2] + c_PLAT * a2$V[2]
    )
  plans <- list(
    crown_jewel = two_asset_plan(1, a2),
    impact_proportional = two_asset_plan(a2$L[1] / sum(a2$L), a2),
    equilibrium = two_asset_plan(unname(eq$coverage["PLAT"]), a2)
  )
  list(equilibrium = eq, grid = grid, plans = plans, assets2 = a2,
       eq_payoff = unname(att_util(eq$coverage, a2)[1]))
}

main_20 <- function() save_result(run_two_asset(load_assets()), "two_asset")

if (sys.nframe() == 0) {
  source("R/00_params.R"); source("R/01_utils.R")
  main_20()
}
