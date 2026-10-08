## Figure 1. The estimation-window problem: a conceptual schematic.
##
## ILLUSTRATIVE DATA ONLY. Every series in this figure is synthetic and generated
## below from fixed formulas and a fixed random seed. No observed data, real years
## or real species are used, and nothing is read from ../Raw_data.
##
## The synthetic system has 50 years and two structural breaks, after years 20 and 40:
##   early  (years 1-20)   effort builds up and log(CPUE) falls steeply with effort
##                         (a clear depletion signal with strong contrast);
##   middle (years 21-40)  CPUE drops to a low, flat level while effort stays high and
##                         fluctuates (CPUE responds only weakly to effort);
##   recent (years 41-50)  effort is cut sharply and keeps falling, and CPUE partly
##                         recovers (a third, different CPUE-effort relationship).
## Three candidate windows, each ending in the final year: full history (years 1-50,
## all three periods), post-break (21-50, two periods) and recent (41-50, one period).
## Panel C uses made-up curves for the information / representativeness trade-off.
##
## Run from this folder:  Rscript make_fig01.R
## Output: fig01_window_problem.{pdf,png,svg}

source("../_common/theme_dsi.R")

## ---- synthetic series -------------------------------------------------------------
n_year  <- 50L
break1  <- 20L             # last year of the early period
break2  <- 40L             # last year of the middle period
set.seed(20240601)         # fixed seed: the figure is identical on every run
yr <- seq_len(n_year)
e_noise <- rnorm(n_year, 0, 1.4)
c_noise <- rnorm(n_year, 0, 0.06)

period <- case_when(yr <= break1 ~ "pre", yr <= break2 ~ "mid", TRUE ~ "recent")
effort <- case_when(
  period == "pre" ~ 5 + 23 * (yr - 1) / (break1 - 1),               # steady build-up
  period == "mid" ~ 34 + 6 * sin((yr - break1) / 3),                # high, fluctuating
  TRUE            ~ 19 - 1.2 * (yr - break2 - 1)) +                 # cut, then falling
  e_noise
log_cpue <- case_when(
  period == "pre" ~ 4.45 - 0.028 * effort,                          # steep depletion
  period == "mid" ~ 3.30 - 0.008 * effort,                          # low and flat
  TRUE            ~ 3.95 - 0.045 * effort) +                        # partial recovery
  c_noise
syn <- tibble(year = yr, effort = effort, cpue = exp(log_cpue), period = period)

## Candidate windows. Each bar has the colour of the years it adds, so the bars
## double as the key for the points in A and B.
windows <- tibble(window = c("Full history", "Post-break", "Recent"),
                  start  = c(1L, break1 + 1L, break2 + 1L),
                  period = c("pre", "mid", "recent"))
win_levels <- windows$window

x_year <- scale_x_continuous(breaks = c(1, seq(10, 50, 10)), limits = c(0.5, n_year + 0.5),
                             expand = c(0, 0))
v_brk <- geom_vline(xintercept = c(break1, break2) + 0.5, colour = col_break,
                    linetype = "22", linewidth = 0.3)
no_x <- theme(axis.text.x = element_blank(), axis.title.x = element_blank(),
              axis.ticks.x = element_blank())
no_y <- theme(axis.text.y = element_blank(), axis.ticks.y = element_blank())

## ---- A: the windows over a synthetic CPUE and effort series ------------------------
trk <- windows %>% mutate(y = factor(window, levels = rev(window)))
pA1 <- ggplot(trk) +
  v_brk +
  geom_segment(aes(x = start - 0.4, xend = n_year + 0.4, y = y, yend = y, colour = period),
               linewidth = 2.6, lineend = "butt") +
  annotate("text", x = c(break1, break2) + 0.9, y = 3.55, label = c("break 1", "break 2"),
           hjust = 0, vjust = 0, size = pt(7), colour = ink1, family = base_family) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_y_discrete(expand = expansion(add = c(0.6, 0.9))) +
  x_year + coord_cartesian(clip = "off") +
  labs(y = NULL, tag = "A") + theme_dsi() + no_x +
  theme(panel.grid = element_blank(), axis.text.y = element_text(colour = ink1, size = 7))

pA2 <- ggplot(syn, aes(year, cpue)) + v_brk +
  geom_line(colour = ink3, linewidth = 0.35) +
  geom_point(aes(colour = period), size = 1.1) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  x_year + labs(y = "CPUE") + theme_dsi() + no_x + no_y

pA3 <- ggplot(syn, aes(year, effort)) + v_brk +
  geom_line(colour = ink3, linewidth = 0.35) +
  geom_point(aes(colour = period), size = 1.1) +
  scale_colour_manual(values = col_period, guide = "none") +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.08))) +
  x_year + labs(x = "Year", y = "Effort") + theme_dsi() + no_y

pA <- pA1 / pA2 / pA3 + plot_layout(heights = c(0.62, 1, 1))

