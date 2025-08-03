# =============================================================================
# ENHANCED VISUALIZATIONS v4.1 - MAGNIFIED SCALES FOR BETTER VISIBILITY
# =============================================================================
# Purpose: Create publication-quality visualizations with magnified scales
#          to better show subtle but meaningful changes in attitudes
# Version: 4.1
# Date: January 2025
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(viridis)
library(RColorBrewer)
library(scales)
library(patchwork)

cat("=============================================================\n")
cat("ENHANCED VISUALIZATIONS v4.1 - MAGNIFIED SCALES\n")
cat("=============================================================\n")

# =============================================================================
# 1. LOAD PREPARED DATA
# =============================================================================

cat("\n1. LOADING ANALYSIS OUTPUTS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load saved analysis outputs
overall_trends <- read_csv("outputs/overall_trends_v4_0.csv", show_col_types = FALSE)
generation_trends <- read_csv("outputs/generation_year_trends_v4_0.csv", show_col_types = FALSE)
period_effects <- read_csv("outputs/period_effects_v4_0.csv", show_col_types = FALSE)
regression_results <- read_csv("outputs/regression_results_v4_0.csv", show_col_types = FALSE)

# Check the actual range of values
cat("\nActual data ranges:\n")
cat(sprintf("Liberalism: [%.3f, %.3f]\n", 
            min(generation_trends$liberalism_mean, na.rm = TRUE),
            max(generation_trends$liberalism_mean, na.rm = TRUE)))
cat(sprintf("Restrictionism: [%.3f, %.3f]\n",
            min(generation_trends$restrictionism_mean, na.rm = TRUE),
            max(generation_trends$restrictionism_mean, na.rm = TRUE)))

# =============================================================================
# 2. THEME AND COLOR SETUP
# =============================================================================

# Enhanced publication theme
theme_publication_magnified <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
  theme(
    plot.title = element_text(size = rel(1.4), face = "bold", 
                             margin = margin(b = 10), hjust = 0),
    plot.subtitle = element_text(size = rel(1.1), color = "gray30", 
                                margin = margin(b = 10), hjust = 0),
    plot.caption = element_text(size = rel(0.8), color = "gray50", 
                               hjust = 0, margin = margin(t = 10)),
    axis.title = element_text(size = rel(1), face = "bold"),
    axis.text = element_text(size = rel(0.9)),
    legend.title = element_text(size = rel(1), face = "bold"),
    legend.text = element_text(size = rel(0.9)),
    legend.position = "bottom",
    panel.grid.major = element_line(color = "gray85", linewidth = 0.5),
    panel.grid.minor = element_line(color = "gray95", linewidth = 0.25),
    panel.background = element_rect(fill = "white", color = NA),
    strip.text = element_text(size = rel(1.1), face = "bold"),
    strip.background = element_rect(fill = "gray95", color = "gray70"),
    plot.background = element_rect(fill = "white", color = NA)
  )
}

# Color schemes
generation_palette <- c(
  "1st Generation" = "#E41A1C",    # Bright red
  "2nd Generation" = "#377EB8",    # Blue  
  "3rd+ Generation" = "#4DAF4A"    # Green
)

# =============================================================================
# 3. VISUALIZATION 1: MAGNIFIED GENERATION TRENDS
# =============================================================================

