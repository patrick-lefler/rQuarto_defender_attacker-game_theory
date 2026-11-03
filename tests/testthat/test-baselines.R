test_that("allocations respect bounds and budget", {
  for (B in c(5, 9, 14, 20)) {
    for (f in list(alloc_risk_ranked, alloc_proportional, alloc_uniform)) {
      c <- f(B, assets)
      expect_true(all(c >= COVERAGE_FLOOR - 1e-9 & c <= assets$c_max + 1e-9))
      expect_lte(spend(c, assets), B + 1e-6)
      if (B <= sum(assets$k * assets$c_max)) expect_equal(spend(c, assets), B, tolerance = 1e-6)
    }
  }
})

test_that("risk-ranked fills in heat-map expected-loss order", {
  c <- alloc_risk_ranked(BUDGET_BASE, assets)
  expect_equal(unname(c["PLAT"]), 0.9)
  expect_equal(unname(c["PIPE"]), 0.758, tolerance = 5e-3)
  expect_equal(unname(c[c("DATA", "IDP", "CORP", "VEND")]), rep(0.25, 4))
})

test_that("baselines match reference rows", {
  expect_equal(unname(alloc_proportional(9, assets)), c(0.559, 0.525, 0.580, 0.456, 0.403, 0.323), tolerance = 5e-3)
  expect_equal(unname(alloc_uniform(9, assets)), rep(0.462, 6), tolerance = 5e-3)
})
