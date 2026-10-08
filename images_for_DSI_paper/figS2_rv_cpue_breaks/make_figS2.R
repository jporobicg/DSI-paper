## Figure S2. Research-vessel survey CPUE by functional group with the detected breakpoints.
## Inputs (../Raw_data): data_inputs/derived/annual_rv_cpue_by_species.csv,
## results_dsi/structural_breakpoints.csv, revision_outputs/issue03_rv_missing_years.csv.
## Run from this folder:  Rscript make_figS2.R
## Output: figS2_rv_cpue_breaks.{pdf,png,svg}

source("../_common/theme_dsi.R")
rv   <- read_csv("../Raw_data/data_inputs/derived/annual_rv_cpue_by_species.csv", show_col_types = FALSE)
bp   <- read_csv("../Raw_data/results_dsi/structural_breakpoints.csv", show_col_types = FALSE) %>%
  filter(series_type == "RV_cpue") %>% rename(species = unit)
miss <- read_csv("../Raw_data/revision_outputs/issue03_rv_missing_years.csv", show_col_types = FALSE)$missing_years
sp8 <- c("ANC", "CMA", "DMF", "LPF", "MPF", "NTU", "SAR", "SCP")
lab8 <- setNames(species_labels[sp8], sp8)

gaps <- tibble(y = sort(miss)) %>% mutate(run = cumsum(c(1, diff(y) != 1))) %>%
  group_by(run) %>% summarise(xmin = min(y) - 0.5, xmax = max(y) + 0.5, .groups = "drop")
## break year marks the last year of the earlier segment; the line is drawn between years
rv_full <- expand_grid(species = sp8, year = 1971:2023) %>% left_join(rv, by = c("species", "year")) %>%
  mutate(species = factor(species, levels = sp8))
bp <- bp %>% mutate(species = factor(species, levels = sp8),
                    direction = factor(direction, levels = c("decrease", "increase")))

## ymin = 0 maps to -Inf on the log axis, so the gap bands span the full panel height
p <- ggplot(rv_full, aes(year, rv_cpue)) +
  geom_rect(data = gaps, aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = Inf), fill = col_gap,
            inherit.aes = FALSE) +
  geom_vline(data = bp, aes(xintercept = break_year + 0.5, colour = direction), linetype = "22",
             linewidth = 0.45) +
  geom_line(colour = ink3, linewidth = 0.35, na.rm = TRUE) +
  geom_point(colour = ink1, size = 0.7, na.rm = TRUE) +
  facet_wrap(~ species, ncol = 4, scales = "free_y", labeller = labeller(species = lab8)) +
  scale_colour_manual(values = c(decrease = col_down, increase = col_up),
                      labels = c("Downward break", "Upward break"), name = NULL, drop = FALSE) +
  scale_x_continuous(breaks = seq(1970, 2020, 10), labels = c("1970", "", "1990", "", "2010", ""),
                     limits = c(1970, 2024), expand = c(0, 0)) +
  scale_y_log10(labels = function(x) format(x, drop0trailing = TRUE, scientific = FALSE, trim = TRUE)) +
  labs(x = "Year", y = "RV survey CPUE (log scale)") + theme_dsi() +
  theme(legend.position = "top", legend.key.width = unit(5, "mm"), panel.spacing.x = unit(3, "mm"),
        strip.text = element_text(size = 7.5))
save_fig(p, "figS2_rv_cpue_breaks", width_mm = 190, height_mm = 95)
cat("Figure S2 written.\n")
