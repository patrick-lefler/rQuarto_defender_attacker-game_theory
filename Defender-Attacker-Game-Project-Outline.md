# Where Will the Attacker Strike?
## Game-Theoretic Allocation of a Security Budget — Project Outline (v2)

Format: Quarto website, 5 pages, R
Audience: senior risk executives, CISOs, board risk and audit committees
Working folder: `project_2026-11-02_rQuarto_defender_attacker_game`
Length cap: 4,000 words of prose for the whole site (code, tables, math and figure captions excluded)

### Decisions locked in v2

| Decision | Choice | Rationale |
|---|---|---|
| Number of assets | 6 | Enough to show defender and attacker valuing different assets; small enough that every asset can be explained within the 4,000-word cap |
| Firm | 500-person fintech software firm whose platform is critical infrastructure for its clients | A release-pipeline or platform compromise spreads to clients, which sharpens the board-level stakes |
| Attacker | A single strategic adversary: a ransomware crew | Concrete and familiar to boards; the uncertainty analysis focuses on how well we understand this one adversary |
| Budget slider | No slider on the executive page. One restrained slider on the budget-frontier section (page 4) | See section 4 |

---

## 1. The Core Idea

Most security budgets are allocated by ranking risks by expected loss and funding from the top down. That logic assumes the threat is fixed. A ransomware crew is not fixed. It probes defenses, buys access from brokers, and moves to whatever is now the softest target with good extortion leverage.

This project models the security budget as a Stackelberg game: the firm commits to an allocation of protective coverage across six assets, and the ransomware crew observes that allocation and picks its best target in response. The equilibrium allocation is then compared with the allocations firms actually use.

The board takeaway: a defensible security budget leaves the attacker no obviously good option. It does not simply protect the most valuable assets the most.

### Board questions the project answers

1. If we fund our top risks first, where does that push the ransomware crew?
2. How much residual risk does that cost us compared with an allocation that anticipates the attacker?
3. How much does the answer depend on correctly understanding what the crew wants?
4. What is the marginal value of the next $1M of security spend, and where should it go?

### The finding the project is built to test (not assume)

The gap between the risk-ranked plan and the equilibrium plan should be largest where the crew's preferences differ from the firm's. A ransomware crew values extortion leverage and ease of entry: identity, corporate IT, and anything that stops clients' operations. The firm's largest losses sit in the release pipeline (downstream liability to clients) and the production platform. When the two sets of preferences match, the plans converge. The size of the gap is the result, not a premise, and the convergence case is shown explicitly.

---

## 2. Language Choice: R

R is the right choice; Python offers no decisive advantage for this project.

| Need | R | Python |
|---|---|---|
| Multiple-LP Stackelberg solve | `ompr` + `ROI.plugin.glpk` or `highs` | `pyomo`, `scipy.optimize.linprog` |
| Bounded-rational attacker (nonlinear) | `nloptr`, `optim` | `scipy.optimize` |
| Game-theory specific library | none needed | `nashpy` (normal-form games only; not useful for Stackelberg security games) |
| Board-grade graphics and tables | `ggplot2`, `patchwork`, `gt` | comparable, more effort |

With 6 targets and one attacker, solver speed is irrelevant. Dropping multiple attacker types also removes the only mixed-integer program. Every solve is now a small LP, apart from the bounded-rationality extension.

---

## 3. The Model

### 3.1 The firm

A 500-person fintech software firm. Its cloud-hosted platform (for example, clearing, settlement, or payments-processing software) is used daily by banks, brokers, and market-infrastructure clients. A sustained outage or compromised release affects clients' operations as well as the firm's own. That makes the firm a critical third party in its clients' risk registers.

Illustrative scale for calibration: roughly $120M revenue and a security budget of roughly $8–10M. Both are synthetic and stated as such on page 3.

### 3.2 Six assets

| # | Asset | Defender's view (loss if hit) | Ransomware crew's view (value if hit) |
|---|---|---|---|
| 1 | Production platform (client-facing SaaS) | Very high: client outages, SLA penalties, regulatory attention | High: maximum leverage to force payment |
| 2 | Release pipeline (CI/CD, code signing) | Highest: compromised releases reach every client | Moderate: hard to monetize directly, slow payoff |
| 3 | Client data store | High: notification, contractual, regulatory | High: double-extortion material |
| 4 | Identity provider (SSO / IAM) | Moderate direct loss | Very high: domain-wide access and encryption at scale |
| 5 | Corporate IT (email, endpoints, file shares) | Low to moderate | High: cheap, reliable entry and broad encryption |
| 6 | Critical third-party provider (managed service or SaaS vendor) | Moderate, often underweighted | Moderate to high: weakest-link entry, little direct visibility for the firm |

The defender and attacker rankings deliberately differ, though not in every case. Assets 1 and 3 rank high for both; assets 2, 4 and 5 diverge.

### 3.3 Payoffs

For each target \(t\), four payoffs (in $M):

