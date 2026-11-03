# Development Plan — "Where Will the Attacker Strike?"
## R Quarto Website: Game-Theoretic Allocation of a Security Budget

Version 1.0 · 2026-11-03 · Owner: Patrick Lefler (Seeking Eureka)
Audience for this document: a coding agent building the project end to end
Companion files: `Defender-Attacker-Game-Project-Outline.md` (v2), `reference_prototype.py` (Python reference used to generate the expected values in §11)

---

## 0. How to Use This Document

- Build in the order given in §12. Do not move on from a phase until its acceptance checks pass.
- Every number in §4 is a fixed project parameter. Do not change one without logging it in `data/assumptions_register.csv` and in the change log (§14).
- §11 lists reference results from the prototype. Your R results must match within the stated tolerances. If they do not, there is a bug. Do not tune parameters to force a match.
- Prose limit: 4,000 words across the whole site (§9). This is a hard requirement.
- Ask the owner before you add pages, add attacker types, or change the narrative in §2.

---

## 1. Project Summary

A 500-person fintech software firm, whose cloud platform is critical infrastructure for its bank and broker clients, splits a fixed security budget across six assets. A ransomware crew observes the firm's defenses and attacks the asset that offers it the best payoff. The site compares five allocation strategies:

| Code | Label | Description |
|---|---|---|
| `risk_ranked` | Risk-ranked | Fund assets in descending order of heat-map expected loss until the budget runs out |
| `proportional` | Proportional | Spend in proportion to heat-map expected loss |
| `uniform` | Uniform | Equal coverage everywhere |
| `textbook` | Textbook equilibrium | Strong Stackelberg Equilibrium (SSE); assumes the crew is perfectly rational and its payoffs are known exactly |
| `robust` | Robust equilibrium | Minimizes expected loss against a quantal-response (noisy) crew, with \(\lambda = 2\) |

---

## 2. Narrative (Validated by Prototype)

The prototype produced a stronger, more honest storyline than the outline assumed. Build the site around it.

1. **Risk-ranking invites the attack.** Funding the top risks first leaves the identity provider at baseline coverage. The crew goes there. Expected loss per campaign: about $14.0M.
2. **The textbook equilibrium looks brilliant on paper.** It steers the crew toward low-impact corporate IT and cuts expected loss to about $4.9M. It does this by starving the release pipeline, because the crew does not value the pipeline.
3. **The textbook answer is brittle.** If the firm misjudges the crew's payoffs even modestly, the textbook allocation becomes the worst performer. Mean loss is about $15.3M, and the 95th percentile is about $46M, because the under-protected pipeline is a $60M asset.
4. **The robust equilibrium is the recommendation.** It still anticipates the attacker but hedges against misjudging it. Mean loss under uncertainty is about $9.0M, against $13.8M for risk-ranked, and the 95th percentile is about $15M against $23M. It beats every other strategy at every budget tested.
5. **Board message:** "Anticipate the attacker, but don't bet the firm on reading them perfectly."

Correction to outline v2: the outline promised a check showing that the gap closes when attacker and defender preferences align. The prototype does not support this. With aligned preferences, risk-ranked still loses (about $23.3M against $13.5M), because it concentrates spend regardless of what the attacker wants. Page 3 must report this as found, worded as "concentration itself is the problem, not just misreading the attacker," and must not claim convergence.

---

## 3. Technical Stack

### 3.1 Software

- R ≥ 4.3, Quarto ≥ 1.5
- `renv` for lockfile pinning (required)
- Packages:

| Purpose | Package | Notes |
|---|---|---|
| Data and plotting | `tidyverse` (`dplyr`, `tidyr`, `purrr`, `ggplot2`, `readr`, `tibble`) | |
| LP solver | `highs` | Primary. Fallback: `lpSolve` (all variables are non-negative, so it is compatible) |
| Nonlinear optimizer | `nloptr` | `NLOPT_LD_SLSQP` with analytic gradient (§5.6) |
| Tables | `gt` | |
| Figure composition | `patchwork`, `scales`, `ggrepel`, `ggridges` | |
| Tests | `testthat` | |
| Interactivity | Quarto OJS (built in) and Observable Plot | Page 4 slider only |

