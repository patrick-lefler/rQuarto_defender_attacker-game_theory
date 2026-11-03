# Alignment check: crew values proportional to defender losses.
main_34 <- function() {
  assets <- load_assets()
  V_al <- assets$L * mean(assets$V) / mean(assets$L)
  al <- assets; al$V <- V_al
  tb <- solve_sse(BUDGET_BASE, al, V = V_al)
  rr <- alloc_risk_ranked(BUDGET_BASE, al)
  out <- tibble::tibble(
    strategy = c("textbook", "risk_ranked"),
    target = c(tb$target, assets$asset_id[best_response(unname(rr), al, V_al)]),
    loss_rational = c(tb$loss, realized_loss(unname(rr), al, V_al))
  )
  save_result(list(summary = out, V_aligned = stats::setNames(V_al, assets$asset_id)), "alignment")
}
if (sys.nframe() == 0) {
  for (f in c("R/00_params.R", "R/01_utils.R", "R/20_solve_sse.R", "R/21_baselines.R")) source(f)
  main_34()
}
