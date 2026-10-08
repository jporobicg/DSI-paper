## Figure 5. Retrospective stability, in-sample fit and hindcast skill by estimation window.
## Inputs (../Raw_data/model_all_scenarios, corrected-catch-scaling qC3 model):
## retro_trajectories.csv, retro_mohn_rho_by_species.csv, scenario_species_estimates.csv
## (MSY of the full fit and of each peel), scenario_fit_summary.csv (start years),
## scenario_skill_common_window.csv (in-sample fit 2016-2023), hindcast_summary.csv.
## Run from this folder:  Rscript make_fig05.R
## Output: fig05_retrospective.{pdf,png,svg}

source("../_common/theme_dsi.R")
A <- "../Raw_data/model_all_scenarios/"
traj  <- read_csv(paste0(A, "retro_trajectories.csv"), show_col_types = FALSE)
rho   <- read_csv(paste0(A, "retro_mohn_rho_by_species.csv"), show_col_types = FALSE)
est   <- read_csv(paste0(A, "scenario_species_estimates.csv"), show_col_types = FALSE)
fit   <- read_csv(paste0(A, "scenario_fit_summary.csv"), show_col_types = FALSE)
skill <- read_csv(paste0(A, "scenario_skill_common_window.csv"), show_col_types = FALSE)
hc    <- read_csv(paste0(A, "hindcast_summary.csv"), show_col_types = FALSE)
sp8 <- c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP")

## first modelled year of each group in each window (years before it carry no estimate)
starts <- fit %>% filter(peel == 0) %>% select(scenario, start_years) %>%
  separate_rows(start_years, sep = " ") %>%
  separate(start_years, into = c("species", "start"), sep = ":", convert = TRUE)

## ---- A: retrospective trajectories, two windows x two groups ---------------------
focus <- c("NTU", "SAR"); scn2 <- c("baseline", "post_1987")
tr <- traj %>% filter(species %in% focus, scenario %in% scn2) %>%
  inner_join(starts, by = c("scenario", "species")) %>% filter(year >= start) %>%
  mutate(panel = factor(paste0(species_labels[species], ", ", tolower(scen_short[scenario])),
                        levels = paste0(rep(species_labels[focus], each = 2), ", ",
                                        tolower(scen_short[scn2]))))
tr_term <- tr %>% filter(peel > 0, year == cutoff)
keyA <- tibble(panel = factor(levels(tr$panel)[1], levels = levels(tr$panel)),
               x = c(1985, 1979), y = c(300, 12), lab = c("peels", "all data"),
               col = c("#3d74b8", ink1))
pA <- ggplot() +
  geom_line(data = tr %>% filter(peel > 0), aes(year, B, group = peel), colour = col_dsi, linewidth = 0.45) +
  geom_line(data = tr %>% filter(peel == 0), aes(year, B), colour = ink1, linewidth = 0.65) +
  geom_point(data = tr_term, aes(year, B), colour = col_dsir, size = 0.9) +
  geom_text(data = keyA, aes(x, y, label = lab, colour = col), hjust = 0, size = pt(6.5),
            family = base_family) +
  scale_colour_identity() +
  facet_wrap(~ panel, nrow = 1, scales = "free_y") +
  scale_x_continuous(breaks = seq(1970, 2020, 10), labels = c("1970", "", "1990", "", "2010", ""),
                     limits = c(1970, 2024)) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.06))) +
  labs(x = "Year", y = "Biomass (t)", tag = "A") + theme_dsi() +
  theme(strip.text = element_text(size = 7), panel.spacing.x = unit(4, "mm"))

## ---- B: Mohn's rho by group and window ------------------------------------------
row_levels <- rev(scen_levels)
row_lab <- scen_labels[row_levels]
cells <- rho %>% select(scenario, species, mohn_rho) %>%
  mutate(y = match(scenario, row_levels), x = match(species, sp8),
         fill_val = pmax(pmin(mohn_rho, 1), -1),
         lab = sub("-", "\u2212", sprintf("%.2f", mohn_rho)),
         txt = ifelse(abs(fill_val) > 0.6, "white", ink1))
keys <- tibble(scenario = row_levels, y = seq_along(row_levels))
y_rows <- scale_y_continuous(breaks = seq_along(row_levels), labels = row_lab,
                             limits = c(0.5, length(row_levels) + 0.5), expand = c(0, 0))