Do not use `ompr`. It is unnecessary at this scale and slower to render.

### 3.2 Repository

- Folder and repository name: `project_2026-11-02_rQuarto_defender_attacker_game`
- GitHub repository: private until the owner approves publication. Publish from the `docs/` folder on `main` via GitHub Pages.
- Before committing, check the Git author identity per the user's environment rules. Never invent an author.

### 3.3 Directory Layout (exact)

```
project_2026-11-02_rQuarto_defender_attacker_game/
├── _quarto.yml
├── index.qmd
├── 01-the-game.qmd
├── 02-allocation.qmd
├── 03-robustness.qmd
├── 04-governance.qmd
├── styles.css
├── R/
│   ├── 00_params.R
│   ├── 01_utils.R
│   ├── 20_solve_sse.R
│   ├── 21_baselines.R
│   ├── 30_robust.R
│   ├── 31_qre_sweep.R
│   ├── 32_misestimation.R
│   ├── 33_frontier.R
│   ├── 34_alignment_check.R
│   ├── 90_theme.R
│   ├── 99_wordcount.R
│   └── run_all.R
├── data/
│   ├── assets.csv
│   ├── assumptions_register.csv
│   └── results/              # all .rds outputs (git-tracked, small)
├── tests/
│   └── testthat/
│       ├── test-sse.R
│       ├── test-baselines.R
│       ├── test-robust.R
│       └── test-reference-values.R
├── renv.lock
├── README.md
└── docs/                     # rendered site
```

---

## 4. Parameters (fixed)

### 4.1 Global constants (`R/00_params.R`)

| Name | Value | Meaning |
|---|---|---|
| `SEED` | `20261103` | Seed for all random number generation |
| `BUDGET_BASE` | `9.0` | Allocable security budget, $M per year |
| `COVERAGE_FLOOR` | `0.25` | Hygiene baseline coverage on every asset (compliance minimum); its cost is included in the budget |
| `DEF_COVERED_SHARE` | `0.10` | Defender loss when an attack is stopped = 10% of the full loss (detection, response, containment) |
| `LAMBDA_ROBUST` | `2.0` | Rationality parameter for the robust strategy |
| `LAMBDA_GRID` | `c(0.25, 0.5, 1, 2, 3, 5, 10)` | Grid for the QRE sweep |
| `MISEST_SIGMA` | `0.35` | Lognormal σ of the multiplicative error on the crew's success payoffs |
| `N_MC` | `3000` | Monte Carlo draws |
| `BUDGET_GRID` | `seq(5.0, 20.0, by = 0.5)` | Frontier and slider grid (the minimum feasible budget is 4.875) |
| `N_STARTS` | `20` | Multistart count for the robust optimizer |
| `TOL` | `1e-7` | Tie tolerance for attacker best response |

Units: all money in $M. Loss figures are expected loss per targeted ransomware campaign; the model assumes one campaign per year. State this unit on every page where numbers appear.

### 4.2 Assets (`data/assets.csv`)

Exact columns and values:

| asset_id | asset_name | L | V | A_c | k | c_max | p_heat |
|---|---|---|---|---|---|---|---|
| PLAT | Production platform | 45 | 6.0 | -1.0 | 4.0 | 0.90 | 0.30 |
| PIPE | Release pipeline (CI/CD, code signing) | 60 | 2.5 | -1.0 | 3.0 | 0.90 | 0.15 |
| DATA | Client data store | 30 | 5.0 | -1.0 | 2.5 | 0.90 | 0.30 |
| IDP | Identity provider (SSO/IAM) | 18 | 7.0 | -0.5 | 2.0 | 0.90 | 0.25 |
| CORP | Corporate IT (email, endpoints, file shares) | 10 | 5.5 | -0.3 | 3.0 | 0.85 | 0.50 |
| VEND | Critical third-party provider | 20 | 4.0 | -0.5 | 5.0 | 0.70 | 0.20 |

