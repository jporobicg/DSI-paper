## Figure 2. A coherent 1987 shift, shown with the survey gaps and against a null.
## Inputs (../Raw_data): data_inputs/derived/annual_rv_ecosystem_index.csv,
## results_dsi/structural_breakpoints.csv, revision_outputs/issue03_rv_missing_years.csv,
## results_dsi/breakyear_null_all_series_summary.csv (no-common-break AR(1) null
## over all 25 series, 2000 simulations).
## Run from this folder:  Rscript make_fig02.R
## Output: fig02_structural_change.{pdf,png,svg}

source("../_common/theme_dsi.R")
eco   <- read_csv("../Raw_data/data_inputs/derived/annual_rv_ecosystem_index.csv", show_col_types = FALSE)
bp    <- read_csv("../Raw_data/results_dsi/structural_breakpoints.csv", show_col_types = FALSE)
miss  <- read_csv("../Raw_data/revision_outputs/issue03_rv_missing_years.csv", show_col_types = FALSE)$missing_years
nullS <- read_csv("../Raw_data/results_dsi/breakyear_null_all_series_summary.csv", show_col_types = FALSE)
yr_lim <- c(1970, 2024)
x_year <- scale_x_continuous(limits = yr_lim, breaks = seq(1970, 2020, 10), expand = c(0, 0))
v87 <- geom_vline(xintercept = 1987.5, colour = col_break, linetype = "22", linewidth = 0.35)
no_x <- theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(), axis.title.x = element_blank())

## contiguous survey gaps as bands
gaps <- tibble(y = sort(miss)) %>% mutate(run = cumsum(c(1, diff(y) != 1))) %>%
  group_by(run) %>% summarise(xmin = min(y) - 0.5, xmax = max(y) + 0.5, .groups = "drop")

## ---- A: ecosystem index --------------------------------------------------------
eco_full <- tibble(year = 1971:2023) %>% left_join(eco, by = "year")
eco_bp <- bp %>% filter(series_type == "RV_ecosystem_index")
b87 <- eco_bp %>% filter(break_year == 1987); b16 <- eco_bp %>% filter(break_year > 2010)
seg <- tibble(x = c(1971, 1988), xend = c(1987, 2023), y = c(b87$mean_before, b87$mean_after))
big_gap <- gaps %>% slice_max(xmax - xmin, n = 1)
ytop <- 1.75
pA <- ggplot(eco_full, aes(year, rv_index)) +
  geom_rect(data = gaps, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), fill = col_gap,
            inherit.aes = FALSE) +
  geom_hline(yintercept = 0, colour = ink3, linewidth = 0.25) +
  v87 +
  geom_vline(xintercept = b16$break_year[1] - 0.5, colour = ink3, linetype = "22", linewidth = 0.3) +
  geom_segment(data = seg, aes(x = x, xend = xend, y = y, yend = y), colour = col_down,
               linewidth = 0.8, inherit.aes = FALSE) +
  geom_line(colour = ink2, linewidth = 0.4, na.rm = TRUE) +
  geom_point(colour = ink1, size = 1.0, na.rm = TRUE) +
  annotate("text", x = 1988, y = ytop, label = "1987", hjust = 0, vjust = 1, size = pt(6.5),
           colour = ink1, family = base_family) +
  annotate("text", x = b16$break_year[1] - 0.2, y = ytop, label = as.character(b16$break_year[1]),
           hjust = 0, vjust = 1, size = pt(6.5), colour = ink2, family = base_family) +
  annotate("text", x = (big_gap$xmin + big_gap$xmax) / 2, y = ytop, label = "no survey",
           vjust = 1, size = pt(6.5), colour = ink2, family = base_family) +
  x_year + scale_y_continuous(limits = c(-1.45, ytop), breaks = c(-1, 0, 1)) +
  labs(y = "RV ecosystem index\n(standardised log CPUE)", tag = "A") +
  theme_dsi() + no_x

