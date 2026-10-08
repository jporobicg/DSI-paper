#!/usr/bin/env bash
# Rebuild every figure of the DSI manuscript. Each script runs from its own folder
# and reads only ../Raw_data and ../_common/theme_dsi.R.
set -euo pipefail
cd "$(dirname "$0")"
for d in fig01_window_problem fig02_structural_change fig03_dsi_screening \
         fig04_window_consequences fig05_retrospective fig06_startyear_scan \
         figS1_dsi_components figS2_rv_cpue_breaks; do
  script=$(ls "$d"/make_*.R)
  echo "== $script"
  (cd "$d" && Rscript "$(basename "$script")")
done
mkdir -p review
for d in fig0*_* figS*_*; do
  n=${d%%_*}
  cp "$d"/*.png "review/${n}_final.png"
done
echo "All figures written; review copies in review/."