Column definitions:
- `L`: defender loss if the asset is attacked and the attack succeeds ($M). Treat as the mean of a lognormal with σ = 0.8. Page 3 displays the implied median and 90% interval for context only; the model uses the mean.
- `V`: the crew's payoff on success ($M): expected ransom × probability of payment + data-resale value − operating cost.
- `A_c`: the crew's payoff when the attack hits coverage (burned access, tooling, exposure).
- `k`: cost ($M) to move the asset's coverage from 0 to 1. Coverage costs scale linearly.
- `c_max`: maximum achievable coverage (no control set is perfect; the vendor is capped lower because the firm controls it only indirectly).
- `p_heat`: annual likelihood rating from the firm's risk heat map, used only by the `risk_ranked` and `proportional` baselines.

Derived (compute, don't store): `Ud_u = -L`, `Ud_c = -DEF_COVERED_SHARE * L`, `EL_heat = p_heat * L`.

### 4.3 Calibration notes (for page 3 prose and the assumptions register)

Values are synthetic and must be labeled "illustrative" on the site. Calibration cites to add (verify current editions and URLs at build time, and include full URLs in the site): IBM Cost of a Data Breach Report, Verizon DBIR, Coveware quarterly ransomware reports, Cyentia IRIS, FAIR Institute materials. Do not quote specific figures from these sources unless you have verified them.

---

## 5. Model Specification

Notation: \(c \in \mathbb{R}^6\) is coverage, \(t\) indexes targets.

\[
U_d(t,c) = c_t U_d^c(t) + (1-c_t) U_d^u(t), \quad U_a(t,c) = c_t A^c_t + (1-c_t) V_t
\]

Feasible set \(\mathcal{C}(B)\): \(\text{floor} \le c_t \le c^{max}_t\) and \(\sum_t k_t c_t \le B\). Defender loss \(\ell_t(c) = -U_d(t,c)\).

### 5.1 Attacker best response — `best_response(c, assets, V = assets$V)`

Return the index of the target that maximizes \(U_a(t,c)\). Break ties within `TOL` in the defender's favor (the target with the highest \(U_d\)); this is the "strong" tie-break. The `V` argument allows the true crew payoffs to differ from the firm's belief (used in §5.8).

### 5.2 Textbook equilibrium — `solve_sse(B, assets, V = assets$V, floor = COVERAGE_FLOOR)`

Multiple-LP method. For each \(t^*\):

maximize \(c_{t^*}(U_d^c(t^*) - U_d^u(t^*))\)
subject to, for all \(s \ne t^*\): \(c_s(A^c_s - V_s) - c_{t^*}(A^c_{t^*} - V_{t^*}) \le V_{t^*} - V_s\),
plus \(\sum k_t c_t \le B\) and the bounds.

Take the feasible \(t^*\) with the highest \(U_d(t^*, c)\).
Return `list(coverage = <named numeric>, target = <asset_id>, loss = <numeric>, status = <chr per LP>, attack_set = <asset_ids with U_a within TOL of max>)`.
Stop with an informative error if no LP is feasible.

### 5.3 Risk-ranked — `alloc_risk_ranked(B, assets)`

Start every asset at the floor. Spend the remaining budget \(B - \sum k_t \cdot \text{floor}\) by filling assets to `c_max` in descending order of `EL_heat`. The last funded asset gets a partial fill.

### 5.4 Proportional — `alloc_proportional(B, assets)`

Start at the floor. Water-fill: add coverage \(\Delta c_t = w_t R / k_t\) with \(w_t \propto\) `EL_heat` over uncapped assets, where \(R\) is the remaining budget. Cap at `c_max`. Redistribute any leftover among uncapped assets. Iterate until \(R < 10^{-9}\) or every asset is capped.

### 5.5 Uniform — `alloc_uniform(B, assets)`

Bisect on a common level \(m\) so that \(c_t = \min(\max(m, \text{floor}), c^{max}_t)\) spends as much of \(B\) as possible.

### 5.6 Robust equilibrium — `solve_robust(B, assets, lambda = LAMBDA_ROBUST)`

Quantal response: \(q_t(c) = \exp(\lambda U_a(t,c)) / \sum_s \exp(\lambda U_a(s,c))\). Compute with max-subtraction for numerical stability.

Objective: minimize \(f(c) = \sum_t q_t(c)\, \ell_t(c)\) over \(\mathcal{C}(B)\).

Analytic gradient (required). With \(\ell'_j = -(1 - \text{DEF\_COVERED\_SHARE}) L_j\) and \(a'_j = A^c_j - V_j\):

\[
\frac{\partial f}{\partial c_j} = q_j \left[ \ell'_j + \lambda\, a'_j (\ell_j - f) \right]
\]

Optimizer: `nloptr` with `NLOPT_LD_SLSQP`, one inequality constraint \(\sum k_t c_t - B \le 0\) with its gradient \(k\), box bounds, `xtol_rel = 1e-8`, `maxeval = 2000`.

Multistart: run `N_STARTS` starts. Start 1 is the proportional allocation; the others are uniform random points in the box, scaled toward the floor until they are budget-feasible. Use `set.seed(SEED)`. Return the best solution.

Verify the gradient against finite differences in tests (§10).

### 5.7 QRE evaluation — `qre_loss(c, assets, lambda, V = assets$V)`

Returns \(f(c)\). Used both for evaluating every strategy and inside `solve_robust`.

### 5.8 Misestimation Monte Carlo — `run_misestimation(strategies, assets, n = N_MC, sigma = MISEST_SIGMA)`

- `set.seed(SEED)`. Draw an `n × 6` matrix of multipliers `exp(rnorm(., 0, sigma))`. True crew payoffs are `V_true = V * multiplier`; `A_c` stays fixed.
- Use common random numbers: every strategy is evaluated against the same draws.
- For each strategy's fixed coverage \(c\) (built on the firm's belief `V`), compute `best_response(c, V = V_true)` and the realized loss.
- Return a long tibble with columns `draw, strategy, target, loss`, and a summary tibble with `strategy, mean, p50, p90, p95, p99, share_attacked_by_asset`.