pB <- ggplot(cells) +
  geom_tile(aes(x, y, fill = fill_val), colour = "white", linewidth = 0.6) +
  geom_text(aes(x, y, label = lab, colour = txt), size = pt(6.2), family = base_family) +
  geom_point(data = keys, aes(x = -0.05, y = y, shape = scenario), colour = scen_col[keys$scenario],
             fill = "white", size = 1.8, stroke = 0.6) +
  scale_colour_identity() +
  scale_shape_manual(values = scen_shape, guide = "none") +
  scale_fill_gradient2(low = col_down, mid = "#f4f3ef", high = col_up, midpoint = 0, limits = c(-1, 1),
                       breaks = c(-1, -0.5, 0, 0.5, 1), labels = c("\u22121", "", "0", "", "\u22651"),
                       name = "Mohn's \u03c1") +
  scale_x_continuous(breaks = 1:8, labels = sp8, position = "top", expand = c(0, 0),
                     limits = c(-0.45, 8.5)) +
  y_rows + coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL, tag = "B") + theme_dsi() +
  theme(panel.grid = element_blank(), axis.ticks = element_blank(),
        axis.text.y = element_text(colour = ink1, size = 7, margin = margin(0, 0, 0, 0)),
        axis.text.x.top = element_text(colour = ink1, size = 7),
        legend.position = "bottom", legend.title = element_text(size = 7, vjust = 0.8),
        legend.key.width = unit(7, "mm"), legend.key.height = unit(2.2, "mm"),
        legend.margin = margin(0, 0, 0, 0))

## ---- C: summaries by window: retrospective drift, fit and hindcast skill ----------
rho_msy <- est %>% select(scenario, species, peel, MSY) %>% group_by(scenario, species) %>%
  summarise(r = mean((MSY[peel > 0] - MSY[peel == 0]) / MSY[peel == 0]), .groups = "drop") %>%
  group_by(scenario) %>% summarise(value = mean(abs(r)), .groups = "drop")
metric_levels <- c("mean |\u03c1|\nbiomass", "mean |\u03c1|\nMSY", "log RMSE\n2016\u20132023",
                   "hindcast\nMASE, 1 yr")
summ <- bind_rows(
  rho %>% group_by(scenario) %>% summarise(value = mean(abs(mohn_rho)), .groups = "drop") %>%
    mutate(metric = metric_levels[1], kind = "bar"),
  rho_msy %>% mutate(metric = metric_levels[2], kind = "bar"),
  skill %>% transmute(scenario, value = cpue_logRMSE, metric = metric_levels[3], kind = "dot"),
  hc %>% filter(design == "one_step") %>% transmute(scenario, value = mase, metric = metric_levels[4], kind = "dot")) %>%
  mutate(y = match(scenario, row_levels), metric = factor(metric, levels = metric_levels),
         lab = ifelse(metric == metric_levels[3], sprintf("%.3f", value), sprintf("%.2f", value)))
## per-metric x ranges: bars from 0, dots on a zoomed range
lims <- tibble(metric = factor(metric_levels, levels = metric_levels),
               lo = c(0, 0, 0.3, 0.6), hi = c(0.62, 0.62, 0.45, 0.85), y = 1)
pC <- ggplot(summ) +
  geom_blank(data = lims, aes(x = lo, y = y)) + geom_blank(data = lims, aes(x = hi, y = y)) +
  geom_col(data = summ %>% filter(kind == "bar"), aes(x = value, y = y), orientation = "y",
           width = 0.62, fill = "#9a9994") +
  geom_segment(data = summ %>% filter(kind == "dot"), aes(x = -Inf, xend = value, y = y, yend = y),
               colour = grid_col, linewidth = 0.4) +
  geom_point(data = summ %>% filter(kind == "dot"), aes(x = value, y = y), colour = ink1, size = 1.5) +
  geom_text(aes(x = value, y = y, label = lab), hjust = -0.25, size = pt(6.2), colour = ink2,
            family = base_family) +
  facet_grid(. ~ metric, scales = "free_x") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.02)),
                     breaks = function(l) if (l[1] < 0.1) c(0, 0.25, 0.5)
                                          else if (l[1] < 0.5) c(0.3, 0.4) else c(0.6, 0.7, 0.8),
                     labels = function(b) sub("\\.?0+$", "", formatC(b, format = "f", digits = 2))) +
  y_rows + coord_cartesian(clip = "off") +
  labs(x = NULL, y = NULL, tag = "C") + theme_dsi() +
  theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank(),
        strip.text = element_text(face = "plain", size = 7, hjust = 0.5, lineheight = 0.9),
        axis.text.x = element_text(size = 6.5), panel.spacing.x = unit(5, "mm"),
        strip.placement = "outside")

bottom <- pB + pC + plot_layout(widths = c(1.15, 1))
fig <- free(pA) / bottom + plot_layout(heights = c(0.85, 1))
save_fig(fig, "fig05_retrospective", width_mm = 190, height_mm = 120)
cat("Figure 5 written.\n")
