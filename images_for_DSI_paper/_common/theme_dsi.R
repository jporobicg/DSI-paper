## Shared graphical language for the DSI manuscript figures.
## Sourced by every make_figNN.R. Journal target: Fisheries Research
## (single column 90 mm, double column 190 mm; vector PDF + 300 dpi PNG).

suppressPackageStartupMessages({
  library(ggplot2); library(dplyr); library(tidyr); library(readr); library(patchwork)
})

## ---- scenario identity: one hue per family, shape/linetype within family ----
## Families: full history (grey) | breakpoint-derived windows (blue) |
## assessment convention (vermillion) | DSIr-derived windows (bluish green).
## Okabe-Ito hues; validated with the dataviz palette script (all pairs, light).
scen_levels <- c("baseline", "post_1987", "recent_2016", "per_species",
                 "thai_dof", "dsir_group", "dsir_channel")
scen_labels <- c(baseline     = "Full history (1971)",
                 post_1987    = "Post-1987 break",
                 recent_2016  = "Recent (2016)",
                 per_species  = "Per-species RV break",
                 thai_dof     = "Thai DOF starts",
                 dsir_group   = "DSIr: group optimum",
                 dsir_channel = "DSIr: dominant-fleet optimum")
scen_col <- c(baseline = "#6f6f6f", post_1987 = "#0072B2", recent_2016 = "#0072B2",
              per_species = "#0072B2", thai_dof = "#D55E00",
              dsir_group = "#009E73", dsir_channel = "#009E73")
scen_lty <- c(baseline = "solid", post_1987 = "solid", recent_2016 = "dotted",
              per_species = "longdash", thai_dof = "solid",
              dsir_group = "solid", dsir_channel = "longdash")
scen_shape <- c(baseline = 16, post_1987 = 16, recent_2016 = 1, per_species = 17,
                thai_dof = 15, dsir_group = 18, dsir_channel = 5)

## ---- other roles -----------------------------------------------------------
col_dsi   <- "#86b6ef"   # DSI, raw (lighter step of the blue ramp)
col_dsir  <- "#0d366b"   # DSIr, robustness-adjusted (dark step)
col_break <- "#0b0b0b"   # 1987 break line (ink)
col_gap   <- "#e1e0d9"   # survey-gap band
col_down  <- "#0072B2"   # breakpoint: decrease
col_up    <- "#D55E00"   # breakpoint: increase
col_null  <- "#c3c2b7"   # null / stationary reference band
col_comp  <- c(slope = "#0072B2", effort_contrast = "#56B4E9", cpue_contrast = "#009E73",
               sample_size = "#E69F00", catch_effort = "#CC79A7")   # Fig 1C stacked segments
col_period <- c(pre = "#9a9a9a", mid = "#56B4E9", recent = "#0072B2")
ink1 <- "#0b0b0b"; ink2 <- "#52514e"; ink3 <- "#898781"; grid_col <- "#e1e0d9"

species_labels <- c(ANC = "Anchovies", CMA = "Indian mackerel", DMF = "Demersal mixed fish",
                    LPF = "Large pelagic finfish", MPF = "Medium pelagic finfish",
                    NTU = "Neritic tuna", SAR = "Sardines", SCP = "Scads")
group_labels <- c(Anchovy = "Anchovy group", Demersal = "Demersal group", Pelagic = "Pelagic group")

## ---- theme -----------------------------------------------------------------
theme_dsi <- function(base_size = 8) {
  theme_minimal(base_size = base_size, base_family = "sans") +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(colour = grid_col, linewidth = 0.25),
          axis.line = element_blank(),
          axis.ticks = element_line(colour = "#c3c2b7", linewidth = 0.25),
          axis.text = element_text(colour = ink2, size = base_size - 1),
          axis.title = element_text(colour = ink1, size = base_size),
          strip.text = element_text(colour = ink1, face = "bold", size = base_size, hjust = 0),
          plot.title = element_text(colour = ink1, face = "bold", size = base_size + 1, hjust = 0),
          plot.subtitle = element_text(colour = ink2, size = base_size - 0.5),
          plot.tag = element_text(face = "bold", size = base_size + 2),
          legend.position = "bottom", legend.title = element_text(size = base_size - 0.5),
          legend.text = element_text(size = base_size - 1), legend.key.height = unit(3, "mm"),
          legend.key.width = unit(6, "mm"),
          plot.background = element_rect(fill = "white", colour = NA),
          plot.margin = margin(3, 3, 3, 3))
}

## ---- output ----------------------------------------------------------------
save_fig <- function(p, stem, width_mm = 190, height_mm = 120, dir = ".") {
  ggsave(file.path(dir, paste0(stem, ".pdf")), p, width = width_mm, height = height_mm,
         units = "mm", device = cairo_pdf)
  ggsave(file.path(dir, paste0(stem, ".png")), p, width = width_mm, height = height_mm,
         units = "mm", dpi = 300, device = ragg::agg_png, bg = "white")
  invisible(file.path(dir, paste0(stem, c(".pdf", ".png"))))
}
