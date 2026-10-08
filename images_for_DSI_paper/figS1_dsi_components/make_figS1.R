## Figure S1. How DSI is built from its weighted components and discounted to DSIr,
## for the three illustrative windows of Figure 1 in each aggregated group.
## Inputs (../Raw_data): results_dsi/dsi_components_aggregated.csv,
## data_inputs/Thai_main_groups.csv, results_dsi/structural_breakpoints.csv.
## Run from this folder:  Rscript make_figS1.R
## Output: figS1_dsi_components.{pdf,png,svg}

source("../_common/theme_dsi.R")
raw  <- read_csv("../Raw_data/data_inputs/Thai_main_groups.csv", show_col_types = FALSE)
comp <- read_csv("../Raw_data/results_dsi/dsi_components_aggregated.csv", show_col_types = FALSE)
brk  <- read_csv("../Raw_data/results_dsi/structural_breakpoints.csv", show_col_types = FALSE)
break_year <- brk %>% filter(series_type == "RV_ecosystem_index", direction == "decrease") %>%
  pull(break_year) %>% min()
recent_start <- 2016L
win_levels <- c("Full history", "Post-1987", "Recent")
first_year <- raw %>% group_by(group) %>% summarise(first = min(year), .groups = "drop")

cw <- comp %>% filter(valid) %>% left_join(first_year, by = "group") %>%
  mutate(window = case_when(start_year == first ~ "Full history",
                            start_year == break_year + 1 ~ "Post-1987",
                            start_year == recent_start ~ "Recent")) %>%
  filter(!is.na(window)) %>%
  mutate(window = factor(window, levels = rev(win_levels)),
         group = factor(group, levels = names(group_labels)))
comp_lab <- c(w_slope = "Depletion slope (0.35)", w_e = "Effort contrast (0.20)",
              w_i = "CPUE contrast (0.20)", w_n = "Sample size (0.10)",
              w_ce = "Catch\u2013effort coherence (0.10)")
long <- cw %>% pivot_longer(all_of(names(comp_lab)), names_to = "component", values_to = "w") %>%
  mutate(w = 100 * w, component = factor(component, levels = names(comp_lab), labels = comp_lab))
marks <- cw %>% select(group, window, dsi, dsi_r) %>%
  pivot_longer(c(dsi, dsi_r), names_to = "index", values_to = "value") %>%
  mutate(index = factor(index, levels = c("dsi", "dsi_r"),
                        labels = c("DSI (after outlier penalty)", "DSIr")))

p <- ggplot(long, aes(y = window)) +
  geom_col(aes(x = w, fill = component), width = 0.55, colour = "white", linewidth = 0.25,
           orientation = "y") +
  geom_segment(data = marks %>% filter(index != "DSIr"),
               aes(x = value, xend = value, y = as.numeric(window) - 0.38, yend = as.numeric(window) + 0.38,
                   colour = index), linewidth = 0.9, key_glyph = "vpath") +
  geom_point(data = marks %>% filter(index == "DSIr"), aes(x = value, shape = index), size = 2.1,
             colour = ink1, fill = "white", stroke = 0.6) +
  facet_wrap(~ group, nrow = 1, labeller = labeller(group = group_labels)) +
  scale_fill_manual(values = unname(col_comp), name = NULL) +
  scale_colour_manual(values = ink1, name = NULL) +
  scale_shape_manual(values = 23, name = NULL) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = expansion(add = c(0, 2))) +
  labs(x = "Index score (0\u2013100)", y = NULL) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE, order = 1),
         colour = guide_legend(order = 2), shape = guide_legend(order = 3)) +
  theme_dsi() +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(colour = ink1, size = 7),
        legend.position = "top", legend.key.width = unit(3.5, "mm"), panel.spacing.x = unit(5, "mm"))
save_fig(p, "figS1_dsi_components", width_mm = 190, height_mm = 68)
cat("Figure S1 written.\n")
