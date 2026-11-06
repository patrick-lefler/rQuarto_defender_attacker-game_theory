# Where Will the Attacker Strike?

Game-theoretic allocation of a security budget: a 500-person fintech firm splits a fixed budget across six assets, and a ransomware crew attacks the asset that pays it best. The site compares five allocation strategies (risk-ranked, proportional, uniform, textbook Stackelberg equilibrium, robust quantal-response equilibrium) and tests each against a misjudged attacker.

All values are synthetic and illustrative. Not investment or security advice.

Medium rQuarto project (5 rendered pages). Specification: `Defender-Attacker-Game-Development-Plan.md`. Python reference: `reference_prototype.py` (used only to generate the expected values in the plan).

## Reproduce

```sh
Rscript -e 'renv::restore()'           # R >= 4.3, Quarto >= 1.5
Rscript R/run_all.R                    # all analyses + 7 diagnostics, about 2 s
Rscript -e 'testthat::test_dir("tests/testthat")'
quarto render                          # writes docs/
```

`freeze: auto` re-executes a page only when its own `.qmd` changes, not when the cached results it reads change. After re-running `R/run_all.R`, re-render each page (`quarto render <page>.qmd`) or delete `_freeze/` first. Otherwise a page can show stale numbers; this happened once during the build and was caught on the Governance page.

Scripts never render; pages never solve. Pages read cached results from `data/results/`.

## Layout

| Path | Purpose |
|---|---|
| `params.yaml` | Every parameter, labelled as an assumption, with ranges |
| `R/00_params.R` | Reads `params.yaml` into the plan's constants |
| `R/01_utils.R` | Payoffs, best response, QRE loss and gradient, formatters |
| `R/20_solve_sse.R` | Textbook equilibrium (multiple LPs with `highs`), two-asset example |
| `R/21_baselines.R` | Risk-ranked, proportional, uniform |
| `R/30_robust.R` | Robust equilibrium (`nloptr` SLSQP, analytic gradient, multistart), `build_strategies()` |
| `R/31_qre_sweep.R` ... `R/34_alignment_check.R` | Lambda sweep and lambda choice, misestimation Monte Carlo, frontier and slider data, alignment check |
| `R/90_theme.R` | Strategy names, colours, `theme_se()`, `gt_se()` |
| `R/99_wordcount.R` | Prose word counter |
| `R/run_all.R` | Runs everything, writes `diagnostics.rds` |
| `data/assets.csv`, `data/assumptions_register.csv` | Asset parameters and assumptions register |

## Parameters (`params.yaml`)

| Name | Value | Meaning |
|---|---|---|
| `seed` | 20261103 | Seed for all random streams |
| `budget_base` | 9.0 | Allocable budget, $M per year |
| `coverage_floor` | 0.25 | Hygiene coverage on every asset (cost inside the budget) |
| `def_covered_share` | 0.10 | Defender loss when an attack is stopped, share of full loss |
| `lambda_robust` | 2.0 | Rationality parameter of the robust strategy |
| `lambda_grid` | 0.25, 0.5, 1, 2, 3, 5, 10 | QRE sweep grid |
| `misest_sigma` | 0.35 | Lognormal sigma of the error on the crew's payoffs |
| `n_mc` | 3000 | Monte Carlo draws |
| `budget_grid` | 5 to 20 by 0.5 | Frontier and slider grid (minimum feasible budget 4.875) |
| `n_starts` | 20 | Multistart count for the robust optimizer |
| `tol` | 1e-7 | Tie tolerance for the attacker's best response |

## Decisions and deviations from the plan

- **Slider go/no-go (§8): GO.** The page loads the OJS runtime with zero external requests and the slider updates correctly when served over http (tested headless with Chrome). Opened directly from disk via `file://`, browsers block the OJS modules and the slider does not appear, so view the site through GitHub Pages or a local server (`python3 -m http.server -d docs`). The only external request in the site is MathJax from a CDN on the two pages that contain math callouts.
- **`embed-resources` removed (§9.1 deviation).** With `embed-resources: true` and `self-contained-math: true`, a full `quarto render` inlines each linked sibling page into the later pages, which grew them to 6 to 25 MB (the robustness page alone was 4.9 MB). Without them the whole site is about 3 MB. Revert by restoring the two lines in `_quarto.yml`, but the 5 MB check in §8 will then fail.
- **Navigation:** left sidebar with `render:` list, `freeze: auto` and `theme.scss`, per the `rquarto-project` skill rather than the plan's navbar.
- **Parameters** live in `params.yaml` rather than hard-coded in `00_params.R`; values are those of §4.
- **Diagnostic 3 (budget binding):** the baselines bind exactly. The textbook LP maximizes coverage only on its chosen target, so it can leave budget unspent at high budgets, and the robust solution leaves slack at one budget where no further spend can lower its objective. Both are reported, not hidden.
- **Narrative claim corrected from the plan:** robust is the lowest-mean strategy at every budget on the grid except $5.5M (not "every budget tested"), and in the lambda sweep it is lowest from lambda = 1 upward, not at 0.25 and 0.5.
- **Alignment check:** reported as found. Risk-ranked still loses when crew values are proportional to our losses; concentration itself is the problem.

## Open items

- Calibration references (IBM Cost of a Data Breach, Verizon DBIR, Coveware, Cyentia IRIS, FAIR Institute) are not yet cited. The owner is adding them; each needs a verified edition, figure and full URL before it goes on the site.
- The repository is public on GitHub (`patrick-lefler/rQuarto_defender_attacker-game_theory`). The rendered `docs/` folder is added in a separate PR, and GitHub Pages (source `main`, folder `/docs`) is enabled only after the owner approves.
- Visual QA at 390 px width: tables now scroll inside their container; figures scale. A second pass on the owner's own device is still advisable.

## Change log

- 2026-11-05: Initial build. No change to the plan's §4 parameters.
