## Figure 2. A coherent 1987 shift, shown with the survey gaps and against a null.
## Inputs (../Raw_data): annual_rv_ecosystem_index.csv, structural_breakpoints.csv,
## issue05_11_summary.csv (bootstrap interval of the 1987 shift; AR(1)-null p),
## issue03_rv_missing_years.csv, breakyear_null_all_series_summary.csv and
## _draws.csv (no-common-break AR(1) null over all 25 series, 2000 simulations).
## Run from this folder:  Rscript make_fig02.R

source("../_common/theme_dsi.R")
eco  <- read_csv("../Raw_data/data_inputs/derived/annual_rv_ecosystem_index.csv", show_col_types = FALSE)
bp   <- read_csv("../Raw_data/results_dsi/structural_breakpoints.csv", show_col_types = FALSE)
s511 <- read_csv("../Raw_data/revision_outputs/issue05_11_summary.csv", show_col_types = FALSE)
miss <- read_csv("../Raw_data/revision_outputs/issue03_rv_missing_years.csv", show_col_types = FALSE)$missing_years
nullS <- read_csv("../Raw_data/results_dsi/breakyear_null_all_series_summary.csv", show_col_types = FALSE)
g <- function(q, d = s511) d$value[d$quantity == q]
yr_lim <- c(1970, 2024)

## ---- A: ecosystem index --------------------------------------------------------
eco_full <- tibble(year = 1971:2023) %>% left_join(eco, by = "year")
eco_bp <- bp %>% filter(series_type == "RV_ecosystem_index")
b87 <- eco_bp %>% filter(break_year == 1987); b16 <- eco_bp %>% filter(break_year > 2010)
seg <- tibble(x = c(1971, 1988), xend = c(1987, 2023), y = c(b87$mean_before, b87$mean_after))
gaps <- tibble(xmin = miss - 0.5, xmax = miss + 0.5)
lab_shift <- sprintf("Level shift at 1987: %.2f (bootstrap 95%% interval %.2f to %.2f)\nF-statistic vs AR(1) null: p = %.3f",
                     g("eco_shift_prepost1987"), g("eco_shift_boot_lo"), g("eco_shift_boot_hi"), g("eco_AR1null_p"))
pA <- ggplot(eco_full, aes(year, rv_index)) +
  geom_rect(data = gaps, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), fill = col_gap, inherit.aes = FALSE) +
  geom_hline(yintercept = 0, colour = ink3, linewidth = 0.3) +
  geom_vline(xintercept = 1987.5, colour = col_break, linetype = "22", linewidth = 0.4) +
  geom_vline(xintercept = b16$break_year[1] - 0.5, colour = ink3, linetype = "22", linewidth = 0.35) +
  geom_segment(data = seg, aes(x = x, xend = xend, y = y, yend = y), colour = col_down, linewidth = 0.9, inherit.aes = FALSE) +
  geom_line(colour = ink2, linewidth = 0.45, na.rm = TRUE) +
  geom_point(colour = ink1, size = 1.2, na.rm = TRUE) +
  annotate("text", x = 1992, y = -1.35, label = "no survey", size = 2.1, colour = ink2, hjust = 0) +
  annotate("text", x = 2023, y = 1.58, label = lab_shift, size = 2.1, colour = ink2, hjust = 1, vjust = 1, lineheight = 0.95) +
  annotate("text", x = b16$break_year[1] - 1, y = 0.9, label = sprintf("%d break\n(increase)", b16$break_year[1]),
           size = 2.0, colour = ink2, hjust = 1, lineheight = 0.9) +
  annotate("text", x = 1986.8, y = -1.3, label = "1987 break\n(decrease)", size = 2.0, colour = ink1, hjust = 1, lineheight = 0.9) +
  scale_x_continuous(limits = yr_lim, breaks = seq(1970, 2020, 10), expand = c(0, 0)) +
  scale_y_continuous(limits = c(-1.45, 1.65), breaks = c(-1, 0, 1)) +
  labs(x = NULL, y = "RV ecosystem index\n(standardised log CPUE)", tag = "A") +
  theme_dsi() + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())

