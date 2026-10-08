# images_for_DSI_paper

Figures for the manuscript *When does the history stop helping? Using a Data
Suitability Index and structural-change diagnostics to choose estimation windows
for a multispecies production model in the Gulf of Thailand*. Created 2026-10-08.

## Layout

```
images_for_DSI_paper/
  README.md                 this file
  _common/theme_dsi.R       shared palette, scenario encoding, theme, save_fig()
  Raw_data/                 every input the figure scripts read, copied unchanged
    data_inputs/            model and DSI input data (copy of ../Data, incl. derived/)
    results_dsi/            DSI window scores, components, breakpoints, nulls
    results_production_model/   the July scenario tables (per-fleet catch scaling; superseded)
    model_all_scenarios/    seven windows under the corrected catch scaling (see below)
    model_startyear_scan/   model refitted at every start-year floor 1971-2010
    revision_outputs/       tables from revision_outputs/tables (simulation, FDR, nulls)
  fig01_window_problem/     make_fig01.R, fig01_window_problem.{pdf,png}, caption.md
  fig02_structural_change/  make_fig02.R, ...
  fig03_dsi_screening/      make_fig03.R, ...
  fig04_window_consequences/ make_fig04.R, ...
  fig05_model_diagnostics/  make_fig05.R, ...
```

Each `make_figNN.R` is run from its own folder (`Rscript make_figNN.R`); it reads
only from `../Raw_data` and `../_common/theme_dsi.R` and writes a 190 mm wide
vector PDF and a 300 dpi PNG. Figures use Okabe-Ito hues; scenario identity is
one hue per family (full history grey; breakpoint-derived windows blue;
assessment convention vermilion; DSIr-derived windows green) with shape and
line type inside a family.

## Which model results the figures use

The manuscript's model tables (`Raw_data/results_production_model/`) were produced
in July 2026 with the per-fleet catch scaling that the model's author later
identified as a bug (each fleet's catch divided by its own mean, so the model
removed 1.5 to 2.8 times the observed catch; see
`FAO_meeting/MSPM_new_approach/catch_scale_fixed_best/README.md`). The project's
frozen copy of that July code reproduces the manuscript numbers exactly
(baseline NLL 1328.105, post-1987 NLL 944.335).

On the author's decision of 2026-10-08, Figures 4 and 5 use the **corrected
catch scaling with the manuscript's qC3 configuration** (108 parameters, anchovy
index catchability estimated). These results are in
`Raw_data/model_all_scenarios/` (seven windows: baseline, post_1987, thai_dof,
recent_2016, per_species, dsir_group, dsir_channel; each with the full fit, five
retrospective peels, Mohn's rho, a hindcast of the survey index from the peel fits
under observed effort, and a 20-year status-quo projection) and
`Raw_data/model_startyear_scan/` (the same diagnostics for every global
start-year floor 1971-2010). Scripts:
`../Scripts/production_model/run_all_scenarios_full.R` and
`run_startyear_scan.R`. The Results tables in the manuscript must be regenerated
from these files before submission.

## New analyses produced for the figures

| Script | Output | Used in |
|---|---|---|
| `Scripts/DSI/07_dsi_components_export.R` | `results_dsi/dsi_components_aggregated.csv` (every DSI/DSIr component per window, own effort per group) | Fig. 1C |
| `Scripts/DSI/08_breakyear_null_all_series.R` | `results_dsi/breakyear_null_all_series_{summary,draws}.csv` (no-common-break AR(1) null over all 25 series; the fast search is validated against the published break years) | Fig. 2C |
| `Scripts/production_model/run_all_scenarios_full.R` | `model_all_scenarios/*.csv` | Figs 4, 5A-B |
| `Scripts/production_model/run_startyear_scan.R` | `model_startyear_scan/*.csv` | Fig. 5C |

DSIr-selected windows (`model_all_scenarios/dsir_scenario_definitions.csv`):
`dsir_group` = best DSIr start of each DOF aggregated group applied to its
species (ANC 2001 via its own minimum start; DMF 1977; CMA, LPF, MPF, NTU, SAR,
SCP 2009); `dsir_channel` = best DSIr start in each species' dominant fleet
(ANC 2008, CMA 1997, DMF 1980, LPF 1991, MPF 1991, NTU 1991, SAR 1990, SCP 1995).
Both require at least 12 years to 2023.

## Hindcast definition

From each peel fit (data to 2023 - p, p = 1..5) the fitted model is projected over
the withheld years under the observed effort, with fleet catchability held at its
terminal value and extra catch scaled with effort (as in the paper's projections).
The predicted survey index is q_idx x B. Errors are on the log scale. MASE divides
the model's mean absolute error by that of a no-change forecast (last observed
index value at or before the origin). "One year ahead" pools horizon-1 predictions
from the five origins; "five years ahead" uses all horizons from the 2018 origin.