cat("\n3. CREATING MAGNIFIED GENERATION TRENDS VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate appropriate y-axis limits for each index
lib_range <- range(generation_trends$liberalism_mean, na.rm = TRUE)
lib_buffer <- diff(lib_range) * 0.2
lib_limits <- c(lib_range[1] - lib_buffer, lib_range[2] + lib_buffer)

res_range <- range(generation_trends$restrictionism_mean, na.rm = TRUE)
res_buffer <- diff(res_range) * 0.2
res_limits <- c(res_range[1] - res_buffer, res_range[2] + res_buffer)

# Create liberalism panel with magnified scale
p_lib_magnified <- generation_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, color = generation_label)) +
  
  # Add zero line for reference
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.5) +
  
  # Confidence ribbons
  geom_ribbon(aes(ymin = liberalism_ci_lower, ymax = liberalism_ci_upper, 
                  fill = generation_label),
              alpha = 0.15, linetype = 0) +
  
  # Main lines and points
  geom_line(linewidth = 1.5) +
  geom_point(size = 3.5) +
  
  # Add trend lines
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8, 
              linetype = "dotted", alpha = 0.8) +
  
  # Scales
  scale_color_manual(values = generation_palette, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_palette, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  scale_y_continuous(limits = lib_limits,
                     labels = function(x) sprintf("%.2f", x)) +
  
  # Labels
  labs(
    title = "Immigration Policy Liberalism by Generation",
    subtitle = "Magnified scale shows subtle but important differences",
    x = "Survey Year",
    y = "Liberalism Index (Standardized)"
  ) +
  
  # Add annotations for key findings
  annotate("text", x = 2018, y = lib_limits[2] * 0.9,
           label = "1st Gen: Slight increase\n(p = 0.053)",
           size = 3, color = generation_palette["1st Generation"],
           fontface = "italic") +
  
  theme_publication_magnified()

# Create restrictionism panel with magnified scale
p_res_magnified <- generation_trends %>%
  filter(!is.na(restrictionism_mean)) %>%
  ggplot(aes(x = survey_year, y = restrictionism_mean, color = generation_label)) +
  
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.5) +
  
  geom_ribbon(aes(ymin = restrictionism_ci_lower, ymax = restrictionism_ci_upper, 
                  fill = generation_label),
              alpha = 0.15, linetype = 0) +
  
  geom_line(linewidth = 1.5) +
  geom_point(size = 3.5) +
  
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.8, 
              linetype = "dotted", alpha = 0.8) +
  
  scale_color_manual(values = generation_palette, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_palette, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  scale_y_continuous(limits = res_limits,
                     labels = function(x) sprintf("%.2f", x)) +
  
  labs(
    title = "Immigration Policy Restrictionism by Generation",
    subtitle = "Note the different patterns across generations",
    x = "Survey Year",
    y = "Restrictionism Index (Standardized)"
  ) +
  
  theme_publication_magnified()

# Combine panels
p_combined_magnified <- p_lib_magnified / p_res_magnified +
  plot_annotation(
    title = "Generational Trends in Hispanic Immigration Attitudes (2002-2023)",
    subtitle = "Magnified scales reveal subtle but significant patterns",
    caption = "Source: Pew Research Center National Survey of Latinos. Shaded areas show 95% confidence intervals.\nDotted lines show linear trends. Zero line indicates population mean.",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 13, color = "gray40"),
      plot.caption = element_text(size = 10, color = "gray50", hjust = 0)
    )
  )

ggsave("outputs/figure_v4_1_magnified_generation_trends.png", 
       p_combined_magnified, width = 12, height = 12, dpi = 300)

cat("Magnified generation trends visualization saved.\n")

# =============================================================================
# 4. VISUALIZATION 2: DIFFERENCE FROM BASELINE
# =============================================================================