## ---- B: break matrix over 25 series ------------------------------------------
sp8 <- c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP")
fl6 <- c("AFN", "APS", "GN", "OBT", "PS", "PT")
rows <- bind_rows(
  tibble(series_type = "RV_cpue", unit = sp8, type = "RV survey CPUE", label = sp8),
  tibble(series_type = "RV_ecosystem_index", unit = "ecosystem", type = "RV survey CPUE", label = "Ecosystem index"),
  tibble(series_type = "effort_by_fleet", unit = fl6, type = "Effort", label = fl6),
  tibble(series_type = "effort_total", unit = "all_fleets", type = "Effort", label = "All fleets"),
  tibble(series_type = "total_catch", unit = sp8, type = "Catch", label = sp8),
  tibble(series_type = "demersal_share", unit = "DMF_share", type = "Composition", label = "DMF share of catch")) %>%
  mutate(row = row_number(), type = factor(type, levels = c("RV survey CPUE", "Effort", "Catch", "Composition")))
tiles <- bp %>% inner_join(rows, by = c("series_type", "unit")) %>%
  mutate(direction = factor(direction, levels = c("decrease", "increase")))
rows_f <- rows %>% mutate(label = factor(label, levels = rev(unique(label))))
tiles$label <- factor(tiles$label, levels = levels(rows_f$label))
pB <- ggplot(tiles, aes(x = break_year, y = label)) +
  geom_rect(data = gaps, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), fill = col_gap, inherit.aes = FALSE) +
  geom_vline(xintercept = 1987.5, colour = col_break, linetype = "22", linewidth = 0.4) +
  geom_tile(aes(fill = direction), width = 0.9, height = 0.78) +
  geom_blank(data = rows_f, aes(x = 1971, y = label)) +
  facet_grid(type ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_fill_manual(values = c(decrease = col_down, increase = col_up), name = "Break direction",
                    labels = c("decrease", "increase")) +
  scale_x_continuous(limits = yr_lim, breaks = seq(1970, 2020, 10), expand = c(0, 0)) +
  labs(x = NULL, y = NULL, tag = "B") +
  theme_dsi() + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
                      strip.placement = "outside", strip.text.y.left = element_text(angle = 0, face = "bold", size = 7, hjust = 1),
                      panel.grid.major.y = element_blank(), panel.spacing.y = unit(1.5, "mm"),
                      axis.text.y = element_text(size = 6.5), legend.position = "right",
                      legend.key.height = unit(3, "mm"), legend.key.width = unit(4, "mm"))

## ---- C: series breaking per year, against the null ----------------------------
counts <- bp %>% count(break_year, name = "n_series")
q95 <- nullS$value[nullS$quantity == "null_q95_max"]; pmax_ <- nullS$value[nullS$quantity == "p_max_ge_obs"]
obs_max <- nullS$value[nullS$quantity == "obs_max_same_year"]; nsim <- nullS$value[nullS$quantity == "n_sims"]
pC <- ggplot(counts, aes(break_year, n_series)) +
  geom_rect(data = gaps, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), fill = col_gap, inherit.aes = FALSE) +
  geom_col(width = 0.8, fill = ink2) +
  geom_hline(yintercept = q95, colour = col_up, linetype = "22", linewidth = 0.5) +
  annotate("text", x = 2023.5, y = q95 + 0.45, hjust = 1, size = 2.1, colour = col_up,
           label = sprintf("95th percentile of the null: no common break, AR(1) series, %d simulations", nsim)) +
  annotate("text", x = 1988.5, y = obs_max - 0.2, hjust = 0, vjust = 1, size = 2.1, colour = ink1,
           label = sprintf("1987: %d of 25 series, p = %.4f", obs_max, pmax_)) +
  scale_x_continuous(limits = yr_lim, breaks = seq(1970, 2020, 10), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq(0, 8, 2), limits = c(0, 8.6), expand = c(0, 0)) +
  labs(x = "Year", y = "Series breaking", tag = "C") + theme_dsi()

fig <- pA / pB / pC + plot_layout(heights = c(1.1, 2.1, 0.75))
save_fig(fig, "fig02_structural_change", width_mm = 190, height_mm = 170)
cat("Figure 2 written.\n")