### 5.9 Strategy wrapper — `build_strategies(B, assets)`

Returns a named list of the five coverage vectors in the order `risk_ranked, proportional, uniform, textbook, robust`. All downstream code iterates over this list.

---

## 6. Analysis Scripts and Cached Outputs

All scripts source `00_params.R` and `01_utils.R`. Scripts never render; pages never solve.

| Script | Produces (`data/results/`) | Contents |
|---|---|---|
| `20_solve_sse.R` | `two_asset.rds` | Two-asset worked example (§7.2): solution, plus a grid of `c_PLAT` from 0 to 1 with the crew's payoffs for both targets |
| `21_baselines.R` + `30_robust.R` | `strategies_base.rds` | Tibble: `strategy, asset_id, coverage, spend`; plus `summary`: `strategy, target, loss_rational, qre2_loss` at `BUDGET_BASE` |
| `31_qre_sweep.R` | `qre_sweep.rds` | `strategy, lambda, expected_loss` over `LAMBDA_GRID` (strategies fixed at `BUDGET_BASE`) |
| `32_misestimation.R` | `misest_draws.rds`, `misest_summary.rds` | See §5.8 |
| `33_frontier.R` | `frontier.rds`, `slider_data.rds` | For each B in `BUDGET_GRID` and each strategy: `loss_rational, target_rational, mc_mean, mc_p95`, plus coverage by asset (long) for the slider. Re-solve the textbook and robust strategies per B. Reuse the same draws as §5.8. |
| `34_alignment_check.R` | `alignment.rds` | Set `V_aligned = L * mean(V) / mean(L)`. Recompute textbook and risk-ranked; report rational loss and target |
| `run_all.R` | all of the above + `session_info.rds`, `diagnostics.rds` | Runs everything in order, then runs the checks in §10.2 and writes pass/fail |

Expected runtime: under 2 minutes. If the frontier robust solves are slow, reduce `N_STARTS` to 8 for the frontier only and log the change.

---

## 7. Page Specifications

### 7.1 Global page rules

- Every page starts with a setup chunk (`#| include: false`) that loads packages, sources `R/90_theme.R`, and reads its `.rds` files.
- Chunk defaults: `echo: true` with `code-fold: true` (site-wide), `warning: false`, `message: false`.
- Every figure has a label (`#| label: fig-...`), a `fig-cap` of at most 25 words, and `fig-alt` text.
- Inline numbers come from cached results via inline R (`` `r fmt_m(x)` ``). Never hard-code a result in prose.
- Helper `fmt_m(x)` returns "$9.0M" (one decimal). Helper `fmt_pct(x)` returns "35%".
- Strategy display names and colors come from `90_theme.R` only.
- Math lives in collapsible callouts: `::: {.callout-note collapse="true" title="The math"}`.