## ---- B: what each window "sees": log(CPUE) against effort --------------------------
fits <- lapply(seq_len(nrow(windows)), function(k) {
  d <- syn %>% filter(year >= windows$start[k])
  m <- lm(log(cpue) ~ effort, data = d)
  grid <- tibble(effort = seq(min(d$effort), max(d$effort), length.out = 60))
  pr <- predict(m, grid, interval = "confidence")
  list(pts = mutate(d, window = windows$window[k]),
       fit = mutate(grid, window = windows$window[k], fit = pr[, "fit"],
                    lo = pr[, "lwr"], hi = pr[, "upr"]))
})
pts <- bind_rows(lapply(fits, `[[`, "pts")) %>% mutate(window = factor(window, win_levels))
fit <- bind_rows(lapply(fits, `[[`, "fit")) %>% mutate(window = factor(window, win_levels))

pB <- ggplot(pts, aes(effort, log(cpue))) +
  geom_ribbon(data = fit, aes(x = effort, ymin = lo, ymax = hi), inherit.aes = FALSE,
              fill = ink3, alpha = 0.22) +
  geom_line(data = fit, aes(x = effort, y = fit), colour = ink1, linewidth = 0.5) +
  geom_point(aes(colour = period), size = 1.2, stroke = 0) +
  facet_wrap(~ window, nrow = 1) +
  scale_colour_manual(values = col_period, guide = "none") +
  labs(x = "Effort", y = "log CPUE", tag = "B") + theme_dsi() + no_y +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        panel.spacing.x = unit(3, "mm"))

## ---- C: conceptual trade-off along the window start year ---------------------------
## Made-up curves. Information (contrast and length) falls as the window shortens,
## slowly at first and quickly for short windows. Representativeness of the current
## system steps up after each break: low while the window still includes the early
## period, intermediate while it includes the middle period, high once it holds only
## the recent period. Suitability is their product. Each curve is scaled to its own
## maximum, so only the shapes and the location of the peak carry meaning.
s <- seq(1, 46, by = 0.05)
info <- 1 - ((s - 1) / n_year)^1.6
repr <- case_when(s <= break1 + 0.5 ~ 0.12 + 0.18 * (s - 1) / (break1 - 1),
                  s <= break2 + 0.5 ~ 0.50 + 0.15 * (s - break1 - 1) / (break2 - break1 - 1),
                  TRUE              ~ 1)
suit <- info * repr; suit <- suit / max(suit)
crv <- tibble(s = s, Informative = info, Representative = repr, Suitable = suit) %>%
  pivot_longer(-s, names_to = "curve", values_to = "v") %>%
  mutate(curve = factor(curve, c("Informative", "Representative", "Suitable")))
## the diamond marks the best whole-year start (window starts are whole years)
peak <- crv %>% filter(curve == "Suitable", abs(s - round(s)) < 1e-9) %>%
  slice_max(v, n = 1, with_ties = FALSE)
lab_at <- tibble(curve = factor(c("Informative", "Representative", "Suitable"), levels(crv$curve)),
                 s = c(3, 3, 27)) %>%
  left_join(crv %>% mutate(s = round(s, 2)), by = c("curve", "s")) %>%
  mutate(vjust = c(-0.8, 1.9, -0.9))
c_col <- c(Informative = "#3d74b8", Representative = ink3, Suitable = ink1)
c_lty <- c(Informative = "solid", Representative = "22", Suitable = "solid")
c_lwd <- c(Informative = 0.6, Representative = 0.6, Suitable = 1.0)

pC <- ggplot(crv, aes(s, v)) +
  v_brk +
  geom_line(aes(colour = curve, linetype = curve, linewidth = curve)) +
  geom_text(data = lab_at, aes(label = curve, colour = curve, vjust = vjust), hjust = 0,
            size = pt(7), family = base_family) +
  geom_point(data = windows, aes(x = start, y = -0.06, colour = period), inherit.aes = FALSE,
             shape = 17, size = 1.9) +
  geom_point(data = peak, shape = 23, fill = "#009E73", colour = "white", size = 2.6,
             stroke = 0.5) +
  scale_colour_manual(values = c(c_col, col_period), guide = "none") +
  scale_linetype_manual(values = c_lty, guide = "none") +
  scale_linewidth_manual(values = c_lwd, guide = "none") +
  scale_x_continuous(breaks = c(1, seq(10, 50, 10)), limits = c(0.5, n_year + 0.5),
                     expand = c(0, 0)) +
  scale_y_continuous(limits = c(-0.1, 1.12), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  labs(x = "First year of window", y = "Relative value", tag = "C") + theme_dsi() + no_y +
  theme(panel.grid.major.y = element_blank())

## ---- assemble --------------------------------------------------------------------
right <- pB / pC + plot_layout(heights = c(1, 1.05))
fig <- (wrap_elements(full = pA) | wrap_elements(full = right)) +
  plot_layout(widths = c(1, 1.15)) &
  theme(plot.tag.position = c(0, 1))
save_fig(fig, "fig01_window_problem", width_mm = 190, height_mm = 100)
cat(sprintf("Figure 1 written (suitability peaks at window start %.2f).\n", peak$s))
