# Runs the whole analysis in order, then the diagnostics. Run from the project root:
#   Rscript R/run_all.R
for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R",
            "R/30_robust.R", "R/31_qre_sweep.R", "R/32_misestimation.R", "R/33_frontier.R",
            "R/34_alignment_check.R", "R/99_wordcount.R")) source(f)

dir.create(RESULTS_DIR, showWarnings = FALSE, recursive = TRUE)
t0 <- Sys.time()
main_20(); main_30(); main_31(); main_32(); main_33(); main_34()

assets <- load_assets()
fr <- read_result("frontier")
f <- fr$frontier
chk <- function(check, ok, detail) tibble::tibble(check = check, result = if (isTRUE(ok)) "pass" else "FAIL", detail = detail)

# 1. SSE LPs without solver error
sse_ok <- fr$sse_ok && all(solve_sse(BUDGET_BASE, assets)$status %in% c("Optimal", "Infeasible"))
d1 <- chk("SSE LPs solved without solver error", sse_ok,
          sprintf("%d budgets on the grid, every LP optimal or infeasible", length(BUDGET_GRID)))

# 2. Best response consistency for every strategy at every budget
bc <- fr$coverage |>
  dplyr::summarise(tgt = assets$asset_id[best_response(coverage, assets)], .by = c(budget, strategy)) |>
  dplyr::left_join(f |> dplyr::select(budget, strategy, target_rational), by = dplyr::join_by(budget, strategy))
d2 <- chk("Best-response consistency", all(bc$tgt == bc$target_rational),
          sprintf("%d strategy-budget pairs rechecked", nrow(bc)))

# 3. Budget constraint binding. Baselines must spend B exactly. Textbook (SSE LP only maximizes
# coverage on the chosen target) and robust may leave slack: report it, and for robust verify
# that extra spend cannot lower the objective (no uncapped coordinate has a negative gradient).
full_cost <- sum(assets$k * assets$c_max)
bind <- f |> dplyr::mutate(slack = budget - spend) |> dplyr::filter(budget <= full_cost)
base_ok <- bind |>
  dplyr::filter(strategy %in% c("risk_ranked", "proportional", "uniform"), budget <= full_cost) |>
  dplyr::summarise(ok = all(abs(slack) < 1e-6)) |> dplyr::pull(ok)
rob_slack <- bind |> dplyr::filter(strategy == "robust", slack > 1e-6)
rob_cov <- fr$coverage |> dplyr::filter(strategy == "robust")
rob_kkt <- all(purrr::map_lgl(rob_slack$budget, \(B) {
  c <- rob_cov$coverage[rob_cov$budget == B]
  g <- qre_grad(c, assets, LAMBDA_ROBUST)
  all(g[c < assets$c_max - 1e-6] > -1e-6)
}))
tb_slack <- bind |> dplyr::filter(strategy == "textbook", slack > 1e-6)
d3 <- chk("Budget constraint binding",
          base_ok && rob_kkt && all(bind$slack > -1e-6),
          sprintf("Baselines bind where B <= %.1f. Textbook leaves slack at %d budgets (max %.2f); robust at %d (max %.2f, no improving move)",
                  full_cost, nrow(tb_slack), max(0, tb_slack$slack), nrow(rob_slack), max(0, rob_slack$slack)))

# 4. Two-asset analytic match: equal crew payoff 6 - 7c = -0.5 + 7.5c  => c = 6.5/14.5
ta <- read_result("two_asset")
d4 <- chk("Two-asset analytic match", abs(ta$equilibrium$coverage[["PLAT"]] - 6.5 / 14.5) < 1e-3,
          sprintf("PLAT coverage %.4f vs analytic %.4f", ta$equilibrium$coverage[["PLAT"]], 6.5 / 14.5))

# 5. Gradient check
set.seed(SEED)
gerr <- max(purrr::map_dbl(1:5, \(i) {
  x <- stats::runif(6, COVERAGE_FLOOR, assets$c_max)
  fd <- purrr::map_dbl(1:6, \(j) {
    e <- replace(numeric(6), j, 1e-6)
    (qre_loss(x + e, assets, LAMBDA_ROBUST) - qre_loss(x - e, assets, LAMBDA_ROBUST)) / 2e-6
  })
  max(abs(qre_grad(x, assets, LAMBDA_ROBUST) - fd))
}))
d5 <- chk("Gradient check", gerr < 1e-5, sprintf("max abs error %.1e at five points", gerr))

# 6. MC stability with SEED + 1
base <- read_result("strategies_base")$strategies
strats <- split(base, factor(base$strategy, levels = STRATEGIES)) |> purrr::map(\(d) d$coverage)
s0 <- read_result("misest_summary")
s1 <- run_misestimation(strats, assets, seed = SEED + 1)$summary
pct <- abs(s1$mean[match(s0$strategy, s1$strategy)] / s0$mean - 1)
same_rank <- identical(s0$strategy[order(s0$mean)], s1$strategy[order(s1$mean)])
d6 <- chk("Monte Carlo stability (seed + 1)", all(pct <= 0.05) && same_rank,
          sprintf("max change in mean %.1f%%; ranking %s", 100 * max(pct), if (same_rank) "unchanged" else "CHANGED"))


# 8. QRE dominance: robust minimizes its own objective (QRE loss at LAMBDA_ROBUST) at every
# budget. This shows the $5.5M exception on the frontier is a property of the misjudgment
# test, not an optimizer failure.
qd <- fr$coverage |>
  dplyr::arrange(budget, strategy, match(asset_id, assets$asset_id)) |>
  dplyr::summarise(obj = qre_loss(coverage, assets, LAMBDA_ROBUST), .by = c(budget, strategy)) |>
  dplyr::summarise(robust = obj[strategy == "robust"],
                   best_other = min(obj[strategy != "robust"]), .by = budget) |>
  dplyr::mutate(margin = best_other - robust)
tight <- qd |> dplyr::filter(margin > 1e-6) |> dplyr::slice_min(margin, n = 1)
d8 <- chk("Robust minimizes the QRE objective at every budget", all(qd$margin > -1e-6),
          sprintf("Robust lowest or tied at all %d budgets; closest call at %s: robust %.2f vs best other %.2f",
                  nrow(qd), fmt_m(tight$budget), tight$robust, tight$best_other))


# 7. Word count
wc <- wordcount_table(".")
d7 <- chk("Word count <= 4,000", wordcount_ok(wc),
          sprintf("%d prose words across %d of 5 pages written", sum(wc$prose, na.rm = TRUE), sum(!is.na(wc$prose))))

diag <- dplyr::bind_rows(d1, d2, d3, d4, d5, d6, d8) # word count is for internal use only
save_result(diag, "diagnostics")

pk <- c("highs", "nloptr", "dplyr", "ggplot2", "gt", "testthat")
save_result(list(
  r_version = R.version.string, seed = SEED,
  packages = stats::setNames(vapply(pk, \(p) as.character(utils::packageVersion(p)), ""), pk),
  built = format(Sys.time(), "%Y-%m-%d %H:%M"), session = utils::sessionInfo()
), "session_info")

print(as.data.frame(dplyr::bind_rows(diag, d7)), right = FALSE)
cat(sprintf("run_all finished in %.1f s\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
quit(status = if (all(c(diag$result, d7$result) == "pass")) 0 else 1)