### 7.2 Page 1 — `index.qmd` "Executive Summary" (≤ 600 words; written last)

Sections:
1. The problem (about 120 words): budgets are ranked; ransomware crews adapt.
2. Three findings (about 200 words), each with one inline number:
   - Risk-ranking leaves identity exposed; loss of about $14M against about $9M robust.
   - The textbook equilibrium looks best on paper and is worst under uncertainty; 95th percentile about $46M.
   - The robust allocation cuts expected loss by about 35% and the tail by about 35% against risk-ranked.
3. Hero figure `fig-hero`: for each of the five strategies, a pair of horizontal bars, "If we read the crew perfectly" (rational loss) and "If we misjudge the crew" (MC mean), with a p95 whisker on the misjudged bar and the robust strategy highlighted. Order bars by MC mean.
4. "Questions to ask your CISO" callout (four questions):
   - Where does our current plan push an attacker?
   - Which high-impact assets are we under-protecting because we assume attackers don't want them?
   - How would our allocation perform if our threat intelligence is wrong?
   - What does the next $1M buy under each approach?
5. "How to read this site": one line per page.

No slider on this page.

### 7.3 Page 2 — `01-the-game.qmd` "The Game" (≤ 750 words)

1. Why "defend the most valuable asset" fails (about 150 words).
2. Two-asset worked example. Parameters: PLAT (L 45, V 6, A_c −1) and IDP (L 18, V 7, A_c −0.5); unit cost 1 each; budget 1.0; no floor; `c_max` = 1.
   - Show three plans: protect the crown jewel (c = 1, 0), impact-proportional (c = 0.714, 0.286), and equilibrium.
   - Figure `fig-two-asset`: x-axis is coverage on PLAT (the remainder goes to IDP); two lines show the crew's payoff on each target; the equilibrium point is marked at the intersection; the three plans are annotated with the defender loss each produces.
   - `gt` table `tbl-two-asset`: plan, coverage, crew target, defender loss.
   - Expected values are in §11.1.
3. The setup in one paragraph, with notation in a collapsible callout (§5 formulas).
4. Three assumptions, stated plainly: the crew observes coverage; the firm's commitment is credible; payoffs can be estimated. Close with a forward pointer: page 4 relaxes the third assumption.

### 7.4 Page 3 — `02-allocation.qmd` "Allocating the Budget" (≤ 950 words)

1. The firm (about 100 words): 500 staff; the platform is critical infrastructure for clients; $9.0M allocable budget, including the 0.25 hygiene floor.
2. `tbl-assets` (`gt`): asset, defender loss (with implied median and 90% interval from the lognormal), crew value, cost to cover, coverage cap, heat-map likelihood. Footnote: "Illustrative values."
3. `fig-divergence`: labeled scatter of defender loss rank (x) against crew value rank (y), with a 45° reference line. Assets far from the line are where the two sides disagree.
4. Four strategies at the base budget, excluding robust (it is introduced on page 4):
   - `fig-coverage-small-multiples`: one panel per strategy, bars of coverage by asset; the crew's target is highlighted in each panel.
   - `tbl-strategy-summary` (`gt`): strategy, crew target, expected loss (rational crew).
5. Interpretation (about 250 words): risk-ranked funds PLAT and PIPE and leaves IDP at the floor; the textbook equilibrium equalizes the crew's payoff across five assets (every asset except PIPE, which the crew values too little to need coverage), lets the attack fall on CORP, and holds PIPE at the floor. End with: "This is the trap: the plan only works if we've read the crew perfectly."
6. Alignment check (about 120 words), reported as found (§2 correction).

### 7.5 Page 4 — `03-robustness.qmd` "Misreading the Attacker" (≤ 950 words)

1. Why the textbook answer is fragile (about 120 words): it relies on the crew being exactly indifferent across targets, so small errors tip it.
2. Misjudged payoffs:
   - `fig-misest-ridges`: ridgeline of the loss distribution per strategy, with the robust strategy highlighted and the p95 marked.
   - `tbl-misest` (`gt`): mean, median, p95, p99, and the asset the crew hits most often.
   - Callout: "value of better threat intelligence," calculated as robust MC mean minus robust rational loss (about $1.6M), and textbook MC mean minus textbook rational loss (about $10.4M). Explain that this measures how much each strategy depends on accurate intelligence.
