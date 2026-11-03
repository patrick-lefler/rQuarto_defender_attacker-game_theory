rel <- function(x, y) abs(x - y) / abs(y)

test_that("base-budget results match the prototype reference values", {
  strats <- build_strategies(BUDGET_BASE, assets)
  ref_cov <- list(
    risk_ranked  = c(0.900, 0.758, 0.250, 0.250, 0.250, 0.250),
    proportional = c(0.559, 0.525, 0.580, 0.456, 0.403, 0.323),
    uniform      = rep(0.462, 6),
    textbook     = c(0.539, 0.250, 0.462, 0.637, 0.564, 0.394),
    robust       = c(0.632, 0.355, 0.559, 0.608, 0.288, 0.386)
  )
  ref_loss <- c(risk_ranked = 13.95, proportional = 10.61, uniform = 10.52, textbook = 4.92, robust = 7.40)
  ref_qre <- c(risk_ranked = 13.65, proportional = 10.19, uniform = 12.40, textbook = 15.12, robust = 8.04)
  ref_target <- c(risk_ranked = "IDP", proportional = "IDP", uniform = "IDP", textbook = "CORP", robust = "CORP")
  for (s in names(strats)) {
    tol_c <- if (s == "robust") 0.02 else 0.005
    expect_true(all(abs(unname(strats[[s]]) - ref_cov[[s]]) <= tol_c), info = s)
    tol_l <- if (s == "robust") 0.02 else 0.01
    expect_lt(rel(realized_loss(unname(strats[[s]]), assets), ref_loss[[s]]), tol_l)
    expect_lt(rel(qre_loss(unname(strats[[s]]), assets, 2), ref_qre[[s]]), 0.02)
    expect_equal(assets$asset_id[best_response(unname(strats[[s]]), assets)], ref_target[[s]])
  }
})

test_that("misestimation MC matches reference means/p95 within 5% and ranking exactly", {
  strats <- build_strategies(BUDGET_BASE, assets)
  s <- run_misestimation(lapply(strats, unname), assets)$summary
  ref_mean <- c(risk_ranked = 13.82, proportional = 10.72, uniform = 13.58, textbook = 15.32, robust = 9.02)
  ref_p95 <- c(risk_ranked = 23.2, proportional = 22.3, uniform = 26.3, textbook = 46.5, robust = 14.9)
  for (nm in names(ref_mean)) {
    r <- s[s$strategy == nm, ]
    expect_lt(rel(r$mean, ref_mean[[nm]]), 0.05)
    expect_lt(rel(r$p95, ref_p95[[nm]]), 0.05)
  }
  expect_equal(s$strategy[order(s$mean)], names(sort(ref_mean)))
})

test_that("robust has the lowest MC mean for budgets 6 to 15", {
  f <- read_result("frontier")$frontier
  for (B in seq(6, 15, by = 0.5)) {
    d <- f[f$budget == B, ]
    expect_equal(d$strategy[which.min(d$mc_mean)], "robust", info = B)
  }
})

test_that("alignment check matches the prototype", {
  a <- read_result("alignment")$summary
  expect_equal(a$loss_rational[a$strategy == "textbook"], 13.5, tolerance = 0.02)
  expect_equal(a$target[a$strategy == "textbook"], "IDP")
  expect_equal(a$loss_rational[a$strategy == "risk_ranked"], 23.3, tolerance = 0.02)
  expect_equal(a$target[a$strategy == "risk_ranked"], "DATA")
})
