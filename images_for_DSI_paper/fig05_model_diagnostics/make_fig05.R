## Figure 5. Model-based diagnostics by estimation window, and their
## correspondence with the DSIr screen.
## Inputs (../Raw_data): model_all_scenarios/{retro_trajectories, retro_mohn_rho_by_species,
## scenario_species_estimates, hindcast_summary}.csv; model_startyear_scan/{scan_mohn_rho,
## scan_species_estimates, scan_hindcast_summary, scan_fit_summary}.csv;
## results_dsi/dsi_windows_aggregated.csv. All model results from the corrected-scaling qC3 model.
## Run from this folder:  Rscript make_fig05.R

source("../_common/theme_dsi.R")
A <- "../Raw_data/model_all_scenarios/"; S <- "../Raw_data/model_startyear_scan/"
traj <- read_csv(paste0(A, "retro_trajectories.csv"), show_col_types = FALSE)
rho  <- read_csv(paste0(A, "retro_mohn_rho_by_species.csv"), show_col_types = FALSE)
est  <- read_csv(paste0(A, "scenario_species_estimates.csv"), show_col_types = FALSE)
hcA  <- read_csv(paste0(A, "hindcast_summary.csv"), show_col_types = FALSE)
s_rho <- read_csv(paste0(S, "scan_mohn_rho.csv"), show_col_types = FALSE)
s_est <- read_csv(paste0(S, "scan_species_estimates.csv"), show_col_types = FALSE)
s_hc  <- read_csv(paste0(S, "scan_hindcast_summary.csv"), show_col_types = FALSE)
s_fit <- read_csv(paste0(S, "scan_fit_summary.csv"), show_col_types = FALSE)
win   <- read_csv("../Raw_data/results_dsi/dsi_windows_aggregated.csv", show_col_types = FALSE) %>%
  filter(valid, is.finite(dsi_r)) %>% rename(group = species)
sp8 <- c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP")

## ---- A: retrospective trajectories, two windows x two groups -------------------
focus <- c("NTU", "SAR"); scn2 <- c("baseline", "post_1987")
tr <- traj %>% filter(species %in% focus, scenario %in% scn2) %>%
  mutate(scenario = factor(scenario, levels = scn2, labels = scen_labels[scn2]),
         species = factor(species, levels = focus, labels = species_labels[focus]))
tr_term <- tr %>% filter(peel > 0, year == cutoff)
short_lab <- c(baseline = "full history", post_1987 = "post-1987")
tr <- tr %>% mutate(scn_short = short_lab[as.character(factor(scenario, levels = scen_labels[scn2], labels = scn2))],
                    panel = factor(paste0(species, "\n", scn_short),
                                   levels = c(paste0(species_labels[focus][1], "\n", short_lab[scn2]),
                                              paste0(species_labels[focus][2], "\n", short_lab[scn2]))))