3. Introduce the robust equilibrium (about 150 words, with the math collapsed): it assumes the crew mostly, but not always, picks the best target.
4. Noisy attackers: `fig-qre-sweep`, expected loss against \(\lambda\) (log x-axis) for all five strategies.
5. Budget frontier:
   - `fig-frontier`: static chart of MC mean loss against budget for all five strategies, with a vertical marker at $9.0M.
   - One sentence on the marginal value of the next $1M under robust and under risk-ranked, computed from `frontier.rds` at $9.0M → $10.0M.
   - Slider (§8), directly beneath the static chart.

### 7.6 Page 5 — `04-governance.qmd` "Governance & Audit" (≤ 600 words)

1. How a board should use this (about 150 words): as a challenge to the budget, not an allocation engine.
2. `tbl-assumptions` (`gt`), from `data/assumptions_register.csv` with columns `id, assumption, why_it_matters, how_it_could_fail, where_tested`. At least eight rows:
   - one campaign per year
   - single adversary type
   - the crew observes coverage
   - linear coverage cost
   - coverage as a probability
   - the 10% covered-loss share
   - the 0.25 floor
   - synthetic calibration
   - \(\lambda = 2\) choice
3. Limitations (about 120 words): no repeated play, no deception or honeypots, no other attacker types, and a static budget.
4. Link to the Three Questions model-governance framework (link to the owner's published page; ask the owner for the URL if it isn't in the repository).
5. Diagnostics: `tbl-diagnostics` from `diagnostics.rds` (check, result, detail), followed by a session-info summary (R version, key package versions, seed).

---

## 8. Slider Specification (page 4 only)

- Data: in an R chunk, `ojs_define(slider = slider_data)`, a long table with `budget, strategy, asset_id, coverage, target_rational, mc_mean`. Restrict the strategies to `risk_ranked` and `robust`.
- Control: `viewof budget = Inputs.range([5, 20], {step: 0.5, value: 9, label: "Allocable budget ($M)"})`.
- Output 1: Observable Plot grouped horizontal bars, coverage by asset for the two strategies, using the same colors as the ggplot theme. No animation and no transitions.
- Output 2: a single sentence in a styled `div`: "At $X.XM, the crew's best target is [asset] under risk-ranked and [asset] under robust. Expected loss if we misjudge the crew: $A.AM against $B.BM."
- Font, colors, and spacing match the site (§9.2). No other inputs, tooltips, or legends beyond a simple color key.
- Go/no-go: render with `embed-resources: true`. If the page fails to load the OJS runtime offline, or the page exceeds 5 MB, remove the slider and keep `fig-frontier`. Record the decision in the README.

---

## 9. Site Configuration and Styling

### 9.1 `_quarto.yml` (exact)

```yaml
project:
  type: website
  output-dir: docs

website:
  title: "Where Will the Attacker Strike?"
  description: "Game-Theoretic Allocation of a Security Budget"
  navbar:
    left:
      - href: index.qmd
        text: "Executive Summary"
      - href: 01-the-game.qmd
        text: "The Game"
      - href: 02-allocation.qmd
        text: "Allocating the Budget"
      - href: 03-robustness.qmd
        text: "Misreading the Attacker"
      - href: 04-governance.qmd
        text: "Governance & Audit"
  page-footer:
    center: "Seeking Eureka · Illustrative synthetic analysis · Not investment or security advice"

format:
  html:
    code-fold: true
    df-print: paged
    fig-width: 8
    fig-height: 5
    lightbox: true
    linkcolor: "#0166CC"
    theme: sandstone
    css: styles.css
    toc: true
    toc-depth: 3
    embed-resources: true
    self-contained-math: true

execute:
  warning: false
  message: false
```

### 9.2 Theme (`R/90_theme.R`)