- \(U_d^c(t)\), \(U_d^u(t)\): defender payoff if \(t\) is attacked while covered or uncovered
- \(U_a^c(t)\), \(U_a^u(t)\): attacker payoff if the attack hits coverage (failed attempt, burned access) or succeeds (expected ransom plus data-sale value)

Defender losses are calibrated FAIR-style: a median and a 90% interval per asset, drawn from a lognormal. Attacker payoffs come from a simple ransomware economics model: expected ransom × probability of payment + data value − operating cost. Candidate calibration references (check current editions before citing): IBM/Ponemon Cost of a Data Breach, Verizon DBIR, Cyentia IRIS, Coveware quarterly ransomware reports, and FAIR Institute guidance.

### 3.4 Coverage and budget

Coverage \(c_t \in [0, \bar{c}_t]\) is the probability that an attack on \(t\) is stopped, with \(\bar{c}_t < 1\). Unit cost \(k_t\) varies by asset; the third-party provider is expensive to cover because the firm controls it only through contracts and monitoring.

\[
\sum_t k_t c_t \le B
\]

\[
U_d(t, c) = c_t U_d^c(t) + (1 - c_t) U_d^u(t), \qquad
U_a(t, c) = c_t U_a^c(t) + (1 - c_t) U_a^u(t)
\]

### 3.5 Solution concept: Strong Stackelberg Equilibrium

Multiple-LP method. For each candidate target \(t^*\):

\[
\max_c \; U_d(t^*, c) \quad \text{s.t.} \quad U_a(t^*, c) \ge U_a(t, c) \;\; \forall t, \quad \text{budget and bounds}
\]

Pick the \(t^*\) with the best defender value; this means six LPs. The equilibrium makes the crew indifferent across an "attack set" and prices every other asset out. The attack set is what the board should see.

### 3.6 Baseline allocations

| Strategy | Rule |
|---|---|
| Risk-ranked | Fund assets in order of expected loss until the budget runs out (the heat-map approach) |
| Proportional | Spend in proportion to expected loss |
| Uniform | Equal coverage everywhere |
| Equilibrium | Stackelberg solution |

The crew best-responds to each strategy, and the firm's realized expected loss is compared like for like.

### 3.7 Extensions (page 4)

1. Bounded rationality (quantal response). Real crews are opportunistic and noisy, so target choice follows \(P(t) \propto \exp(\lambda U_a(t, c))\). Sweep \(\lambda\) from near-random to fully rational. Does the equilibrium advantage hold up?
2. Misreading the crew. The firm's estimate of the crew's payoffs is wrong. Monte Carlo (5,000 draws) perturbs the true attacker payoffs, solves using the firm's belief, and evaluates against the true crew. The result is the dollar value of better threat intelligence.
3. Budget frontier. Residual risk against budget for each strategy, from $0 to full coverage. This gives the marginal value of the next $1M and shows how the crew's preferred target shifts as the budget grows.

---

## 4. The Slider Decision

The executive page gets no slider. A board member reading a pre-read or a printed pack needs one clear static chart; a slider on the first page invites fiddling rather than understanding, and it does not print.

Page 4 gets one restrained slider, at the budget frontier, because it shows something a static chart cannot show compactly. As the budget moves, the coverage bars rebalance and the crew's best-response target changes. Design rules to keep it from looking cheesy:

- One control only (budget), stepped in $0.5M increments, with no animation, colors that match the site palette, and no extra widgets
- Precomputed in R across the budget grid and passed with `ojs_define()`, then drawn with Observable Plot; nothing is computed live
- Two linked panels: coverage by asset under equilibrium against risk-ranked, plus a single-line readout ("At $8.5M, the crew targets Identity under risk-ranked; residual loss $X.XM against $Y.YM")
- A static frontier chart sits directly above it, so the page works even if the slider is ignored
- Check rendered page size with `embed-resources: true`. If OJS bloats the page or fails to embed, drop the slider and keep the static chart.

---

## 5. Site Structure and Word Budget

| Page | File | Prose words |
|---|---|---|
| 1. Executive Summary | `index.qmd` | 600 |
| 2. The Game | `01-the-game.qmd` | 750 |
| 3. Allocating the Budget | `02-allocation.qmd` | 950 |
| 4. Misreading the Attacker | `03-robustness.qmd` | 950 |
| 5. Governance & Audit | `04-governance.qmd` | 600 |
| Total | | 3,850 (150-word buffer) |

Words are counted from rendered prose, excluding code, tables, display math, and captions. `R/99_wordcount.R` strips chunks and callouts from each `.qmd` and reports page and site totals. It runs before every publish.

### Page 1 — Executive Summary (600 words; written last)

- The problem in two paragraphs: budgets are ranked, ransomware crews adapt
- Three headline findings, each with one number
- Hero figure: residual expected loss by strategy (four bars), with the crew's chosen target labeled on each bar
- "Questions to ask your CISO" box (four questions)
- One-line guide to the other pages

