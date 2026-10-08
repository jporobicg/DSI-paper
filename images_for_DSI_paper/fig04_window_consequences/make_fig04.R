## Figure 4. The estimation window changes current status, projected status and
## the estimated biomass trajectories.
## Inputs (../Raw_data/model_all_scenarios, corrected-catch-scaling qC3 model):
## scenario_time_series.csv (biomass and B/B_MSY by group, year and window) and
## scenario_projection_terminal.csv (20-year status-quo projection).
## Run from this folder:  Rscript make_fig04.R
## Output: fig04_window_consequences.{pdf,png,svg}

source("../_common/theme_dsi.R")
ts   <- read_csv("../Raw_data/model_all_scenarios/scenario_time_series.csv", show_col_types = FALSE)
proj <- read_csv("../Raw_data/model_all_scenarios/scenario_projection_terminal.csv", show_col_types = FALSE)
sp_levels <- rev(c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP"))
x_min <- 0.05; x_max <- 2.6   # display range of B/B_MSY; values below x_min are drawn at the edge and labelled

scen_scales <- list(
  scale_colour_manual(values = scen_col, labels = scen_labels, breaks = scen_levels, name = NULL, drop = FALSE),
  scale_shape_manual(values = scen_shape, labels = scen_labels, breaks = scen_levels, name = NULL, drop = FALSE),
  scale_linetype_manual(values = scen_lty, labels = scen_labels, breaks = scen_levels, name = NULL, drop = FALSE))

## ---- A, B: B/B_MSY by group in 2023 and in 2043 ---------------------------------
status <- bind_rows(
  ts %>% filter(year == 2023) %>% transmute(scenario, species, value = B_over_B_MSY, panel = "2023"),
  proj %>% transmute(scenario, species, value = B_end_over_B_MSY, panel = "2043")) %>%
  mutate(scenario = factor(scenario, levels = scen_levels),
         species = factor(species, levels = sp_levels, labels = species_labels[sp_levels]),
         off = value < x_min, x = pmax(value, x_min),
         ## small vertical offset per window so coincident estimates stay visible
         y = as.numeric(species) + seq(0.27, -0.27, length.out = length(scen_levels))[as.integer(scenario)])

panel_status <- function(pn, title, tag, show_y) {
  d <- status %>% filter(panel == pn)
  off <- d %>% filter(off)
  p <- ggplot(d, aes(x = x, y = y)) +
    geom_vline(xintercept = 1, colour = ink3, linewidth = 0.4) +
    geom_rect(data = d %>% group_by(species) %>% summarise(lo = min(x), hi = max(x), yc = as.numeric(species[1])),
              aes(xmin = lo, xmax = hi, ymin = yc - 0.36, ymax = yc + 0.36), fill = "#f4f3ef",
              inherit.aes = FALSE) +
    geom_point(data = d %>% filter(!off), aes(colour = scenario, shape = scenario), size = 1.9, stroke = 0.6) +
    geom_point(data = off, aes(colour = scenario), shape = "\u25C0", size = 2.2) +
    geom_text(data = off, aes(label = formatC(value, format = "fg", digits = 2)),
              nudge_x = 0.06, hjust = 0, vjust = 0.4, size = pt(6), colour = ink2, family = base_family) +
    scale_x_log10(limits = c(x_min * 0.92, x_max), breaks = c(0.05, 0.1, 0.25, 0.5, 1, 2),
                  labels = c("0.05", "0.1", "0.25", "0.5", "1", "2"), expand = c(0, 0)) +
    scale_y_continuous(breaks = seq_along(sp_levels), labels = species_labels[sp_levels],
                       expand = expansion(add = 0.45)) +
    scen_scales[1:2] +
    labs(x = expression(italic(B) / italic(B)[MSY] ~ "(log scale)"), y = NULL, title = title, tag = tag) +
    guides(colour = "none", shape = "none") +
    theme_dsi() + theme(panel.grid.major.y = element_blank(),
                        axis.text.y = element_text(colour = ink1, size = 7))
  if (!show_y) p <- p + theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
                              plot.title = element_text(margin = margin(0, 0, 3, 5)))
  p
}
pA <- panel_status("2023", "2023, end of the fit", "A", TRUE)
pB <- panel_status("2043", "2043, after 20 years at status-quo effort", "B", FALSE)

## ---- C: biomass trajectories of the two most window-sensitive groups -------------
focus <- c("NTU", "SAR")
traj <- ts %>% filter(species %in% focus, active > 0) %>%
  mutate(scenario = factor(scenario, levels = scen_levels),
         species = factor(species, levels = focus, labels = species_labels[focus]))
ends <- traj %>% group_by(scenario, species) %>% filter(year == max(year)) %>% ungroup()
pC <- ggplot(traj, aes(year, B, colour = scenario, linetype = scenario, shape = scenario)) +
  geom_line(linewidth = 0.55) +
  geom_point(data = ends, size = 1.9, stroke = 0.6) +
  facet_wrap(~ species, nrow = 1, scales = "free_y") +
  scen_scales +
  scale_x_continuous(breaks = seq(1970, 2020, 10), limits = c(1970, 2025)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
  labs(x = "Year", y = "Estimated biomass (t)", tag = "C") +
  guides(colour = guide_legend(nrow = 2, byrow = TRUE), shape = guide_legend(nrow = 2, byrow = TRUE),
         linetype = guide_legend(nrow = 2, byrow = TRUE)) +
  theme_dsi() + theme(panel.spacing.x = unit(6, "mm"))

fig <- pA + pB + free(pC) + plot_layout(design = "AB\nCC", heights = c(1.1, 1)) &
  theme(legend.position = "bottom", legend.key.width = unit(7, "mm"), legend.text = element_text(size = 7),
        legend.box.margin = margin(1, 0, 0, 0))
save_fig(fig, "fig04_window_consequences", width_mm = 190, height_mm = 132)
cat("Figure 4 written.\n")
