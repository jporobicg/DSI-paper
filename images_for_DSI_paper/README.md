# images_for_DSI_paper: redesigned figures

Figures for the manuscript *When does the history stop helping? Using a Data
Suitability Index and structural-change diagnostics to choose estimation windows
for a multispecies production model in the Gulf of Thailand*.

This folder is a redesign of the original figure package. The data in `Raw_data/`
are an unchanged copy; only the plotting code, layouts and captions changed. The aim
was less text inside the figures, one message per panel, direct labels instead of
legends where they fit, and every explanation moved to `caption.md`.

## Layout

```
redesign/
  README.md                    this file
  run_all.sh                   rebuilds every figure and refreshes review/
  _common/theme_dsi.R          palette, scenario encoding, theme, save_fig()
  Raw_data/                    every input the scripts read (unchanged copy)
  fig01_window_problem/        make_fig01.R, caption.md, fig01_window_problem.{pdf,png,svg}
  fig02_structural_change/     make_fig02.R, ...
  fig03_dsi_screening/         make_fig03.R, ...
  fig04_window_consequences/   make_fig04.R, ...
  fig05_retrospective/         make_fig05.R, ...   (was the top half of the old Fig. 5)
  fig06_startyear_scan/        make_fig06.R, ...   (was panel C of the old Fig. 5)
  figS1_dsi_components/        make_figS1.R, ...   (was panel C of the old Fig. 1)
  figS2_rv_cpue_breaks/        make_figS2.R, ...   (RV CPUE series with breakpoints)
  review/                      figNN_final.png copies of the final PNGs
```

## Running

```
./run_all.sh                     # all figures
cd fig03_dsi_screening && Rscript make_fig03.R   # one figure
```

Each script runs from its own folder, reads only `../Raw_data` and
`../_common/theme_dsi.R`, and writes a cairo PDF (fonts embedded), a 300 dpi PNG and
an SVG. Tested with R 4.x, ggplot2 3.5.1, patchwork 1.3.0, ragg and svglite. The
font is Liberation Sans (metric-compatible with Arial); install
`fonts-liberation` if it is missing.

## Graphical conventions

* All figures are 190 mm wide (double column), 8 pt base font at final size, axis
  text 7 pt, in-panel labels at least 6 pt.
* Panel tags are bold capitals at the top left of each panel.
* Scenario identity (Figs 4 and 5) is unchanged from the original package: one
  Okabe-Ito hue per family (full history grey; breakpoint-derived windows blue;
  Thai DOF convention vermilion; DSIr-derived windows green), with shape and line
  type inside a family. Fig. 5 repeats each window's symbol next to its row label so
  the two figures can be read together.
* Survey gaps are light grey bands; the 1987 break is a black dashed line;
  downward breaks are blue and upward breaks orange throughout.

## Which model results the figures use

Figures 4, 5 and 6 use the corrected catch scaling with the manuscript's qC3
configuration (`Raw_data/model_all_scenarios/` and `Raw_data/model_startyear_scan/`),
as decided on 2026-10-08. `Raw_data/results_production_model/` (the July runs with
per-fleet catch scaling) is kept for reference and is not plotted. The numbers in
the figures are exactly those in the CSV files; no value was altered. Two display
choices are worth knowing:

* Fig. 4A–B uses a log axis from 0.05; the two full-history projections below that
  (Indian mackerel 0.017, large pelagic finfish 0.00041) are drawn at the axis edge
  with their values printed.
* Fig. 5A starts each trajectory at the window's first modelled year (from
  `scenario_fit_summary.csv`). The CSV also stores the constant values carried
  before that year, which the old figure drew as flat lines.

## Figure-by-figure changes

