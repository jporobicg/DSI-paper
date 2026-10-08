## Figure 1. Why the estimation window matters and what DSI / DSIr measure.
## Inputs (all in ../Raw_data): Thai_main_groups.csv (aggregated commercial
## CPUE and effort), dsi_components_aggregated.csv (every DSI/DSIr component,
## each group scored on its own effort), structural_breakpoints.csv (1987).
## Run from this folder:  Rscript make_fig01.R

source("../_common/theme_dsi.R")
raw  <- read_csv("../Raw_data/data_inputs/Thai_main_groups.csv", show_col_types = FALSE)
comp <- read_csv("../Raw_data/results_dsi/dsi_components_aggregated.csv", show_col_types = FALSE)
brk  <- read_csv("../Raw_data/results_dsi/structural_breakpoints.csv", show_col_types = FALSE)
break_year <- brk %>% filter(series_type == "RV_ecosystem_index", direction == "decrease") %>%
  pull(break_year) %>% min()
last_year <- max(raw$year)
windows <- tibble(window = c("Full history", "Post-break", "Recent"),
                  start = c(min(raw$year[raw$group == "Demersal"]), break_year + 1L, 2016L),
                  scen = c("baseline", "post_1987", "recent_2016"))
windows$label <- sprintf("%s (%d–%d)", windows$window, windows$start, last_year)
windows$window <- factor(windows$window, levels = windows$window)
windows$label2 <- sprintf("%s\n%d\u2013%d", windows$window, windows$start, last_year)

dem <- raw %>% filter(group == "Demersal") %>% arrange(year) %>%
  mutate(effort_m = effort / 1e6,
         period = case_when(year <= break_year ~ "pre", year < 2016 ~ "mid", TRUE ~ "recent"))
period_lab <- c(pre = sprintf("≤ %d", break_year), mid = sprintf("%d–%d", break_year + 1, 2015),
                recent = sprintf("%d–%d", 2016, last_year))

## ---- A: CPUE and effort strips with the three windows ------------------------
ymax <- max(dem$cpue) * 1.05
brack <- windows %>% mutate(y = ymax * c(1.48, 1.30, 1.12), xend = last_year,
                            hj = c(0, 0, 1), nx = c(0.8, 0.8, -0.8), var = "CPUE\n(kg/unit)")
var_levels <- c("CPUE\n(kg/unit)", "Effort\n(10\u2076 units)")
demL <- dem %>% select(year, period, cpue, effort_m) %>%
  pivot_longer(c(cpue, effort_m), names_to = "var", values_to = "value") %>%
  mutate(var = factor(var, levels = c("cpue", "effort_m"), labels = var_levels))
brack$var <- factor(brack$var, levels = var_levels)
blank <- tibble(var = factor(var_levels, levels = var_levels), year = 1971,
                value = c(ymax * 1.62, 0))
pA <- ggplot(demL, aes(year, value)) +
  geom_blank(data = blank) +
  geom_vline(xintercept = break_year + 0.5, colour = col_break, linetype = "22", linewidth = 0.35) +
  geom_line(colour = ink2, linewidth = 0.5) +
  geom_point(aes(colour = period), size = 1.2) +
  geom_segment(data = brack, aes(x = start, xend = xend, y = y, yend = y),
               colour = scen_col[brack$scen], linetype = scen_lty[brack$scen], linewidth = 0.7,
               inherit.aes = FALSE) +
  geom_point(data = brack, aes(x = start, y = y), colour = scen_col[brack$scen], size = 1.6,
             inherit.aes = FALSE) +
  geom_text(data = brack, aes(x = start + nx, y = y, label = label, hjust = hj), colour = ink1,
            size = 2.0, vjust = -0.55, inherit.aes = FALSE) +
  geom_text(data = tibble(var = factor("CPUE\n(kg/unit)", levels = var_levels), year = break_year + 1,
                          value = ymax * 0.98, lab = sprintf("%d break", break_year)),
            aes(label = lab), hjust = 0, size = 2.2, colour = ink2, inherit.aes = TRUE) +
  facet_wrap(~ var, ncol = 1, scales = "free_y", strip.position = "left") +
  scale_colour_manual(values = col_period, labels = period_lab, name = NULL) +
  scale_x_continuous(breaks = seq(1970, 2020, 10), limits = c(1970, last_year + 1)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.02))) +
  coord_cartesian(clip = "off") +
  labs(x = "Year", y = NULL, tag = "A") + theme_dsi() +
  theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 90, face = "plain", size = 7, lineheight = 0.9),
        legend.position = "bottom", legend.key.width = unit(3, "mm"), legend.margin = margin(0, 0, 0, 0),
        panel.spacing.y = unit(1.5, "mm")) +
  guides(colour = guide_legend(override.aes = list(size = 2)))

