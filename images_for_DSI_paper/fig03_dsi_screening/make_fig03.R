## Figure 3. DSI / DSIr window screening with a simulation-calibrated reference.
## Inputs (../Raw_data): results_dsi/dsi_windows_aggregated.csv (each group scored
## on its own effort series), revision_outputs/issue04_dsi_simulation_raw.csv
## (200 simulated 30-year series per type scored with the same engine),
## results_dsi/candidate_periods.csv, model_all_scenarios/dsir_scenario_definitions.csv.
## Run from this folder:  Rscript make_fig03.R
## Output: fig03_dsi_screening.{pdf,png,svg}

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

## stationary (no-signal) reference: interquartile range of simulated DSIr
b_stat <- sim %>% filter(type == "stationary") %>%
  summarise(lo = quantile(dsi_r, 0.25), hi = quantile(dsi_r, 0.75))

## DSIr optimum used by the dsir_group scenario (window of at least 12 years to 2023)
opt <- defs %>% distinct(group, dsir_group_start_raw, dsir_group_DSIr) %>%
  transmute(group, start_year = dsir_group_start_raw, dsi_r = dsir_group_DSIr,
            what = "DSIr optimum (\u2265 12-year window)")
dof <- tibble(group = names(dof_start), start_year = dof_start) %>%
  left_join(win %>% select(group, start_year, dsi_r), by = c("group", "start_year")) %>%
  mutate(what = "Thai DOF assessment start")
marks <- bind_rows(dof, opt) %>%
  mutate(what = factor(what, levels = c("Thai DOF assessment start", "DSIr optimum (\u2265 12-year window)")))

short_from <- last_model_year - min_window + 2L     # starts leaving fewer than 12 years
cand_years <- cand %>% filter(start_year > 1971) %>% pull(start_year)
x_sc <- function(top = FALSE)
  scale_x_continuous(breaks = seq(1970, 2015, 5), limits = c(1970.5, 2018), expand = c(0, 0),
                     sec.axis = if (top) dup_axis(breaks = cand_years - 0.5, labels = cand_years, name = NULL)
                                else waiver())
y_sc <- scale_y_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = c(0, 0))

panel_dsi <- function(g, tag, top = FALSE, bottom = FALSE, ylab = NULL) {
  w <- win %>% filter(group == g)
  m <- marks %>% filter(group == g)
  p <- ggplot() +
    annotate("rect", xmin = short_from - 0.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "#f1f0ec") +
    annotate("rect", xmin = -Inf, xmax = Inf, ymin = b_stat$lo, ymax = b_stat$hi, fill = col_null, alpha = 0.55) +
    geom_vline(xintercept = cand_years - 0.5, colour = ink3, linewidth = 0.3, linetype = "22") +
    geom_ribbon(data = w, aes(x = start_year, ymin = dsi_r, ymax = dsi), fill = col_dsi, alpha = 0.28) +
    geom_line(data = w, aes(start_year, dsi), colour = col_dsi, linewidth = 0.5) +
    geom_line(data = w, aes(start_year, dsi_r), colour = col_dsir, linewidth = 0.85) +
    geom_point(data = m, aes(start_year, dsi_r, shape = what, fill = what), colour = ink1,
               size = 2.1, stroke = 0.5) +
    scale_shape_manual(values = c(21, 23), name = NULL, drop = FALSE) +
    scale_fill_manual(values = c("white", "#009E73"), name = NULL, drop = FALSE) +
    x_sc(top) + scale_y_continuous(breaks = seq(0, 100, 25), expand = c(0, 0)) +
    coord_cartesian(ylim = c(0, 100), clip = "off") +
    labs(x = if (bottom) "Window start year (window ends in the last observed year)" else NULL,
         y = ylab, title = group_labels[[g]], tag = tag) +
    theme_dsi() + theme(plot.title = element_text(margin = margin(0, 0, 2, 0)))
  if (!bottom) p <- p + theme(axis.text.x = element_blank())
  if (top) {
    p <- p +
      theme(axis.text.x.top = element_text(size = 6.5, colour = ink2, margin = margin(0, 0, 1, 0)),
            axis.ticks.x.top = element_blank()) +
      annotate("text", x = 1991, y = 72, label = "DSI", hjust = 0.5, size = pt(7),
               colour = "#3d74b8", family = base_family, fontface = "bold") +
      annotate("text", x = 1991, y = 30, label = "DSIr", hjust = 0.5, size = pt(7),
               colour = col_dsir, family = base_family, fontface = "bold") +
      annotate("text", x = 2000, y = b_stat$hi + 1.5, label = "no-signal range (D)", vjust = 0,
               size = pt(6.5), colour = ink2, family = base_family)
  }
  if (bottom) {
    p <- p + annotate("text", x = (short_from - 0.5 + 2018) / 2, y = 96, vjust = 1,
                      label = "< 12\nyears", size = pt(6.5), colour = ink2, lineheight = 0.9,
                      family = base_family)
  }
  p
}
pA <- panel_dsi("Anchovy", "A", top = TRUE)
pB <- panel_dsi("Demersal", "B", ylab = "Index score (0\u2013100)")
pC <- panel_dsi("Pelagic", "C", bottom = TRUE)

pD <- sim %>%
  mutate(type = factor(type, levels = c("stationary", "level_shift", "trend", "hyperstable"),
                       labels = c("No\nsignal", "Level\nshift", "Trend", "Hyper-\nstable")),
         class = case_when(type == "No\nsignal" ~ "stationary",
                           type == "Hyper-\nstable" ~ "hyperstable", TRUE ~ "informative")) %>%
  ggplot(aes(type, dsi_r, fill = class)) +
  geom_boxplot(width = 0.55, outlier.size = 0.45, outlier.alpha = 0.5, linewidth = 0.3, colour = ink2) +
  scale_fill_manual(values = c(stationary = col_null, informative = col_dsi, hyperstable = "#f4b183"),
                    guide = "none") +
  y_sc + labs(x = "Simulated series (200 each)", y = "DSIr (0\u2013100)", tag = "D") +
  theme_dsi() + theme(axis.text.x = element_text(size = 7, lineheight = 0.9, colour = ink1),
                      panel.grid.major.x = element_blank())

fig <- pA + pB + pC + pD +
  plot_layout(design = "AD\nBD\nCD", widths = c(2.35, 1), guides = "collect") &
  theme(legend.position = "bottom", legend.key.width = unit(3, "mm"),
        legend.text = element_text(size = 7), legend.box.margin = margin(0, 0, 0, 0))
save_fig(fig, "fig03_dsi_screening", width_mm = 190, height_mm = 132)
cat("Figure 3 written.\n")
