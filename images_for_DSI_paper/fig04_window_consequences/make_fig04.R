## Figure 4. The estimation window changes status, reference points and projections.
## Inputs (../Raw_data/model_all_scenarios): scenario_time_series.csv (biomass
## and B/B_MSY by group, year and window), scenario_projection_terminal.csv
## (20-year status-quo projection), all from the corrected-scaling qC3 model.
## Run from this folder:  Rscript make_fig04.R

source("../_common/theme_dsi.R")
ts   <- read_csv("../Raw_data/model_all_scenarios/scenario_time_series.csv", show_col_types = FALSE)
proj <- read_csv("../Raw_data/model_all_scenarios/scenario_projection_terminal.csv", show_col_types = FALSE)
sp_levels <- rev(c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP"))

term <- ts %>% filter(year == 2023) %>% select(scenario, species, value = B_over_B_MSY) %>%
  mutate(panel = "A   2023, terminal year of the fit")
end  <- proj %>% select(scenario, species, value = B_end_over_B_MSY) %>%
  mutate(panel = "B   2043, after 20 years of status-quo effort")
dots <- bind_rows(term, end) %>%
  mutate(scenario = factor(scenario, levels = scen_levels),
         species = factor(species, levels = sp_levels, labels = species_labels[sp_levels]),
         panel = factor(panel, levels = unique(panel)))

pAB <- ggplot(dots, aes(x = value, y = species)) +
  geom_vline(xintercept = 1, colour = ink3, linewidth = 0.4) +
  geom_line(aes(group = species), colour = grid_col, linewidth = 0.6) +
  geom_point(aes(colour = scenario, shape = scenario), size = 2.1, stroke = 0.7) +
  facet_wrap(~ panel, nrow = 1) +
  scale_x_log10(breaks = c(0.1, 0.25, 0.5, 1, 2, 4), labels = c("0.1", "0.25", "0.5", "1", "2", "4")) +
  scale_colour_manual(values = scen_col, labels = scen_labels, name = "Estimation window", drop = FALSE) +
  scale_shape_manual(values = scen_shape, labels = scen_labels, name = "Estimation window", drop = FALSE) +
  labs(x = expression(B / B[MSY]~"(log scale)"), y = NULL) +
  theme_dsi() + theme(panel.grid.major.y = element_blank(), legend.position = "none")

## C. biomass trajectories for the two most window-sensitive groups
focus <- c("NTU", "SAR")
traj <- ts %>% filter(species %in% focus, active > 0) %>%
  mutate(scenario = factor(scenario, levels = scen_levels),
         species = factor(species, levels = focus, labels = species_labels[focus]))
ends <- traj %>% group_by(scenario, species) %>% filter(year == max(year)) %>% ungroup()
pC <- ggplot(traj, aes(year, B, colour = scenario, linetype = scenario)) +
  geom_line(linewidth = 0.6) +
  geom_point(data = ends, aes(shape = scenario), size = 2, stroke = 0.7) +
  facet_wrap(~ species, nrow = 1, scales = "free_y") +
  scale_colour_manual(values = scen_col, labels = scen_labels, name = "Estimation window", drop = FALSE) +
  scale_linetype_manual(values = scen_lty, labels = scen_labels, name = "Estimation window", drop = FALSE) +
  scale_shape_manual(values = scen_shape, labels = scen_labels, name = "Estimation window", drop = FALSE) +
  scale_x_continuous(breaks = seq(1970, 2020, 10), limits = c(1970, 2025)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
  labs(x = "Year", y = "Estimated biomass (t)", tag = "C") +
  theme_dsi() + theme(legend.position = "bottom") +
  guides(colour = guide_legend(nrow = 3, byrow = TRUE, title.position = "top"),
         linetype = guide_legend(nrow = 3, byrow = TRUE, title.position = "top"),
         shape = guide_legend(nrow = 3, byrow = TRUE, title.position = "top"))

fig <- pAB / pC + plot_layout(heights = c(1.25, 1))
save_fig(fig, "fig04_window_consequences", width_mm = 190, height_mm = 150)
cat("Figure 4 written.\n")
