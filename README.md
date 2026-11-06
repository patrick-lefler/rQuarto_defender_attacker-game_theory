# Where Will the Attacker Strike?

Game-theoretic allocation of a security budget: a 500-person fintech firm splits a fixed budget across six assets, and a ransomware crew attacks the asset that pays it best. The site compares five allocation strategies (risk-ranked, proportional, uniform, textbook Stackelberg equilibrium, robust quantal-response equilibrium) and tests each against a misjudged attacker.

**Live site:** [patrick-lefler.com/rQuarto_defender_attacker-game_theory](https://patrick-lefler.com/rQuarto_defender_attacker-game_theory/)

All values are synthetic and illustrative. Not investment or security advice.

Medium rQuarto project (5 rendered pages). Specification: `Defender-Attacker-Game-Development-Plan.md`. Python reference: `reference_prototype.py` (used only to generate the expected values in the plan).

## Key results (base budget $9M)

| Strategy | Loss if we read the crew perfectly | Average loss if we misjudge it | 1-in-20 bad case |
|---|---|---|---|
| Robust equilibrium | $7.4M | $9.0M | $14.9M |
| Proportional | $10.6M | $10.7M | $22.3M |
| Uniform | $10.5M | $13.3M | $26.3M |
| Risk-ranked | $13.9M | $13.9M | $23.2M |
| Textbook equilibrium | $4.9M | $15.3M | $46.5M |

The textbook equilibrium is best on paper but brittle when our read of the crew is wrong. The robust strategy gives up a little on paper and is best once misjudgment is allowed for. It stays best in all eight sensitivity cases on the Governance page, including a lateral-movement scenario.

## Reproduce

```sh
Rscript -e 'renv::restore()'           # R >= 4.3, Quarto >= 1.5
Rscript R/run_all.R                    # all analyses + 7 diagnostics
Rscript -e 'testthat::test_dir("tests/testthat")'
quarto render                          # writes docs/
```

Run `R/run_all.R` from the terminal with `Rscript`, not with `source()` in an R session. It ends with `quit()`, which would close the session. The script exits non-zero if any diagnostic fails.

`freeze: auto` re-executes a page only when its own `.qmd` changes, not when the cached results it reads change. After re-running `R/run_all.R`, re-render each page (`quarto render <page>.qmd`) or delete `_freeze/` first. Otherwise a page can show stale numbers. This happened once during the build and was caught on the Governance page.

Scripts never render; pages never solve. Pages read cached results from `data/results/`. A page fails to render if a result file it reads is missing, so run `R/run_all.R` before `quarto render` after adding a script.

## Layout

| Path | Purpose |
|---|---|
| `params.yaml` | Every parameter, labeled as an assumption, with ranges |
| `R/00_params.R` | Reads `params.yaml` into the plan's constants |
| `R/01_utils.R` | Payoffs, best response, QRE loss and gradient, formatters |
| `R/20_solve_sse.R` | Textbook equilibrium (multiple LPs with `highs`), two-asset example |
| `R/21_baselines.R` | Risk-ranked, proportional, uniform |
| `R/30_robust.R` | Robust equilibrium (`nloptr` SLSQP, analytic gradient, multistart), `build_strategies()` |
| `R/31_qre_sweep.R` | Lambda sweep; lambda chosen on a separate simulation seed (`seed + 100`) |
| `R/32_misestimation.R` | Misestimation Monte Carlo and value-of-information results |
| `R/33_frontier.R` | Budget frontier and slider data |
| `R/34_alignment_check.R` | Alignment check (crew values proportional to our losses) |
| `R/35_sensitivity.R` | One-at-a-time sensitivity (A6, A7, A10) and lateral-movement scenario (A11) |
| `R/90_theme.R` | Strategy and asset names, colors, `theme_se()`, `gt_se()` |
| `R/99_wordcount.R` | Internal prose word counter (not shown on the site) |
| `R/run_all.R` | Runs everything, writes `diagnostics.rds` |
| `tests/testthat/` | Unit tests for the solvers, baselines and reference values |
| `data/assets.csv`, `data/assumptions_register.csv` | Asset parameters and assumptions register (A1–A11) |
| `data/results/` | Cached results read by the pages |
| `docs/` | Rendered site, served by GitHub Pages |

## Parameters (`params.yaml`)

| Name | Value | Meaning |
|---|---|---|
| `seed` | 20261103 | Seed for all random streams (lambda choice uses `seed + 100`) |
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

Sensitivity settings tested in `R/35_sensitivity.R`: covered share 5% and 20%; coverage floor 15% and 35%; sigma 0.20 and 0.50; identity loss 30 and corporate IT loss 22 for lateral movement.

## Diagnostics

`R/run_all.R` runs seven checks, all reported in the Governance page's diagnostics table:

1. SSE LPs solved without solver error
2. Best-response consistency
3. Budget constraint binding
4. Two-asset analytic match
5. Gradient check
6. Monte Carlo stability (seed + 1)
7. Robust minimizes the QRE objective at every budget

A word-count check (4,000-word prose cap) also runs and can fail the build, but it is printed to the terminal only and is not saved to `diagnostics.rds` or shown on the site.

## Decisions and deviations from the plan

- **Slider go/no-go (§8): GO.** The page loads the OJS runtime with zero external requests, and the slider updates correctly when served over http (tested headless with Chrome). If you open a page directly from disk via `file://`, browsers block the OJS modules and the slider does not appear. View the site through GitHub Pages or a local server (`python3 -m http.server -d docs`). The only external request in the site is MathJax from a CDN, on the two pages with math callouts (The Game and Robustness).
- **`embed-resources` removed (§9.1 deviation).** With `embed-resources: true` and `self-contained-math: true`, a full `quarto render` inlines each linked sibling page into the later pages, which grew them to 6 to 25 MB (the robustness page alone was 4.9 MB). Without them, the whole site is about 4 MB. To revert, restore the two lines in `_quarto.yml`, but the 5 MB check in §8 will then fail.
- **Navigation:** left sidebar with a `render:` list, `freeze: auto` and `theme.scss`, following the house style for these Quarto projects rather than the plan's navbar.
- **Parameters** live in `params.yaml` rather than hard-coded in `00_params.R`; values are those of §4.
- **Diagnostic 3 (budget binding):** the baselines bind exactly. The textbook LP maximizes coverage only on its chosen target, so it can leave budget unspent at high budgets. The robust solution leaves slack at one budget, where no further spending can lower its objective. Both are reported, not hidden.
- **Narrative claim corrected from the plan:** robust is the lowest-mean strategy at every budget on the grid except $5.5M (not "every budget tested"). Diagnostic 7 confirms this is a property of the misjudgment test, not an optimizer failure: robust still has the lowest QRE objective at $5.5M (13.54 vs 13.92). In the lambda sweep, robust is lowest from lambda = 1 upward, not at 0.25 or 0.5.
- **Lambda chosen out of sample:** lambda is selected on simulated crews drawn with `seed + 100` and reported on the main seed, so the choice is not tuned to the reported results. Lambda = 2 gives the lowest average loss on both.
- **"What perfect intelligence would be worth" callout:** renamed "How much each strategy relies on a perfect read". It reports each strategy's gap between the perfectly read and misjudged losses, which is not a true value of perfect information. True EVPI (re-optimizing against each crew) is computed in `R/32_misestimation.R` and saved to `evpi.rds`, but it is not shown on the site.
- **Alignment check:** reported as found. Risk-ranked still loses when crew values are proportional to our losses; concentration itself is the problem.
- **Lateral movement:** the model treats assets as independent (assumption A11). A simple lateral-movement scenario, with higher losses when identity or corporate IT is hit, is tested in the sensitivity table, and robust remains best.

## Open items

- Calibration references (IBM Cost of a Data Breach, Verizon DBIR, Coveware, Cyentia IRIS, FAIR Institute) are not yet cited. Each needs a verified edition, figure and full URL before it goes on the site.
- Visual QA at 390 px width: tables scroll inside their container, and figures scale. A second pass on a phone is still advisable.

## Change log

- 2026-11-03: Initial build. No change to the plan's §4 parameters.
- 2026-11-05: Review revisions:
  - Executive summary chart rebuilt.
  - "Where the crew strikes" chart replaces the ridgeline chart.
  - Sensitivity and lateral-movement table added (`R/35_sensitivity.R`, assumption A11).
  - Lambda chosen on a separate seed.
  - QRE-dominance diagnostic added.
  - Budget-frontier explanations added.
  - Word count removed from the site.
  - American spelling throughout.
  - Reproduce instructions added to the Governance page.
  - GitHub Pages enabled.
