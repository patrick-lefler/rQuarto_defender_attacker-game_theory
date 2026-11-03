test_that("two-asset example matches the reference", {
  r <- run_two_asset(assets)
  expect_equal(unname(r$equilibrium$coverage), c(0.4483, 0.5517), tolerance = 1e-3)
  expect_equal(r$equilibrium$target, "IDP")
  expect_equal(r$equilibrium$loss, 9.062, tolerance = 1e-3)
  expect_equal(r$eq_payoff, 2.862, tolerance = 1e-3)
  expect_equal(r$plans$crown_jewel$loss, 18.0, tolerance = 1e-3)
  expect_equal(r$plans$impact_proportional$loss, 13.37, tolerance = 1e-3)
})

test_that("SSE at the base budget is consistent", {
  s <- solve_sse(BUDGET_BASE, assets)
  expect_true(all(s$status %in% c("Optimal", "Infeasible")))
  expect_equal(s$target, assets$asset_id[best_response(unname(s$coverage), assets)])
  expect_lte(spend(s$coverage, assets), BUDGET_BASE + 1e-6)
})

test_that("SSE errors informatively when infeasible", {
  expect_error(solve_sse(1, assets), "no feasible")
})
