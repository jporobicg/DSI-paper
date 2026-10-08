## Figure 1. Why the estimation window matters and what DSI / DSIr measure.
## Inputs (../Raw_data): data_inputs/Thai_main_groups.csv (aggregated commercial
## CPUE and effort), results_dsi/dsi_components_aggregated.csv (DSI and DSIr per
## window, each group scored on its own effort), results_dsi/structural_breakpoints.csv
## (the 1987 break of the RV ecosystem index).
## Run from this folder:  Rscript make_fig01.R
## Output: fig01_window_problem.{pdf,png,svg}

source("../_common/theme_dsi.R")
raw  <- read_csv("../Raw_data/data_inputs/Thai_main_groups.csv", show_col_types = FALSE)
comp <- read_csv("../Raw_data/results_dsi/dsi_components_aggregated.csv", show_col_types = FALSE)
brk  <- read_csv("../Raw_data/results_dsi/structural_breakpoints.csv", show_col_types = FALSE)

break_year <- brk %>% filter(series_type == "RV_ecosystem_index", direction == "decrease") %>%
  pull(break_year) %>% min()
last_year <- max(raw$year)
recent_start <- 2016L

## The three illustrative windows. Each colour is the colour of the years that
## the window adds, so the window bars in A double as the key for A and B.
windows <- tibble(window = c("Full history", "Post-1987", "Recent"),
                  start  = c(min(raw$year[raw$group == "Demersal"]), break_year + 1L, recent_start),
                  period = c("pre", "mid", "recent"))
windows$label <- sprintf("%s  %d\u2013%d", windows$window, windows$start, last_year)
win_levels <- windows$window

dem <- raw %>% filter(group == "Demersal") %>% arrange(year) %>%
  mutate(effort_m = effort / 1e6,
         period = case_when(year <= break_year ~ "pre", year < recent_start ~ "mid", TRUE ~ "recent"))

x_year <- scale_x_continuous(breaks = seq(1970, 2020, 10), limits = c(1969.5, last_year + 0.5),
                             expand = c(0, 0))
v87 <- geom_vline(xintercept = break_year + 0.5, colour = col_break, linetype = "22", linewidth = 0.3)
no_x <- theme(axis.text.x = element_blank(), axis.title.x = element_blank(),
              axis.ticks.x = element_blank())

## ---- A: the windows, demersal CPUE and effort ------------------------------------
trk <- windows %>% mutate(y = factor(label, levels = rev(label)))
pA1 <- ggplot(trk) +
  v87 +
  geom_segment(aes(x = start - 0.4, xend = last_year + 0.4, y = y, yend = y, colour = period),
               linewidth = 2.6, lineend = "butt") +
  annotate("text", x = break_year + 0.9, y = 3.55, label = as.character(break_year), hjust = 0,
           vjust = 0, size = pt(6.5), colour = ink1, family = base_family) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_y_discrete(expand = expansion(add = c(0.6, 0.9))) +
  x_year + coord_cartesian(clip = "off") +
  labs(y = NULL, tag = "A") + theme_dsi() + no_x +
  theme(panel.grid = element_blank(), axis.text.y = element_text(colour = ink1, size = 7))

pA2 <- ggplot(dem, aes(year, cpue)) + v87 +
  geom_line(colour = ink3, linewidth = 0.35) +
  geom_point(aes(colour = period), size = 1.1) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  x_year + labs(y = "CPUE\n(kg per unit)") + theme_dsi() + no_x

pA3 <- ggplot(dem, aes(year, effort_m)) + v87 +
  geom_line(colour = ink3, linewidth = 0.35) +
  geom_point(aes(colour = period), size = 1.1) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  x_year + labs(x = "Year", y = "Effort\n(10\u2076 units)") + theme_dsi()

pA <- pA1 / pA2 / pA3 + plot_layout(heights = c(0.62, 1, 1))

