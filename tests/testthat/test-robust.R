test_that("analytic gradient matches central finite differences", {
  set.seed(1)
  for (i in 1:5) {
    x <- stats::runif(6, COVERAGE_FLOOR, assets$c_max)
    g <- qre_grad(x, assets, LAMBDA_ROBUST)
    h <- 1e-6
    fd <- vapply(1:6, function(j) {
      e <- replace(numeric(6), j, h)
      (qre_loss(x + e, assets, LAMBDA_ROBUST) - qre_loss(x - e, assets, LAMBDA_ROBUST)) / (2 * h)
    }, numeric(1))
    expect_lt(max(abs(g - fd)), 1e-5)
  }
})

test_that("robust solution is feasible and improves on the starting point", {
  c <- solve_robust(BUDGET_BASE, assets)
  expect_true(all(c >= COVERAGE_FLOOR - 1e-9 & c <= assets$c_max + 1e-9))
  expect_lte(spend(c, assets), BUDGET_BASE + 1e-6)
  start <- alloc_proportional(BUDGET_BASE, assets)
  expect_lte(qre_loss(c, assets, LAMBDA_ROBUST), qre_loss(start, assets, LAMBDA_ROBUST) + 1e-9)
})

test_that("QRE probabilities sum to one and are stable at large lambda", {
  q <- qre_probs(unname(alloc_uniform(9, assets)), assets, 1e4)
  expect_equal(sum(q), 1)
  expect_false(anyNA(q))
})