- `theme_se()`: based on `theme_minimal(base_size = 12)`, with a left-aligned bold title, a gray subtitle, no minor gridlines, and the legend at the top.
- Strategy palette (named vector `STRAT_COLS`), ordered for display as robust, textbook, proportional, uniform, risk-ranked:

| Strategy | Color |
|---|---|
| robust | `#0166CC` |
| textbook | `#D98C3A` |
| proportional | `#8C8C8C` |
| uniform | `#B5B5B5` |
| risk_ranked | `#4D4D4D` |

- `STRAT_LABELS` maps codes to the display labels in §1.
- Asset labels: use `asset_name` short forms ("Platform", "Pipeline", "Client data", "Identity", "Corporate IT", "Vendor").
- `gt_se(tbl)`: applies consistent `gt` styling (no stripes, a light header fill `#F2F2F2`, numbers right-aligned, $M formatted to one decimal).
- Figures must be readable in grayscale; robust and textbook must also be distinguishable by line type or labels.

### 9.3 Word budget and `R/99_wordcount.R`

| Page | Max prose words |
|---|---|
| index.qmd | 600 |
| 01-the-game.qmd | 750 |
| 02-allocation.qmd | 950 |
| 03-robustness.qmd | 950 |
| 04-governance.qmd | 600 |
| Site total | 4,000 (hard cap) |

The counter reads each `.qmd` and removes:
- YAML front matter
- fenced code chunks (`` ```{r} ``, `` ```{ojs} ``)
- display math (`$$...$$`)
- pipe tables (lines beginning with `|`)
- `#|` chunk options
- HTML comments

Inline R is counted as one word. Callout contents count. It prints a per-page and total table and exits non-zero if any page or the total is over its limit.

---

## 10. Testing and Validation

### 10.1 Unit tests (`tests/testthat/`)

| Test | Requirement |
|---|---|
| `test-sse.R` | Two-asset example matches §11.1 within 1e-3. At the base budget, every LP status is optimal or infeasible (no errors), the returned target is the `best_response` of the returned coverage, and spend ≤ B + 1e-6 |
| `test-baselines.R` | Every allocation respects the bounds and the budget; spend equals B within 1e-6 when B ≤ full-coverage cost; risk-ranked fills in `EL_heat` order |
| `test-robust.R` | The analytic gradient matches central finite differences (h = 1e-6) within 1e-5 at five random feasible points; the solution is feasible; the robust objective at the solution is ≤ the objective at the proportional starting point |
| `test-reference-values.R` | Base-budget results match §11.2 within the tolerances in §11.3 |

### 10.2 Run-time diagnostics (`diagnostics.rds`, shown on page 5)

1. All SSE LPs solved without solver error.
2. Best-response consistency for every strategy at every budget on the grid.
3. Budget constraint binding (spend within 1e-6 of B) for all strategies on the grid where B ≤ full-coverage cost; otherwise slack is reported.
4. Two-asset analytic match.
5. Gradient check passed.
6. MC stability: rerun the misestimation with `SEED + 1`; the mean for each strategy is within ±5% and the strategy ranking by mean is unchanged.
7. Word count ≤ 4,000.

---

## 11. Reference Values (from `reference_prototype.py`)

### 11.1 Two-asset example

- Equilibrium: c = (PLAT 0.4483, IDP 0.5517); the crew attacks IDP; defender loss $9.062M; the crew's payoff on both targets is 2.862.
- Crown jewel (1, 0): the crew attacks IDP; loss $18.0M.
- Impact-proportional (0.714, 0.286): the crew attacks IDP; loss about $13.37M.

### 11.2 Base budget (B = 9.0)

| Strategy | PLAT | PIPE | DATA | IDP | CORP | VEND | Crew target | Rational loss | MC mean | MC p95 | QRE (λ = 2) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Risk-ranked | 0.900 | 0.758 | 0.250 | 0.250 | 0.250 | 0.250 | IDP | 13.95 | 13.82 | 23.2 | 13.65 |
| Proportional | 0.559 | 0.525 | 0.580 | 0.456 | 0.403 | 0.323 | IDP | 10.61 | 10.72 | 22.3 | 10.19 |
| Uniform | 0.462 | 0.462 | 0.462 | 0.462 | 0.462 | 0.462 | IDP | 10.52 | 13.58 | 26.3 | 12.40 |
| Textbook | 0.539 | 0.250 | 0.462 | 0.637 | 0.564 | 0.394 | CORP | 4.92 | 15.32 | 46.5 | 15.12 |
| Robust | 0.632 | 0.355 | 0.559 | 0.608 | 0.288 | 0.386 | CORP | 7.40 | 9.02 | 14.9 | 8.04 |