tr_term <- tr %>% filter(peel > 0, year == cutoff)
pA <- ggplot() +
  geom_line(data = tr %>% filter(peel > 0), aes(year, B, group = peel), colour = col_dsi, linewidth = 0.45) +
  geom_line(data = tr %>% filter(peel == 0), aes(year, B), colour = ink1, linewidth = 0.7) +
  geom_point(data = tr_term, aes(year, B), colour = col_dsir, size = 1.3) +
  facet_wrap(~ panel, nrow = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(1980, 2020, 20)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(x = "Year", y = "Biomass (t)", tag = "A") + theme_dsi() +
  theme(strip.text = element_text(size = 7, lineheight = 0.9), axis.text.x = element_text(size = 6))

## ---- B: Mohn's rho matrix with margins -------------------------------------------
## rho on MSY from the peel species tables
rho_msy <- est %>% select(scenario, species, peel, MSY) %>%
  group_by(scenario, species) %>%
  summarise(rho_msy = mean((MSY[peel > 0] - MSY[peel == 0]) / MSY[peel == 0]), .groups = "drop")
marg <- rho %>% left_join(rho_msy, by = c("scenario", "species")) %>% group_by(scenario) %>%
  summarise(`biomass` = mean(abs(mohn_rho)),
            `biomass\nexcl. NTU` = mean(abs(mohn_rho[species != "NTU"])),
            `MSY` = mean(abs(rho_msy)), .groups = "drop") %>%
  pivot_longer(-scenario, names_to = "species", values_to = "mohn_rho") %>% mutate(block = "summary")
cells <- rho %>% select(scenario, species, mohn_rho) %>% mutate(block = "group") %>% bind_rows(marg) %>%
  mutate(scenario = factor(scenario, levels = rev(scen_levels), labels = rev(scen_labels[scen_levels])),
         species = factor(species, levels = c(sp8, "biomass", "biomass\nexcl. NTU", "MSY")),
         block = factor(block, levels = c("group", "summary"), labels = c("Mohn's \u03c1 by functional group", "mean |\u03c1| over groups")),
         fill_val = pmax(pmin(mohn_rho, 1), -1),
         lab = ifelse(abs(mohn_rho) >= 10, sprintf("%.0f", mohn_rho), sprintf("%.2f", mohn_rho)))
pB <- ggplot(cells, aes(species, scenario)) +
  geom_tile(aes(fill = fill_val), colour = "white", linewidth = 0.6) +
  geom_text(aes(label = lab), size = 1.9, colour = ink1) +
  facet_grid(. ~ block, scales = "free_x", space = "free_x") +
  scale_fill_gradient2(low = col_down, mid = "#f0efec", high = col_up, midpoint = 0, limits = c(-1, 1),
                       name = "Mohn's ρ (clipped at ±1)") +
  labs(x = NULL, y = NULL, tag = "B") +
  theme_dsi() + theme(panel.grid = element_blank(), strip.text = element_text(size = 7, face = "plain", colour = ink2),
                      axis.text.x = element_text(size = 6, lineheight = 0.85), axis.text.y = element_text(size = 7),
                      legend.position = "right", legend.key.height = unit(5, "mm"), legend.key.width = unit(3, "mm"))

## ---- C: start-year scan, stacked panels on one x axis -----------------------------
rho_b <- s_rho %>% group_by(floor) %>%
  summarise(`biomass, all groups` = mean(abs(mohn_rho)), `biomass, excl. NTU` = mean(abs(mohn_rho[species != "NTU"])), .groups = "drop")
rho_m <- s_est %>% select(floor, species, peel, MSY) %>% group_by(floor, species) %>%
  summarise(r = mean((MSY[peel > 0] - MSY[peel == 0]) / MSY[peel == 0]), .groups = "drop") %>%
  group_by(floor) %>% summarise(`MSY, all groups` = mean(abs(r)), .groups = "drop")
c1 <- rho_b %>% left_join(rho_m, by = "floor") %>% pivot_longer(-floor, names_to = "series", values_to = "value") %>%
  mutate(panel = "Retrospective: mean |Mohn's ρ| over five peels")
c2 <- s_hc %>% mutate(series = ifelse(design == "one_step", "one year ahead", "five years ahead"),
                      panel = "Hindcast of the survey index: MASE (log scale, < 1 beats a no-change forecast)") %>%
  select(floor, series, value = mase, panel)
c3 <- win %>% filter(start_year <= 2010) %>% select(floor = start_year, series = group, value = dsi_r) %>%
  mutate(series = paste0("DSIr, ", tolower(series), " group"), panel = "DSIr of the aggregated groups (Fig. 3)")
bad <- s_fit %>% filter(!pdHess | max_gradient > 1) %>% distinct(floor) %>% mutate(value = 0)
cand_v <- geom_vline(xintercept = c(1977, 1988, 2001) - 0.5, colour = ink3, linewidth = 0.3, linetype = "22")
x_sc <- scale_x_continuous(breaks = seq(1970, 2010, 5), limits = c(1970.5, 2010.5), expand = c(0, 0))
th_c <- theme_dsi() + theme(legend.position = "right", legend.key.width = unit(5, "mm"), legend.key.height = unit(3.5, "mm"),
                            legend.text = element_text(size = 6.5), legend.justification = "top",
                            plot.title = element_text(size = 8, face = "bold"), plot.margin = margin(2, 3, 1, 3))
pC1 <- ggplot(c1, aes(floor, value, colour = series)) + cand_v + geom_line(linewidth = 0.6) + geom_point(size = 0.9) +
  geom_point(data = bad, aes(floor, value), shape = 4, colour = col_up, size = 1.6, stroke = 0.6, inherit.aes = FALSE) +
  scale_colour_manual(values = c(`biomass, all groups` = ink1, `biomass, excl. NTU` = ink3, `MSY, all groups` = col_dsir), name = NULL) +
  x_sc + scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  labs(x = NULL, y = "mean |Mohn's \u03c1|", title = "Retrospective stability over five peels", tag = "C") + th_c +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
pC2 <- ggplot(c2, aes(floor, value, colour = series)) + cand_v + geom_hline(yintercept = 1, colour = ink3, linewidth = 0.3) +
  geom_line(linewidth = 0.6) + geom_point(size = 0.9) +
  scale_colour_manual(values = c(`one year ahead` = col_dsir, `five years ahead` = ink1), name = NULL) +
  x_sc + scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.25), expand = c(0, 0)) +
  labs(x = NULL, y = "MASE", title = "Hindcast of the survey index (MASE < 1 beats a no-change forecast)") + th_c +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
pC3 <- ggplot(c3, aes(floor, value, colour = series)) + cand_v + geom_line(linewidth = 0.6) + geom_point(size = 0.9) +
  scale_colour_manual(values = c(`DSIr, anchovy group` = "#CC79A7", `DSIr, demersal group` = "#E69F00", `DSIr, pelagic group` = "#009E73"), name = NULL) +
  x_sc + scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = c(0, 0)) +
  labs(x = "Global start-year floor applied to every group (window ends in 2023)", y = "DSIr",
       title = "DSIr screen of the aggregated commercial groups (Fig. 3)") + th_c
pC <- pC1 / pC2 / pC3 + plot_layout(heights = c(1.2, 1, 1))

fig <- pA / pB / pC + plot_layout(heights = c(0.9, 1.15, 2.6))
save_fig(fig, "fig05_model_diagnostics", width_mm = 190, height_mm = 235)
cat("Figure 5 written.\n")