## ---- B: log(CPUE) against effort inside each window -----------------------------
fits <- lapply(seq_len(nrow(windows)), function(k) {
  d <- dem %>% filter(year >= windows$start[k], is.finite(cpue), cpue > 0, is.finite(effort))
  m <- lm(log(cpue) ~ effort_m, data = d)
  tibble(window = windows$window[k], d, fit = fitted(m), beta = coef(m)[["effort_m"]])
}) %>% bind_rows() %>% mutate(window = factor(window, levels = win_levels))
ann <- fits %>% distinct(window, beta) %>%
  mutate(lab = paste0("\u03b2 = ", sub("-", "\u2212", sprintf("%.3f", beta))))
pB <- ggplot(fits, aes(effort_m, log(cpue))) +
  geom_point(aes(colour = period), size = 1.2, stroke = 0) +
  geom_line(aes(y = fit), colour = ink1, linewidth = 0.5) +
  geom_text(data = ann, aes(x = Inf, y = Inf, label = lab), hjust = 1.08, vjust = 1.4,
            size = pt(6.5), colour = ink2, family = base_family, inherit.aes = FALSE) +
  facet_wrap(~ window, nrow = 1) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_x_continuous(breaks = seq(10, 40, 10)) +
  labs(x = "Effort (10\u2076 units)", y = "log CPUE", tag = "B") + theme_dsi() +
  theme(panel.spacing.x = unit(3, "mm"))

## ---- C: DSI and its robustness-adjusted version DSIr for each window --------------
## "Full history" uses each group's first year (the anchovy series starts in 1972).
first_year <- raw %>% group_by(group) %>% summarise(first = min(year), .groups = "drop")
cw <- comp %>% filter(valid) %>% left_join(first_year, by = "group") %>%
  mutate(window = case_when(start_year == first ~ "Full history",
                            start_year == break_year + 1 ~ "Post-1987",
                            start_year == recent_start ~ "Recent")) %>%
  filter(!is.na(window)) %>%
  mutate(window = factor(window, levels = rev(win_levels)),
         group = factor(group, levels = names(group_labels)))
keyC <- cw %>% filter(group == "Anchovy", window == "Full history") %>%
  select(group, window, dsi, dsi_r)
pC <- ggplot(cw, aes(y = window)) +
  geom_segment(aes(x = dsi_r, xend = dsi, yend = window), colour = col_dsi, linewidth = 1.6,
               alpha = 0.55) +
  geom_point(aes(x = dsi), shape = 21, fill = "white", colour = col_dsi, size = 2.1, stroke = 0.9) +
  geom_point(aes(x = dsi_r), shape = 16, colour = col_dsir, size = 2.1) +
  geom_text(data = keyC, aes(x = dsi, label = "DSI"), vjust = -1.1, size = pt(6.5),
            colour = "#3d74b8", family = base_family) +
  geom_text(data = keyC, aes(x = dsi_r, label = "DSIr"), vjust = -1.1, size = pt(6.5),
            colour = col_dsir, family = base_family) +
  facet_wrap(~ group, nrow = 1, labeller = labeller(group = group_labels)) +
  scale_x_continuous(limits = c(0, 100), breaks = seq(0, 100, 25), expand = expansion(add = 2)) +
  scale_y_discrete(expand = expansion(add = c(0.45, 0.75))) +
  coord_cartesian(clip = "off") +
  labs(x = "Index score (0\u2013100)", y = NULL, tag = "C") + theme_dsi() +
  theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(colour = ink1, size = 7),
        panel.spacing.x = unit(5, "mm"))

## ---- assemble --------------------------------------------------------------------
fig <- (wrap_elements(full = pA) | pB) / pC +
  plot_layout(heights = c(2.1, 1)) &
  theme(plot.tag.position = c(0, 1))
fig[[1]] <- fig[[1]] + plot_layout(widths = c(1, 1.15))
save_fig(fig, "fig01_window_problem", width_mm = 190, height_mm = 112)
cat("Figure 1 written.\n")
