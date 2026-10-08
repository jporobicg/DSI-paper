## Figure 3. DSI / DSIr window screening with a simulation-calibrated reference.
## Inputs (../Raw_data): dsi_windows_aggregated.csv (each group scored on its
## own effort series), issue04_dsi_simulation_raw.csv (200 simulated 30-year
## series per type scored with the same engine), candidate_periods.csv,
## thai_dof_and_model_start_years.csv, dsir_scenario_definitions.csv.
## Run from this folder:  Rscript make_fig03.R

source("../_common/theme_dsi.R")
win  <- read_csv("../Raw_data/results_dsi/dsi_windows_aggregated.csv", show_col_types = FALSE) %>%
  filter(valid, is.finite(dsi_r)) %>% rename(group = species)
sim  <- read_csv("../Raw_data/revision_outputs/issue04_dsi_simulation_raw.csv", show_col_types = FALSE)
cand <- read_csv("../Raw_data/results_dsi/candidate_periods.csv", show_col_types = FALSE)
defs <- read_csv("../Raw_data/model_all_scenarios/dsir_scenario_definitions.csv", show_col_types = FALSE)
last_model_year <- 2023L
min_window <- 12L

dof_start <- c(Anchovy = 1996, Demersal = 1971, Pelagic = 2001)   # Thai DOF assessment starts
grp_levels <- c("Anchovy", "Demersal", "Pelagic")
win$group <- factor(win$group, levels = grp_levels)
panel_lab <- c(Anchovy = "A   Anchovy group", Demersal = "B   Demersal group", Pelagic = "C   Pelagic group")

## reference bands from the simulation (interquartile range of DSIr)
band <- sim %>% mutate(class = case_when(type == "stationary" ~ "stationary",
                                        type %in% c("level_shift", "trend") ~ "informative",
                                        TRUE ~ "hyperstable")) %>%
  group_by(class) %>% summarise(lo = quantile(dsi_r, 0.25), hi = quantile(dsi_r, 0.75),
                                med = median(dsi_r), .groups = "drop")
b_stat <- band %>% filter(class == "stationary"); b_inf <- band %>% filter(class == "informative")

## DSIr optimum used by the dsir_group scenario (>= 12-year window to 2023)
opt <- defs %>% distinct(group, dsir_group_start_raw, dsir_group_DSIr) %>%
  rename(start_year = dsir_group_start_raw, dsi_r = dsir_group_DSIr) %>%
  mutate(group = factor(group, levels = grp_levels))

short_from <- last_model_year - min_window + 2L     # starts leaving < 12 years
cand_ticks <- expand_grid(cand %>% filter(start_year > 1971) %>% select(start_year),
                          group = factor(grp_levels, levels = grp_levels))
long <- win %>% select(group, start_year, DSI = dsi, DSIr = dsi_r) %>%
  pivot_longer(c(DSI, DSIr), names_to = "index", values_to = "value")

ann <- tibble(group = factor(c("Demersal", "Pelagic", "Pelagic"), levels = grp_levels),
              x = c(1983.5, 1988.5, 2011.5), y = c(84, 62, 93),
              lab = c("windows starting inside\nthe 1984–1990 transition", "", "short windows:\nDSI high, DSIr collapses"),
              hj = c(1, 0, 1))
dof_df <- tibble(group = factor(names(dof_start), levels = grp_levels), start_year = dof_start) %>%
  left_join(win %>% select(group, start_year, dsi_r), by = c("group", "start_year"))

pABC <- ggplot() +
  annotate("rect", xmin = short_from - 0.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "#f0efec") +
  geom_rect(data = b_inf, aes(xmin = -Inf, xmax = Inf, ymin = lo, ymax = hi), fill = col_dsir, alpha = 0.10) +
  geom_rect(data = b_stat, aes(xmin = -Inf, xmax = Inf, ymin = lo, ymax = hi), fill = "#898781", alpha = 0.25) +
  geom_vline(data = cand_ticks, aes(xintercept = start_year - 0.5), colour = ink3, linewidth = 0.3, linetype = "22") +
  geom_ribbon(data = win, aes(x = start_year, ymin = dsi_r, ymax = dsi), fill = col_dsi, alpha = 0.25) +
  geom_line(data = win, aes(start_year, dsi), colour = col_dsi, linewidth = 0.5) +
  geom_line(data = win, aes(start_year, dsi_r), colour = col_dsir, linewidth = 0.9) +
  geom_point(data = dof_df, aes(start_year, dsi_r), shape = 21, fill = "white", colour = ink1, size = 2.2, stroke = 0.6) +
  geom_point(data = opt, aes(start_year, dsi_r), shape = 23, fill = "#009E73", colour = "white", size = 2.8, stroke = 0.5) +
  geom_text(data = ann %>% filter(lab != ""), aes(x = x, y = y, label = lab, hjust = hj), size = 2.0,
            colour = ink2, lineheight = 0.9) +
  facet_wrap(~ group, ncol = 1, labeller = labeller(group = panel_lab)) +
  scale_x_continuous(breaks = seq(1970, 2015, 5), limits = c(1970.5, 2018)) +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = c(0, 0)) +
  labs(x = "Window start year (every window ends in the last observed year)", y = "Index (0–100)") +
  theme_dsi() + theme(panel.spacing.y = unit(2, "mm"))

## legend-like key as text under the panels
key <- tibble(x = 1, y = 1)
pD <- sim %>% mutate(type = factor(type, levels = c("stationary", "level_shift", "trend", "hyperstable"),
                                   labels = c("Stationary\n(no signal)", "Level\nshift", "Trend", "Hyper-\nstable")),
                     class = case_when(grepl("Stationary", type) ~ "stationary",
                                       grepl("Hyper", type) ~ "hyperstable", TRUE ~ "informative")) %>%
  ggplot(aes(type, dsi_r, fill = class)) +
  geom_boxplot(width = 0.55, outlier.size = 0.5, outlier.alpha = 0.5, linewidth = 0.35, colour = ink2) +
  scale_fill_manual(values = c(stationary = "#c3c2b7", informative = "#86b6ef", hyperstable = "#f4b183"), guide = "none") +
  scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = c(0, 0)) +
  labs(x = "Simulated series type (200 each)", y = "DSIr (0–100)", tag = "D") +
  theme_dsi() + theme(axis.text.x = element_text(size = 6.5, lineheight = 0.9))

fig <- pABC + pD + plot_layout(widths = c(2.3, 1))
## manual key (drawn as caption text)
fig <- fig + plot_annotation(
  caption = paste0("Thin light line: DSI. Thick dark line: DSIr. Shading between them: robustness discount. Grey band: interquartile range of DSIr for\n",
                   "stationary simulated series (D); blue band: for level-shift and trend series. Dashed verticals: candidate starts 1977, 1988, 2001, 2016.\n",
                   "Open circle: Thai DOF assessment start. Green diamond: DSIr optimum used for the DSIr group-window scenario. Grey area: starts leaving fewer than 12 years."),
  theme = theme(plot.caption = element_text(size = 6, colour = ink2, hjust = 0)))
save_fig(fig, "fig03_dsi_screening", width_mm = 190, height_mm = 150)
cat("Figure 3 written.\n")