## ---- B: break years in 25 series ------------------------------------------------
sp8 <- c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP")
fl6 <- c("AFN", "APS", "GN", "OBT", "PS", "PT")
rows <- bind_rows(
  tibble(series_type = "RV_ecosystem_index", unit = "ecosystem", type = "RV survey CPUE", label = "Ecosystem index"),
  tibble(series_type = "RV_cpue", unit = sp8, type = "RV survey CPUE", label = sp8),
  tibble(series_type = "effort_total", unit = "all_fleets", type = "Effort", label = "All fleets"),
  tibble(series_type = "effort_by_fleet", unit = fl6, type = "Effort", label = fl6),
  tibble(series_type = "total_catch", unit = sp8, type = "Catch", label = sp8),
  tibble(series_type = "demersal_share", unit = "DMF_share", type = "Catch", label = "DMF share")) %>%
  mutate(type = factor(type, levels = c("RV survey CPUE", "Effort", "Catch")),
         key = paste(type, label, sep = "|"))
tiles <- bp %>% inner_join(rows, by = c("series_type", "unit")) %>%
  mutate(direction = factor(direction, levels = c("decrease", "increase")))
stopifnot(nrow(tiles) == nrow(bp))
lab_map <- setNames(rows$label, rows$key)
key_levels <- rev(rows$key)
tiles$key <- factor(tiles$key, levels = key_levels)
rows_f <- rows %>% mutate(key = factor(key, levels = key_levels))
pB <- ggplot(tiles, aes(x = break_year, y = key)) +
  v87 +
  geom_blank(data = rows_f, aes(x = 1971, y = key)) +
  geom_point(aes(shape = direction, fill = direction), size = 1.9, colour = "white", stroke = 0.2) +
  facet_grid(type ~ ., scales = "free_y", space = "free_y", switch = "y") +
  scale_y_discrete(labels = lab_map) +
  scale_shape_manual(values = c(decrease = 25, increase = 24), name = NULL,
                     labels = c("Downward break", "Upward break")) +
  scale_fill_manual(values = c(decrease = col_down, increase = col_up), name = NULL,
                    labels = c("Downward break", "Upward break")) +
  x_year + labs(x = NULL, y = NULL, tag = "B") +
  theme_dsi() + no_x +
  theme(strip.placement = "outside",
        strip.text.y.left = element_text(angle = 90, face = "plain", size = 7, colour = ink1,
                                         hjust = 0.5, margin = margin(0, 2, 0, 0)),
        panel.grid.major.y = element_line(colour = "#f2f1ec", linewidth = 0.2),
        panel.spacing.y = unit(1.6, "mm"), axis.text.y = element_text(size = 6.5),
        legend.position = "inside", legend.position.inside = c(1, 1.005), legend.justification = c(1, 0), legend.direction = "horizontal",
        legend.key.width = unit(3, "mm"), legend.text = element_text(size = 7),
        legend.background = element_rect(fill = "white", colour = NA))

## ---- C: number of series breaking in each year, against the null -----------------
counts <- bp %>% count(break_year, name = "n_series") %>%
  mutate(hi = break_year == 1987)
q95 <- nullS$value[nullS$quantity == "null_q95_max"]
pC <- ggplot(counts, aes(break_year, n_series)) +
  geom_col(aes(fill = hi), width = 0.8) +
  geom_hline(yintercept = q95, colour = col_up, linetype = "22", linewidth = 0.45) +
  annotate("text", x = yr_lim[2] - 0.3, y = q95 + 0.25, hjust = 1, vjust = 0, size = pt(6.5),
           colour = col_up, label = "95% of null maxima", family = base_family) +
  scale_fill_manual(values = c(`TRUE` = ink1, `FALSE` = "#a9a8a2"), guide = "none") +
  x_year + scale_y_continuous(breaks = seq(0, 8, 2), limits = c(0, 8.6), expand = c(0, 0)) +
  labs(x = "Year", y = "Series\nbreaking", tag = "C") + theme_dsi()

fig <- pA / pB / pC + plot_layout(heights = c(1, 2.05, 0.68))
save_fig(fig, "fig02_structural_change", width_mm = 190, height_mm = 142)
cat("Figure 2 written.\n")