### Page 2 — The Game (750 words)

- Why "defend the most valuable asset" fails against an adaptive crew
- Two-asset worked example, solved in closed form: the release pipeline (high loss, hard target) against corporate IT (lower loss, soft target). Fully protecting the pipeline hands the crew corporate IT; the solution finds the coverage that leaves the crew indifferent.
- Figure: the crew's payoff lines for both targets as coverage shifts, with the indifference point marked
- Stackelberg setup and notation in a collapsible callout
- Three assumptions in plain terms: the crew observes coverage, commitment is credible, payoffs can be estimated

### Page 3 — Allocating the Budget (950 words)

- The firm and its six assets: a `gt` table with defender loss and crew value side by side
- Figure: defender loss rank against crew value rank (labeled scatter), which shows the divergence at a glance
- Equilibrium coverage and the attack set
- Strategy comparison: coverage by asset for each strategy (small multiples), plus a `gt` summary of spend, crew target, and expected loss
- Interpretation: why the equilibrium moves spend into identity and corporate IT, and what the risk-ranked plan leaves exposed
- Convergence check: set crew values equal to defender losses and show that the gap closes

### Page 4 — Misreading the Attacker (950 words)

- Bounded rationality: residual loss against \(\lambda\) for each strategy
- Misreading the crew: distribution of realized loss by strategy (ridgeline), with the value of threat intelligence as a dollar figure
- Budget frontier: static frontier chart with the current-budget marker, the marginal value of the next $1M, and the slider beneath it

### Page 5 — Governance & Audit (600 words)

- How a board should use this: as a challenge to the budget, not an allocation engine
- Assumptions register (`gt`): assumption, why it matters, how it could fail, where it is stress-tested
- Limitations: a single attack per period, one adversary type, no repeated play, coverage treated as a probability, synthetic calibration
- Link to the Three Questions model-governance framework
- Reproducibility and solver diagnostics (see the validation checks in section 7)

---

## 6. Repository Layout

```
project_2026-11-02_rQuarto_defender_attacker_game/
├── _quarto.yml
├── index.qmd
├── 01-the-game.qmd
├── 02-allocation.qmd
├── 03-robustness.qmd
├── 04-governance.qmd
├── R/
│   ├── 00_params.R            # 6 assets, payoffs, costs, budget, seed
│   ├── 10_simulate.R          # FAIR-style lognormal losses + ransomware economics
│   ├── 20_solve_sse.R         # multiple-LP Strong Stackelberg solver
│   ├── 21_baselines.R         # risk-ranked, proportional, uniform + best response
│   ├── 31_qre.R               # quantal-response attacker
│   ├── 32_misestimation.R     # Monte Carlo payoff perturbation
│   ├── 33_frontier.R          # budget sweep (also feeds the slider)
│   ├── 90_theme.R             # ggplot theme, palette, gt styling
│   ├── 99_wordcount.R         # prose word count per page and total
│   └── run_all.R              # run once, cache everything
├── data/
│   ├── assets.csv
│   └── results/*.rds
├── styles.css
└── docs/
```

Pages read only from cached `.rds` files and never re-solve, so the numbers are identical across pages.

### `_quarto.yml`

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

format:
  html:
    code-fold: true
    df-print: paged
    fig-width: 8
    fig-height: 5
    lightbox: true
    linkcolor: "#0166CC"
    theme: sandstone
    toc: true
    toc-depth: 3
    embed-resources: true
    self-contained-math: true
```

### Packages

`tidyverse`, `ompr`, `ompr.roi`, `ROI`, `ROI.plugin.glpk` (or `highs`), `nloptr`, `gt`, `patchwork`, `scales`, `ggrepel`, `ggridges`, optionally `renv`.

---

## 7. Build Order

1. `00_params.R`, `10_simulate.R`: build the asset table and confirm that the rank-divergence scatter actually shows divergence.
2. `20_solve_sse.R`: validate the solver on the two-asset example against the closed-form answer, then scale to six assets.
3. `21_baselines.R`: verify each baseline's attacker best response.
4. Gate check: if the equilibrium advantage is trivially small or implausibly large, revisit the calibration and log any change in the assumptions register.
5. `31_qre.R`, `32_misestimation.R`, `33_frontier.R`, then `run_all.R` caching.
6. Draft pages 2–5, figures first and then prose, keeping to the word budget.
7. Prototype the slider. Keep it only if it passes the design rules and page-size check in section 4.
8. Write page 1.
9. Run `99_wordcount.R` and confirm the total is at most 4,000. Render, run visual QA on every page, and publish to GitHub Pages.

### Validation checks (reported on page 5)

- All LPs return optimal status
- At each solution, the crew's chosen target really is a best response
- The budget constraint is binding, or the slack is explained
- The two-asset example matches the analytic solution
- Monte Carlo results are stable across seeds
- Site prose is at most 4,000 words
