## Figure 6. Refitting the model at every start-year floor, compared with the DSIr screen.
## Inputs (../Raw_data): model_startyear_scan/{scan_mohn_rho, scan_species_estimates,
## scan_hindcast_summary, scan_fit_summary}.csv (corrected-catch-scaling qC3 model,
## floors 1971-2010, five peels per floor); results_dsi/dsi_windows_aggregated.csv.
## Run from this folder:  Rscript make_fig06.R
## Output: fig06_startyear_scan.{pdf,png,svg}

source("../_common/theme_dsi.R")
S <- "../Raw_data/model_startyear_scan/"
s_rho <- read_csv(paste0(S, "scan_mohn_rho.csv"), show_col_types = FALSE)
s_est <- read_csv(paste0(S, "scan_species_estimates.csv"), show_col_types = FALSE)
s_hc  <- read_csv(paste0(S, "scan_hindcast_summary.csv"), show_col_types = FALSE)
s_fit <- read_csv(paste0(S, "scan_fit_summary.csv"), show_col_types = FALSE)
win   <- read_csv("../Raw_data/results_dsi/dsi_windows_aggregated.csv", show_col_types = FALSE) %>%
  filter(valid, is.finite(dsi_r)) %>% rename(group = species)
cand_years <- c(1977, 1988, 2001)
x_end <- 2010

## ---- series -----------------------------------------------------------------------
rho_b <- s_rho %>% group_by(floor) %>%
  summarise(`Biomass` = mean(abs(mohn_rho)),
            `Biomass excl. NTU` = mean(abs(mohn_rho[species != "NTU"])), .groups = "drop")
rho_m <- s_est %>% select(floor, species, peel, MSY) %>% group_by(floor, species) %>%
  summarise(r = mean((MSY[peel > 0] - MSY[peel == 0]) / MSY[peel == 0]), .groups = "drop") %>%
  group_by(floor) %>% summarise(MSY = mean(abs(r)), .groups = "drop")
c1 <- rho_b %>% left_join(rho_m, by = "floor") %>%
  pivot_longer(-floor, names_to = "series", values_to = "value")
c2 <- s_hc %>% transmute(floor, value = mase,
                         series = ifelse(design == "one_step", "1 year ahead", "5 years ahead"))
c3 <- win %>% filter(start_year <= x_end) %>%
  transmute(floor = start_year, value = dsi_r, series = group)
bad <- s_fit %>% filter(!pdHess | max_gradient > 1) %>% distinct(floor)

col1 <- c(`Biomass` = ink1, `Biomass excl. NTU` = ink3, MSY = col_dsir)
col2 <- c(`1 year ahead` = col_dsir, `5 years ahead` = ink1)
col3 <- c(Anchovy = "#CC79A7", Demersal = "#E69F00", Pelagic = "#009E73")

## ---- shared pieces ------------------------------------------------------------------
x_sc <- scale_x_continuous(breaks = seq(1970, 2010, 5), expand = c(0, 0))
x_rng <- c(1970.5, x_end + 0.5)
cand_v <- geom_vline(xintercept = cand_years - 0.5, colour = ink3, linewidth = 0.3, linetype = "22")
lab_end <- function(d, cols, nudge = NULL) {
  e <- d %>% group_by(series) %>% filter(floor == max(floor)) %>% ungroup()
  if (!is.null(nudge)) e <- e %>% mutate(value = value + nudge[series])
  geom_text(data = e, aes(x = x_end + 0.9, y = value, label = series), colour = cols[e$series],
            hjust = 0, size = pt(6.5), family = base_family, inherit.aes = FALSE)
}
th <- theme_dsi() + theme(plot.margin = margin(2, 66, 2, 4), legend.position = "none")
no_x <- theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

## ---- A: retrospective stability -----------------------------------------------------
yA <- max(c1$value) * 1.08
p1 <- ggplot(c1, aes(floor, value, colour = series)) + cand_v +
  geom_line(linewidth = 0.55) + geom_point(size = 0.8) +
  geom_point(data = bad, aes(floor, yA), shape = 4, colour = col_up, size = 1.4, stroke = 0.6,
             inherit.aes = FALSE) +
  annotate("text", x = min(bad$floor) - 0.8, y = yA, label = "non-PD Hessian", hjust = 1,
           size = pt(6.5), colour = col_up, family = base_family) +
  lab_end(c1, col1, nudge = c(`Biomass` = -0.035, `Biomass excl. NTU` = 0.04, MSY = 0)) +
  scale_colour_manual(values = col1) +
  x_sc + scale_y_continuous(expand = c(0, 0), breaks = seq(0, 0.8, 0.2)) +
  annotate("text", x = cand_years - 0.5, y = yA * 1.03, label = cand_years, vjust = -0.4,
           size = pt(6.5), colour = ink2, family = base_family) +
  coord_cartesian(xlim = x_rng, ylim = c(0, yA * 1.03), clip = "off") +
  labs(x = NULL, y = "Mean |Mohn's \u03c1|", tag = "A") + th + no_x +
  theme(plot.margin = margin(9, 66, 2, 4))

## ---- B: hindcast skill --------------------------------------------------------------
p2 <- ggplot(c2, aes(floor, value, colour = series)) + cand_v +
  geom_hline(yintercept = 1, colour = ink3, linewidth = 0.3) +
  geom_line(linewidth = 0.55) + geom_point(size = 0.8) +
  lab_end(c2, col2) +
  annotate("text", x = 1971, y = 1.0, label = "no-change forecast", hjust = 0, vjust = -0.5,
           size = pt(6.5), colour = ink2, family = base_family) +
  scale_colour_manual(values = col2) +
  x_sc + scale_y_continuous(breaks = seq(0.6, 1, 0.1), expand = c(0, 0)) +
  coord_cartesian(xlim = x_rng, ylim = c(0.6, 1.08), clip = "off") +
  labs(x = NULL, y = "Hindcast MASE", tag = "B") + th + no_x

## ---- C: DSIr of the aggregated commercial groups ------------------------------------
p3 <- ggplot(c3, aes(floor, value, colour = series)) + cand_v +
  geom_line(linewidth = 0.55) + geom_point(size = 0.8) +
  lab_end(c3 %>% mutate(series = paste(series, "group")), setNames(col3, paste(names(col3), "group"))) +
  scale_colour_manual(values = col3) +
  x_sc + scale_y_continuous(breaks = seq(0, 100, 25), expand = c(0, 0)) +
  coord_cartesian(xlim = x_rng, ylim = c(0, 100), clip = "off") +
  labs(x = "Start-year floor applied to every group (window ends in 2023)", y = "DSIr", tag = "C") + th

fig <- p1 / p2 / p3 + plot_layout(heights = c(1.15, 0.8, 1))
save_fig(fig, "fig06_startyear_scan", width_mm = 190, height_mm = 125)
cat("Figure 6 written.\n")
