# Payoff functions, best response, allocation helpers, formatters.
# Requires 00_params.R to be sourced first.

load_assets <- function(path = file.path(PROJECT_ROOT, "data", "assets.csv")) {
  readr::read_csv(path, show_col_types = FALSE) |>
    dplyr::mutate(
      Ud_u = -L,
      Ud_c = -DEF_COVERED_SHARE * L,
      EL_heat = p_heat * L
    )
}

# Defender utility per target given coverage c (named or positional vector)
def_util <- function(c, assets) c * assets$Ud_c + (1 - c) * assets$Ud_u

# Attacker utility per target; V may be a vector or an n x 6 matrix (rows = draws)
att_util <- function(c, assets, V = assets$V) {
  if (is.matrix(V)) {
    sweep(V, 2, 1 - c, `*`) |> sweep(2, c * assets$A_c, `+`)
  } else {
    c * assets$A_c + (1 - c) * V
  }
}

spend <- function(c, assets) sum(assets$k * c)

# Strong tie-break: among targets within TOL of the attacker's max, pick the highest Ud.
best_response <- function(c, assets, V = assets$V, tol = TOL) {
  Ud <- def_util(c, assets)
  if (is.matrix(V)) {
    Ua <- att_util(c, assets, V)
    cand <- Ua >= apply(Ua, 1, max) - tol
    masked <- matrix(ifelse(cand, rep(Ud, each = nrow(Ua)), -Inf), nrow = nrow(Ua))
    max.col(masked, ties.method = "first")
  } else {
    Ua <- att_util(c, assets, V)
    cand <- which(Ua >= max(Ua) - tol)
    cand[which.max(Ud[cand])]
  }
}

# Realized defender loss when the crew (with payoffs V) best-responds to coverage c
realized_loss <- function(c, assets, V = assets$V) {
  t <- best_response(c, assets, V)
  -def_util(c, assets)[t]
}

# Quantal response probabilities with max-subtraction
qre_probs <- function(c, assets, lambda, V = assets$V) {
  z <- lambda * att_util(c, assets, V)
  z <- z - max(z)
  e <- exp(z)
  e / sum(e)
}

qre_loss <- function(c, assets, lambda, V = assets$V) {
  q <- qre_probs(c, assets, lambda, V)
  sum(q * -def_util(c, assets))
}

qre_grad <- function(c, assets, lambda, V = assets$V) {
  q <- qre_probs(c, assets, lambda, V)
  ell <- -def_util(c, assets)
  f <- sum(q * ell)
  ell_p <- -(1 - DEF_COVERED_SHARE) * assets$L
  a_p <- assets$A_c - V
  q * (ell_p + lambda * a_p * (ell - f))
}

# Formatters
fmt_m <- function(x, digits = 1) paste0("$", formatC(x, format = "f", digits = digits), "M")
fmt_pct <- function(x, digits = 0) paste0(formatC(100 * x, format = "f", digits = digits), "%")

read_result <- function(name) readRDS(file.path(RESULTS_DIR, paste0(name, ".rds")))
save_result <- function(x, name) saveRDS(x, file.path(RESULTS_DIR, paste0(name, ".rds")))