| New figure | What changed and why |
|---|---|
| **Fig. 1** Window problem | (A) The window labels no longer sit on the CPUE series: the windows are drawn as a separate track above it. Each bar has the colour of the years it adds, which also colours the points in A and B, so no legend is needed (this also removes the out-of-order legend). (B) β is kept as a single short label per window; the p and n blocks are gone (n is visible from the points). (C) The 3 × 3 stacked-bar grid, value labels, subtitle and 5-item legend are replaced by one DSI–DSIr dumbbell per window and group. That carries the message of Methods §2.2 that DSIr discounts fragile windows. The component breakdown moved to Fig. S1, because the paper describes the weights in the Methods but never discusses the breakdown. |
| **Fig. 2** Structural change | (A) The level-shift, bootstrap and F-statistic text moved to the caption; only the "1987", "2016" and "no survey" labels remain. (B) Composition is merged into the catch block, so there are three blocks instead of four. Block names are rotated strips instead of wide bold labels, rows are tighter, and tiles became up/down triangles that encode direction by shape as well as colour. (C) The two annotations became one short line label ("95% of null maxima"); the 1987 bar is highlighted. Height went from 170 to 142 mm. |
| **Fig. 3** DSI screening | The three-line footnote and both in-panel notes moved to the caption. DSI and DSIr are labelled directly once (panel A). Candidate start years are labelled once, on the top axis of A. The level-shift/trend band was removed because it sat on top of the blue DSI shading; it is now quoted in the caption, and only the no-signal band remains (labelled once). DOF start and DSIr optimum share a one-line key. The panels are now separate plots with the standard tags, and D aligns with A–C. |
| **Fig. 4** Window consequences | Panel titles are shortened. Group names appear once. Windows are slightly offset within each group, over a shaded range bar, so coincident estimates no longer hide one another. The 7-window legend is one merged two-row key under the figure, ordered by family. C's axis title now sits under its own panels. |
| **Fig. 5** Retrospective, fit, hindcast | Split from the old Fig. 5. (A) The four retrospective panels are wider; "peels" and "all data" are labelled directly. (B) The Mohn's ρ heatmap has scenario symbols matching Fig. 4 and white text on saturated cells. (C) The mean-|ρ| columns became bars aligned with the heatmap rows, joined by the in-sample log RMSE on 2016–2023 and the one-year hindcast MASE. The paper's in-sample-fit figure (`scenario_skill.png`) had no counterpart in the original package; this panel replaces it with the corrected numbers. |
| **Fig. 6** Start-year scan | Split from the old Fig. 5C. The three panel titles and three legends are replaced by y-axis titles and line-end labels. The unexplained orange chevrons are now crosses above panel A with a direct label ("non-PD Hessian"; at least one fit at that floor lacked a positive-definite Hessian). |
| **Fig. S1** DSI components | The component breakdown from the old Fig. 1C, cleaned up: no value labels or subtitle, DSI tick and DSIr diamond in the key. Optional supplement. |
| **Fig. S2** RV CPUE breaks | New small-multiple of the RV CPUE series with their breakpoints. It supports the paper's current Figure `fig:rvcpue`, which Fig. 2B summarises but does not show. Optional supplement. |

### Merge and split decisions

* **Old Fig. 5 split into Figs 5 and 6.** The old figure was 235 mm tall and mixed
  two arguments. Fig. 5 compares the seven named windows (paper §3.4–3.5,
  `fig:skill`, `fig:mohn`, Table `tab:scenarios`). Fig. 6 scans every start-year
  floor against DSIr, which bears on the Discussion paragraph about whether DSI/DSIr
  and the RV breaks "point to the same period". The paper does not yet describe the
  scan (see notes below), so Fig. 6 could also go to the supplement.
* **Old Fig. 1C moved to the supplement (Fig. S1)**; Fig. 1C keeps only DSI vs DSIr.
* **Fig. S2 added** so that the paper's RV-CPUE-by-species figure (`fig:rvcpue`)
  still has a counterpart; it can be dropped if Fig. 2B is judged sufficient.
* Main-text count: 6 figures (the current .tex has 7 figure environments).

## Mapping to the manuscript

The .tex currently includes figures from `../Figures/DSI/` and
`../Figures/production_model/`. Suggested replacements:

| New figure | Replaces / supports in `paper.tex` | Label | Section |
|---|---|---|---|
| Fig. 1 | No current figure. Supports the DSI description and the "which years" question | (new, e.g. `fig:window`) | §1 Introduction (last paragraphs), §2.2 DSI |
| Fig. 2A | `../Figures/DSI/rv_ecosystem_index_breakpoints.png` | `fig:rvindex` | §3.1 |
| Fig. 2C | `../Figures/DSI/breakpoint_year_histogram.png` | `fig:hist` | §3.1 |
| Fig. 2B (+ Fig. S2) | `../Figures/DSI/rv_cpue_breakpoints.png` | `fig:rvcpue` | §3.1 |
| Fig. 3 | `../Figures/DSI/candidate_periods_on_dsi_aggregated.png` | `fig:dsi` | §3.2 (and Table `tab:candidates`) |
| Fig. 4C | `../Figures/production_model/scenario_biomass_trajectories.png` | `fig:biomass` | §3.3 |
| Fig. 4A–B | Supports Table `tab:proj` (2043) and the current-status statements | `fig:biomass` / `tab:proj` | §3.3, §3.6 |
| Fig. 5C (RMSE) | `../Figures/production_model/scenario_skill.png` | `fig:skill` | §3.4 |
| Fig. 5A–C (Mohn's ρ) | `../Figures/production_model/retro_mohn_rho.png` | `fig:mohn` | §3.5, Table `tab:scenarios` |
| Fig. 6 | No current figure. Start-year scan | (new, e.g. `fig:scan`) | §4 Discussion, or a new Results subsection |
| Fig. S1 | No current figure. DSI component weights | (supplement) | §2.2 |
| Fig. S2 | `../Figures/DSI/rv_cpue_breakpoints.png` (full series version) | `fig:rvcpue` | §3.1 / supplement |

Because Fig. 2 combines three current figures, the three `figure` environments in
§3.1 become one, and the references `fig:rvindex`, `fig:hist` and `fig:rvcpue` become
panel references to that single figure. Likewise `fig:skill` and `fig:mohn` become
panels of Fig. 5. Use the PDF versions in `\includegraphics` (vector, fonts embedded)
at `width=\textwidth`.

## Notes: manuscript text that differs from the figure data

These are differences between `paper.tex` and the corrected model outputs plotted
in Figs 4–6, or between the text and the DSI/breakpoint outputs. The paper was not
edited. Corrected values are from `Raw_data/model_all_scenarios/` unless stated.

**Retrospective stability (abstract, §3.5, Table 2, Discussion, Conclusions).** This is
the largest change: the corrected runs do not support "every restricted window
roughly halves or better the drift".

| Window | paper mean ρ | corrected mean ρ | paper mean \|ρ\| | corrected mean \|ρ\| |
|---|---|---|---|---|
| baseline (full) | +0.37 | +0.21 | 0.50 | 0.42 |
| post_1987 | +0.13 | +0.28 | 0.22 | **0.48** (largest of all windows) |
| thai_dof | +0.05 | −0.13 | 0.20 | 0.19 |
| recent_2016 | +0.01 | +0.12 | 0.16 | 0.33 (three peels only) |
| per_species | −0.07 | +0.26 | 0.10 | 0.36 |
| dsir_group | – | +0.07 | – | 0.13 (smallest) |
| dsir_channel | – | +0.09 | – | 0.35 |

* The post-1987 value is driven by sardines (ρ = 2.68). The full-history value is
  driven by neritic tuna (ρ = 2.23); without NTU it is 0.16, lower than every window
  except DSIr-group (0.15) and per-species (0.14).
* The Discussion argues that the full-history mean ρ (+0.37) exceeds the 0.20–0.30
  concern range while every restricted window lies within it. With the corrected
  values the full history is +0.21, inside the range, and post-1987 (+0.28) and
  per-species (+0.26) sit at its upper end.
* In the start-year scan (Fig. 6), the 1988 floor is a local spike (mean |ρ| 0.48)
  between two stable floors (1987: 0.09; 1989: 0.12). The post-1987 result is
  therefore sensitive to the exact start year.
* The abstract, the §3.5 text, the Discussion ("Restricting estimation to the
  post-change period roughly halves or better the drift") and the Conclusions
  ("post-change and per-species estimation windows are substantially more
  reliable"; "We recommend estimating ... from the post-1987 period") all need
  rechecking against these values.

**In-sample fit, 2016–2023 (§3.4, Table 2).** n CPUE obs is unchanged (291, 177,
215, 56, 183). The other columns change:

| Window | log RMSE (paper → corrected) | bias | corr |
|---|---|---|---|
| baseline | 0.380 → 0.399 | +0.096 → +0.104 | 0.969 → 0.966 |
| post_1987 | 0.390 → 0.404 | +0.050 → +0.002 | 0.966 → 0.964 |
| thai_dof | 0.378 → 0.398 | +0.093 → +0.096 | 0.969 → 0.966 |
| recent_2016 | 0.330 → 0.337 | −0.003 → +0.000 | 0.975 → 0.974 |
| per_species | 0.389 → 0.389 | +0.063 → +0.055 | 0.966 → 0.966 |

The qualitative statement (recent window best, the others similar) still holds.

**Projections (§3.6, Table 3).** Corrected mean B/B_MSY in 2043 is:

| Window | paper | corrected |
|---|---|---|
| baseline | 0.57 | 0.50 |
| thai_dof | 0.62 | 0.65 |
| per_species | 0.76 | 1.14 |
| post_1987 | 0.89 | 1.44 |
| recent_2016 | 1.27 | 1.46 |
| dsir_group | not in paper | 1.35 |
| dsir_channel | not in paper | 1.02 |

The range and ordering change: post-1987 is now almost as optimistic as the recent
window.

**Biomass trajectories (§3.3, `fig:biomass` caption).**

* Neritic tuna 2023 biomass is about 28 t (full history) against about 195 t
  (post-1987); the text gives about 50 t and 380 t.
* The caption says the window matters "most strongly for NTU, DMF, MPF and SCP". In
  the corrected runs, the ratio of the largest to the smallest 2023 biomass across
  the five paper windows is:

  | Group | Ratio |
  |---|---|
  | CMA | 12.0 |
  | NTU | 9.0 |
  | ANC | 5.9 |
  | MPF | 5.5 |
  | SAR | 5.2 |
  | SCP | 3.3 |
  | DMF | 2.0 |
  | LPF | 1.6 |

  DMF is among the least sensitive groups and Indian mackerel the most. Fig. 4C
  shows NTU and SAR, as in the original package.

**Number of scenarios (abstract, §2.6, §3.3).** The text describes five windows; the
figures show seven (adding `dsir_group` and `dsir_channel`, defined in
`Raw_data/model_all_scenarios/dsir_scenario_definitions.csv`). The Methods do not
describe these two windows yet. All seven full fits have a positive-definite Hessian
and maximum gradient below 1, so "all scenarios converged" still holds. Some
start-year-scan peels did not (floors 1990, 1999, 2000, 2003, 2005, 2008, 2009).

**Methods not yet describing plotted analyses.**

* The hindcast/MASE (TODO U08 says "not yet run") is now available
  (`hindcast_summary.csv`, `scan_hindcast_summary.csv`) and is plotted in Figs 5C
  and 6B.
* The start-year scan (Fig. 6) is not described anywhere in the text.
* The DSI simulation benchmark (TODO U12) is plotted in Fig. 3D but not yet
  described.

**DSI screening (§3.2).**

* "The highest DSIr scores occur for windows that begin around or after the
  late-1980s decline (best start years: demersal 1977, ...)" is internally
  inconsistent: 1977 is before the decline.
* Fig. 3 also shows that windows starting in 1984–1990 score *low* on DSIr in the
  demersal and pelagic groups.
* The anchovy best start of 2017 (DSIr 59.9) is a 2017–2024 window of 8 years. Among
  windows of at least 12 years, which is the rule used for the `dsir_group` scenario,
  the anchovy optimum is 1998 (DSIr 43.9).

**Discussion, "Reassuringly, the DSI/DSIr screening and the RV breakpoint analysis
point to the same period".** Figs 3 and 6 do not support this as written:

* DSIr is low for windows starting at the 1987–1988 break in the demersal and
  pelagic groups.
* The pelagic DSIr optimum (starts 2008–2011) falls in the least stable region of
  the model scan.
* The old Fig. 5 caption, carried into Fig. 6, already states "the screen identifies
  contrast, not reliability".

**Consistent with the data (no change needed).**

* 1987 is the most frequent break year (8 series).
* There are downward RV-CPUE breaks in 1987 for ANC, DMF, LPF, NTU, SAR and SCP.
* BIC corroborates 1987 in 5 of 9 RV series (LPF, NTU, SAR, SCP and the ecosystem
  index), and the F-test finds 1987 in ANC and DMF where BIC picks a later break.
* The per-species start years in §3.3 match `scenario_fit_summary.csv`.
* All 45 breaks survive the Benjamini–Hochberg correction.