cat("\n4. CREATING DIFFERENCE FROM BASELINE VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate differences from 2002 baseline for each generation
baseline_data <- generation_trends %>%
  filter(survey_year == 2002) %>%
  select(generation_label, 
         baseline_lib = liberalism_mean,
         baseline_res = restrictionism_mean)

diff_data <- generation_trends %>%
  left_join(baseline_data, by = "generation_label") %>%
  mutate(
    lib_diff = liberalism_mean - baseline_lib,
    res_diff = restrictionism_mean - baseline_res
  ) %>%
  filter(!is.na(lib_diff))

# Create difference plot for liberalism
p_diff <- diff_data %>%
  ggplot(aes(x = survey_year, y = lib_diff, color = generation_label)) +
  
  geom_hline(yintercept = 0, linetype = "solid", color = "gray30") +
  
  # Show uncertainty
  geom_ribbon(aes(ymin = lib_diff - liberalism_se * 1.96,
                  ymax = lib_diff + liberalism_se * 1.96,
                  fill = generation_label),
              alpha = 0.2, linetype = 0) +
  
  geom_line(linewidth = 1.5) +
  geom_point(size = 3) +
  
  # Add annotations
  annotate("text", x = 2012, y = 0.02, 
           label = "More Liberal than 2002", 
           size = 4, color = "gray40", fontface = "italic") +
  annotate("text", x = 2012, y = -0.02, 
           label = "Less Liberal than 2002", 
           size = 4, color = "gray40", fontface = "italic") +
  
  scale_color_manual(values = generation_palette, name = "Generation") +
  scale_fill_manual(values = generation_palette, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  scale_y_continuous(labels = function(x) sprintf("%+.2f", x)) +
  
  labs(
    title = "Change in Immigration Policy Liberalism from 2002 Baseline",
    subtitle = "Tracking how each generation's attitudes have shifted over time",
    x = "Survey Year",
    y = "Difference from 2002 Baseline",
    caption = "Source: NSL data. Positive values indicate increased liberalism relative to 2002."
  ) +
  
  theme_publication_magnified()

ggsave("outputs/figure_v4_1_difference_from_baseline.png", 
       p_diff, width = 10, height = 7, dpi = 300)

cat("Difference from baseline visualization saved.\n")

# =============================================================================
# 5. VISUALIZATION 3: PERCENT CHANGE
# =============================================================================

cat("\n5. CREATING PERCENT CHANGE VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate percent change from baseline
pct_change_data <- diff_data %>%
  mutate(
    lib_pct_change = (lib_diff / abs(baseline_lib)) * 100,
    res_pct_change = (res_diff / abs(baseline_res)) * 100
  ) %>%
  filter(is.finite(lib_pct_change))

# Create percent change plot
p_pct <- pct_change_data %>%
  pivot_longer(
    cols = c(lib_pct_change, res_pct_change),
    names_to = "measure",
    values_to = "pct_change"
  ) %>%
  mutate(
    measure_label = ifelse(measure == "lib_pct_change",
                          "Liberalism", "Restrictionism")
  ) %>%
  ggplot(aes(x = survey_year, y = pct_change, color = generation_label)) +
  
  geom_hline(yintercept = 0, linetype = "solid", color = "gray30") +
  
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  
  facet_wrap(~measure_label, scales = "free_y") +
  
  scale_color_manual(values = generation_palette, name = "Generation") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 4)) +
  scale_y_continuous(labels = function(x) paste0(round(x), "%")) +
  
  labs(
    title = "Percent Change in Immigration Attitudes from 2002 Baseline",
    subtitle = "Relative changes show divergent generational trajectories",
    x = "Survey Year",
    y = "Percent Change from 2002",
    caption = "Source: NSL data. Calculated as (current - 2002) / |2002| × 100%"
  ) +
  
  theme_publication_magnified()

ggsave("outputs/figure_v4_1_percent_change.png", 
       p_pct, width = 12, height = 7, dpi = 300)

cat("Percent change visualization saved.\n")

# =============================================================================
# 6. VISUALIZATION 4: ZOOMED SCATTER WITH TRENDS
# =============================================================================

cat("\n6. CREATING ZOOMED SCATTER PLOT WITH TRENDS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create zoomed scatter plot showing individual year points
p_scatter <- generation_trends %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  ggplot(aes(x = liberalism_mean, y = restrictionism_mean, 
             color = generation_label)) +
  
  # Add quadrant lines at zero
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.5) +
  
  # Points sized by year (recent years larger)
  geom_point(aes(size = survey_year), alpha = 0.7) +
  
  # Add year labels for key years
  geom_text(data = . %>% filter(survey_year %in% c(2002, 2012, 2022)),
            aes(label = survey_year),
            nudge_x = 0.02, nudge_y = 0.02,
            size = 3) +
  
  # Add trajectory lines
  geom_path(aes(group = generation_label), 
            linewidth = 1, alpha = 0.5,
            arrow = arrow(length = unit(0.2, "cm"), type = "closed")) +
  
  # Quadrant labels
  annotate("text", x = -0.15, y = 0.15, 
           label = "Liberal &\nRestrictive", 
           size = 3.5, color = "gray60", fontface = "italic") +
  annotate("text", x = 0.15, y = 0.15, 
           label = "Conservative &\nRestrictive", 
           size = 3.5, color = "gray60", fontface = "italic") +
  annotate("text", x = -0.15, y = -0.15, 
           label = "Liberal &\nPermissive", 
           size = 3.5, color = "gray60", fontface = "italic") +
  annotate("text", x = 0.15, y = -0.15, 
           label = "Conservative &\nPermissive", 
           size = 3.5, color = "gray60", fontface = "italic") +
  
  scale_color_manual(values = generation_palette, name = "Generation") +
  scale_size_continuous(range = c(3, 8), guide = "none") +
  
  # Set zoomed limits based on data
  coord_cartesian(
    xlim = c(min(generation_trends$liberalism_mean, na.rm = TRUE) - 0.05,
             max(generation_trends$liberalism_mean, na.rm = TRUE) + 0.05),
    ylim = c(min(generation_trends$restrictionism_mean, na.rm = TRUE) - 0.05,
             max(generation_trends$restrictionism_mean, na.rm = TRUE) + 0.05)
  ) +
  
  labs(
    title = "Immigration Attitude Space: Generational Trajectories",
    subtitle = "Arrows show direction of change from 2002 to 2022",
    x = "Immigration Policy Liberalism →",
    y = "Immigration Policy Restrictionism →",
    caption = "Source: NSL data. Point size indicates survey year (larger = more recent)."
  ) +
  
  theme_publication_magnified()

ggsave("outputs/figure_v4_1_attitude_space_zoomed.png", 
       p_scatter, width = 10, height = 9, dpi = 300)

cat("Zoomed attitude space visualization saved.\n")

# =============================================================================
# 7. VISUALIZATION 5: GENERATION GAP OVER TIME
# =============================================================================

cat("\n7. CREATING GENERATION GAP VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate generation gaps (difference between 1st and 3rd generation)
gap_data <- generation_trends %>%
  select(survey_year, generation_label, liberalism_mean, restrictionism_mean) %>%
  pivot_wider(
    names_from = generation_label,
    values_from = c(liberalism_mean, restrictionism_mean)
  ) %>%
  mutate(
    lib_gap = `liberalism_mean_1st Generation` - `liberalism_mean_3rd+ Generation`,
    res_gap = `restrictionism_mean_1st Generation` - `restrictionism_mean_3rd+ Generation`
  ) %>%
  filter(!is.na(lib_gap) | !is.na(res_gap))

p_gap <- gap_data %>%
  pivot_longer(
    cols = c(lib_gap, res_gap),
    names_to = "measure",
    values_to = "gap"
  ) %>%
  mutate(
    measure_label = ifelse(measure == "lib_gap",
                          "Liberalism Gap", "Restrictionism Gap")
  ) %>%
  filter(!is.na(gap)) %>%
  ggplot(aes(x = survey_year, y = gap)) +
  
  geom_hline(yintercept = 0, linetype = "solid", color = "gray30") +
  
  geom_area(aes(fill = measure_label), alpha = 0.6) +
  geom_line(linewidth = 1.5) +
  geom_point(size = 3) +
  
  facet_wrap(~measure_label) +
  
  scale_fill_manual(values = c("Liberalism Gap" = "#2166AC",
                              "Restrictionism Gap" = "#B2182B"),
                   guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  
  labs(
    title = "The Generation Gap: 1st vs 3rd+ Generation Differences",
    subtitle = "Positive values indicate 1st generation is more liberal/restrictive than 3rd+",
    x = "Survey Year",
    y = "Attitude Difference (1st - 3rd+ Generation)",
    caption = "Source: NSL data. Shows the gap between foreign-born and third+ generation Hispanics."
  ) +
  
  theme_publication_magnified()

ggsave("outputs/figure_v4_1_generation_gap.png", 
       p_gap, width = 12, height = 6, dpi = 300)

cat("Generation gap visualization saved.\n")

# =============================================================================
# 8. SUMMARY
# =============================================================================

cat("\n8. VISUALIZATION SUMMARY\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
cat("Enhanced visualizations with magnified scales created:\n")
cat("1. Magnified generation trends (dual panel)\n")
cat("2. Difference from 2002 baseline\n")
cat("3. Percent change visualization\n")
cat("4. Zoomed attitude space with trajectories\n")
cat("5. Generation gap over time\n")
cat("\nAll visualizations saved to outputs/ directory\n")
cat("\nThese magnified visualizations better show:\n")
cat("- Subtle but meaningful changes over time\n")
cat("- Generational differences and convergence patterns\n")
cat("- Relative changes and trajectories\n")
cat("- The actual magnitude of attitude shifts\n")

# =============================================================================
# END OF ENHANCED VISUALIZATIONS - MAGNIFIED SCALES
# =============================================================================