## ---- B: log(CPUE) against effort inside each window -----------------------
fits <- lapply(seq_len(nrow(windows)), function(k) {
  d <- dem %>% filter(year >= windows$start[k], is.finite(cpue), cpue > 0, is.finite(effort))
  m <- lm(log(cpue) ~ effort_m, data = d)
  s <- summary(m)$coefficients
  tibble(window = windows$window[k], d, fit = fitted(m)) %>%
    mutate(beta = s["effort_m", "Estimate"], p = s["effort_m", "Pr(>|t|)"], n = nrow(d))
}) %>% bind_rows()
ann <- fits %>% group_by(window) %>% summarise(beta = first(beta), p = first(p), n = first(n), .groups = "drop") %>%
  mutate(lab = sprintf("β = %.3f\np %s, n = %d", beta,
                       ifelse(p < 0.001, "< 0.001", sprintf("= %.3f", p)), n))
pB <- ggplot(fits, aes(effort_m, log(cpue))) +
  geom_line(aes(y = fit), colour = ink1, linewidth = 0.5) +
  geom_point(aes(colour = period), size = 1.5, stroke = 0) +
  geom_text(data = ann, aes(x = Inf, y = Inf, label = lab), hjust = 1.05, vjust = 1.3,
            size = 2.0, colour = ink2, lineheight = 0.95, inherit.aes = FALSE) +
  facet_wrap(~ window, nrow = 1, labeller = labeller(window = setNames(windows$label2, windows$window))) +
  scale_colour_manual(values = col_period, labels = period_lab, name = NULL, guide = "none") +
  scale_x_continuous(breaks = seq(10, 40, 10)) +
  labs(x = "Effort (10\u2076 units)", y = "log CPUE", tag = "B") + theme_dsi()

## ---- C: how DSI is built and discounted to DSIr ------------------------------
cw <- comp %>% filter(valid) %>%
  inner_join(windows %>% select(window, start), by = c("start_year" = "start")) %>%
  select(group, window, start_year, w_slope, w_e, w_i, w_n, w_ce, dsi_base, dsi, dsi_r, p_out, P_miss, p_inf, s_stab, s_fit_e)
long <- cw %>% pivot_longer(c(w_slope, w_e, w_i, w_n, w_ce), names_to = "component", values_to = "w") %>%
  mutate(w = 100 * w,
         component = factor(component, levels = c("w_slope", "w_e", "w_i", "w_n", "w_ce"),
                            labels = c("Depletion slope (0.35)", "Effort contrast (0.20)",
                                       "CPUE contrast (0.20)", "Sample size (0.10)",
                                       "Catch–effort coherence (0.10)")),
         window = factor(window, levels = rev(levels(windows$window))),
         group = factor(group, levels = c("Anchovy", "Demersal", "Pelagic")))
marks <- cw %>% mutate(window = factor(window, levels = rev(levels(windows$window))),
                       group = factor(group, levels = c("Anchovy", "Demersal", "Pelagic")))
pC <- ggplot(long) +
  geom_col(aes(x = w, y = as.numeric(window) + 0.17, fill = component), width = 0.34,
           colour = "white", linewidth = 0.3, orientation = "y") +
  geom_col(data = marks, aes(x = dsi_r, y = as.numeric(window) - 0.17), width = 0.26,
           fill = col_dsir, orientation = "y") +
  geom_segment(data = marks, aes(x = dsi, xend = dsi, y = as.numeric(window) - 0.02,
                                 yend = as.numeric(window) + 0.36), colour = ink1, linewidth = 0.8) +
  geom_text(data = marks, aes(x = pmax(dsi_base, dsi_r) + 2, y = as.numeric(window) + 0.17,
                              label = sprintf("DSI %.0f", dsi)), hjust = 0, size = 2.1, colour = ink2) +
  geom_text(data = marks, aes(x = dsi_r + 2, y = as.numeric(window) - 0.17,
                              label = sprintf("DSIr %.0f", dsi_r)), hjust = 0, size = 2.1, colour = ink2) +
  facet_wrap(~ group, nrow = 1, labeller = labeller(group = group_labels)) +
  scale_fill_manual(values = unname(col_comp), name = NULL) +
  scale_x_continuous(limits = c(0, 125), breaks = seq(0, 100, 25), expand = c(0, 0)) +
  scale_y_continuous(breaks = seq_along(levels(long$window)), labels = levels(long$window),
                     limits = c(0.45, length(levels(long$window)) + 0.55), expand = c(0, 0)) +
  labs(x = "Index (0\u2013100)", y = NULL, tag = "C",
       subtitle = "Upper bar: weighted base components; black tick: DSI after the outlier penalty; lower bar: DSIr") +
  theme_dsi() + theme(legend.position = "bottom", panel.grid.major.y = element_blank()) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))

## ---- assemble --------------------------------------------------------------
fig <- (wrap_elements(pA) + pB + plot_layout(widths = c(1, 1.1))) / pC + plot_layout(heights = c(1.2, 1))
save_fig(fig, "fig01_window_problem", width_mm = 190, height_mm = 150)
cat("Figure 1 written.\n")
