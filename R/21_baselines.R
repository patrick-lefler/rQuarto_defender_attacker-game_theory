# Baseline allocation rules: risk-ranked, proportional, uniform.

alloc_risk_ranked <- function(B, assets, floor = COVERAGE_FLOOR) {
  c <- rep(floor, nrow(assets))
  R <- B - sum(assets$k * c)
  for (j in order(-assets$EL_heat, seq_len(nrow(assets)))) {
    if (R <= 0) break
    room <- (assets$c_max[j] - c[j]) * assets$k[j]
    add <- min(room, R)
    c[j] <- c[j] + add / assets$k[j]
    R <- R - add
  }
  stats::setNames(c, assets$asset_id)
}

alloc_proportional <- function(B, assets, floor = COVERAGE_FLOOR) {
  c <- rep(floor, nrow(assets))
  R <- B - sum(assets$k * c)
  open <- rep(TRUE, nrow(assets))
  while (R > 1e-9 && any(open)) {
    w <- assets$EL_heat * open
    w <- w / sum(w)
    dc <- w * R / assets$k
    dc <- pmin(dc, assets$c_max - c)
    c <- c + dc
    R <- R - sum(assets$k * dc)
    open <- open & (assets$c_max - c > 1e-12)
  }
  stats::setNames(c, assets$asset_id)
}

alloc_uniform <- function(B, assets, floor = COVERAGE_FLOOR) {
  at <- function(m) pmin(pmax(m, floor), assets$c_max)
  if (spend(at(1), assets) <= B) return(stats::setNames(at(1), assets$asset_id))
  lo <- 0; hi <- 1
  for (i in 1:200) {
    mid <- (lo + hi) / 2
    if (spend(at(mid), assets) <= B) lo <- mid else hi <- mid
  }
  stats::setNames(at(lo), assets$asset_id)
}