Other prototype observations to confirm:
- Robust has the lowest MC mean at every budget from 6 to 15.
- Choice of λ for the robust strategy: optimizing at λ = 1–2 gives the lowest misestimation MC mean (λ = 1: 9.26; λ = 2: 9.02; λ = 3: 9.89; λ = 5: 11.5). Report this on page 4 as the justification for `LAMBDA_ROBUST = 2`.
- Alignment check: textbook about 13.5 (IDP), risk-ranked about 23.3 (DATA).

### 11.3 Tolerances

| Quantity | Tolerance | Reason |
|---|---|---|
| Deterministic coverages and losses (risk-ranked, proportional, uniform, textbook) | ±0.005 coverage, ±1% loss | Same LP math; solver differences only |
| Robust coverages | ±0.02 | Nonconvex objective; the optimizer may land on a close local optimum |
| Robust loss | ±2% | |
| MC means and percentiles | ±5% | R and NumPy random number generators differ |
| Strategy ranking by MC mean | must match exactly | The narrative depends on it |

If the robust strategy's MC mean is not the lowest, stop and report the problem to the owner rather than adjusting parameters.

---

## 12. Build Phases and Acceptance Criteria

| Phase | Work | Done when |
|---|---|---|
| P0 Scaffold | Create the repository and folders, `renv::init()`, `_quarto.yml`, `styles.css`, placeholder pages | `quarto render` succeeds with placeholders |
| P1 Params and utils | `00_params.R`, `assets.csv`, `01_utils.R` (payoff functions, `best_response`, formatters) | Unit tests for helpers pass |
| P2 Textbook SSE | `20_solve_sse.R`, two-asset example | `test-sse.R` passes; §11.1 matches |
| P3 Baselines | `21_baselines.R` | `test-baselines.R` passes; §11.2 rows 1–3 match |
| P4 Robust | `30_robust.R`, gradient | `test-robust.R` passes; robust row matches |
| P5 Analyses | Scripts 31–34, `run_all.R`, diagnostics | `test-reference-values.R` passes; all diagnostics pass |
| P6 Figures | All figures in a scratch `.qmd` first | Each figure passes the visual QA in §13 |
| P7 Pages 2–5 | Prose plus embedded figures and tables | Each page renders; each is within its word budget |
| P8 Slider | §8 | Go/no-go recorded |
| P9 Page 1 | Executive summary | Within 600 words; every inline number comes from the cached results |
| P10 QA and publish | §13 checklist, README | Owner approves before the repository is made public or Pages is enabled |

---

## 13. QA Checklist (before handing to the owner)

- [ ] `Rscript R/run_all.R` runs clean from a fresh clone after `renv::restore()`
- [ ] `testthat::test_dir("tests/testthat")` passes
- [ ] `Rscript R/99_wordcount.R` exits 0; total ≤ 4,000
- [ ] Every page reviewed in a browser at desktop width and at 390 px mobile width
- [ ] No clipped labels, overlapping annotations, or legends covering data; captions don't wrap awkwardly
- [ ] Strategy colors and labels are consistent across every figure and table
- [ ] No hard-coded result numbers in prose (search the `.qmd` files for `\$[0-9]` outside inline R)
- [ ] "Illustrative" labeling appears on pages 1 and 3 and in the footer
- [ ] All external references carry full URLs that have been checked at build time
- [ ] The README covers purpose, how to reproduce, the parameter table, the slider decision, and the change log

---

## 14. Change Log and Out of Scope

Change log: keep a dated list in `README.md` of any change to §4 parameters, with its reason.

Out of scope (do not build):
- multiple attacker types
- repeated or dynamic games
- deception and honeypots
- live R computation in the browser (Shiny)
- additional pages
- PDF output

Candidate follow-ons, mentioned once on page 5 only: repeated play, attacker-type mixtures, and a link to the attack-graph Markov chain project.
