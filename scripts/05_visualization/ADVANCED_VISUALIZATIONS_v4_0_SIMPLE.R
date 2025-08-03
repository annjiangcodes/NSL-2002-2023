# =============================================================================
# ADVANCED VISUALIZATIONS v4.0 - SIMPLIFIED VERSION
# =============================================================================
# Purpose: Create publication-quality visualizations using the analysis outputs
# Version: 4.0 Simplified
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
cat("ADVANCED VISUALIZATIONS v4.0 - SIMPLIFIED\n")
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

# Load original data for additional analyses
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

cat("Data loaded successfully.\n")

# =============================================================================
# 2. THEME AND COLOR SETUP
# =============================================================================

# Enhanced publication theme
theme_publication_enhanced <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
  theme(
    # Title elements
    plot.title = element_text(size = rel(1.4), face = "bold", 
                             margin = margin(b = 10), hjust = 0),
    plot.subtitle = element_text(size = rel(1.1), color = "gray30", 
                                margin = margin(b = 10), hjust = 0),
    plot.caption = element_text(size = rel(0.8), color = "gray50", 
                               hjust = 0, margin = margin(t = 10)),
    
    # Axis elements
    axis.title = element_text(size = rel(1), face = "bold"),
    axis.text = element_text(size = rel(0.9)),
    
    # Legend elements
    legend.title = element_text(size = rel(1), face = "bold"),
    legend.text = element_text(size = rel(0.9)),
    legend.position = "bottom",
    
    # Panel elements
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    
    # Strip elements (for facets)
    strip.text = element_text(size = rel(1.1), face = "bold"),
    strip.background = element_rect(fill = "gray95", color = "gray70"),
    
    # Overall plot
    plot.background = element_rect(fill = "white", color = NA)
  )
}

# Color schemes
generation_palette <- c(
  "1st Generation" = "#D73027",    # Red
  "2nd Generation" = "#4575B4",    # Blue  
  "3rd+ Generation" = "#91BFDB"    # Light blue
)

# =============================================================================
# 3. VISUALIZATION 1: ENHANCED GENERATION TRENDS
# =============================================================================

cat("\n3. CREATING ENHANCED GENERATION TRENDS VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for visualization
trend_data <- generation_trends %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  pivot_longer(
    cols = c(liberalism_mean, restrictionism_mean),
    names_to = "index_type",
    values_to = "value"
  ) %>%
  mutate(
    index_label = ifelse(index_type == "liberalism_mean", 
                        "Immigration Policy Liberalism", 
                        "Immigration Policy Restrictionism"),
    ci_lower = ifelse(index_type == "liberalism_mean",
                     liberalism_ci_lower, restrictionism_ci_lower),
    ci_upper = ifelse(index_type == "liberalism_mean",
                     liberalism_ci_upper, restrictionism_ci_upper)
  )

p_trends <- ggplot(trend_data, 
                  aes(x = survey_year, y = value, color = generation_label)) +
  
  # Confidence ribbons
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
              alpha = 0.2, linetype = 0) +
  
  # Main lines and points
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  
  # Add smooth trends
  geom_smooth(method = "loess", se = FALSE, linewidth = 0.8, 
              linetype = "dashed", alpha = 0.7) +
  
  # Facet by index type
  facet_wrap(~index_label, ncol = 1, scales = "free_y") +
  
  # Scales and colors
  scale_color_manual(values = generation_palette, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_palette, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  
  # Labels
  labs(
    title = "Generational Trends in U.S. Hispanic Immigration Attitudes (2002-2023)",
    subtitle = "Mean values with 95% confidence intervals and LOESS smoothed trends",
    x = "Survey Year",
    y = "Standardized Index Score",
    caption = "Source: Analysis of Pew Research Center National Survey of Latinos data.\nDashed lines show LOESS smoothed trends."
  ) +
  
  theme_publication_enhanced()

ggsave("outputs/figure_v4_0_enhanced_generation_trends.png", 
       p_trends, width = 12, height = 10, dpi = 300)

cat("Enhanced generation trends visualization saved.\n")

# =============================================================================
# 4. VISUALIZATION 2: PERIOD EFFECTS WITH ANNOTATIONS
# =============================================================================

cat("\n4. CREATING PERIOD EFFECTS VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare period effects data
period_data <- period_effects %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  pivot_longer(
    cols = c(liberalism_mean, restrictionism_mean),
    names_to = "index_type",
    values_to = "value"
  ) %>%
  mutate(
    index_label = ifelse(index_type == "liberalism_mean",
                        "Liberalism", "Restrictionism"),
    se = ifelse(index_type == "liberalism_mean",
               liberalism_se, restrictionism_se)
  )

p_period <- ggplot(period_data, 
                  aes(x = period, y = value, fill = index_label)) +
  
  geom_bar(stat = "identity", position = position_dodge(width = 0.9), width = 0.8) +
  
  geom_errorbar(aes(ymin = value - se, ymax = value + se),
                position = position_dodge(width = 0.9),
                width = 0.25) +
  
  scale_fill_manual(values = c("Liberalism" = "#1B7837", 
                              "Restrictionism" = "#762A83"),
                   name = "Attitude Index") +
  
  labs(
    title = "Immigration Attitudes by Historical Period",
    subtitle = "Overall Hispanic population means with standard errors",
    x = "Historical Period",
    y = "Mean Standardized Score",
    caption = "Source: Pooled NSL data by period. Error bars show ±1 SE."
  ) +
  
  theme_publication_enhanced() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))

ggsave("outputs/figure_v4_0_period_effects_enhanced.png", 
       p_period, width = 10, height = 7, dpi = 300)

cat("Period effects visualization saved.\n")

# =============================================================================
# 5. VISUALIZATION 3: GENERATION COMPARISON ACROSS TIME
# =============================================================================

cat("\n5. CREATING GENERATION COMPARISON VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Select key years for comparison
key_years <- c(2002, 2012, 2022)

comparison_data <- generation_trends %>%
  filter(survey_year %in% key_years, !is.na(liberalism_mean)) %>%
  pivot_longer(
    cols = c(liberalism_mean, restrictionism_mean),
    names_to = "index_type",
    values_to = "value"
  ) %>%
  mutate(
    index_label = ifelse(index_type == "liberalism_mean",
                        "Liberalism", "Restrictionism"),
    se = ifelse(index_type == "liberalism_mean",
               liberalism_se, restrictionism_se),
    year_label = paste("Year:", survey_year)
  )

p_comparison <- ggplot(comparison_data, 
                      aes(x = generation_label, y = value, fill = generation_label)) +
  
  geom_bar(stat = "identity", position = position_dodge()) +
  
  geom_errorbar(aes(ymin = value - se, ymax = value + se),
                width = 0.25) +
  
  facet_grid(index_label ~ year_label, scales = "free_y") +
  
  scale_fill_manual(values = generation_palette, guide = "none") +
  
  labs(
    title = "Generational Differences in Immigration Attitudes: Three Time Points",
    subtitle = "Comparing 2002 (baseline), 2012 (Obama era), and 2022 (current)",
    x = "Immigrant Generation",
    y = "Mean Score",
    caption = "Source: NSL data. Error bars show ±1 SE."
  ) +
  
  theme_publication_enhanced() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/figure_v4_0_generation_comparison.png", 
       p_comparison, width = 12, height = 8, dpi = 300)

cat("Generation comparison visualization saved.\n")

# =============================================================================
# 6. VISUALIZATION 4: NET LIBERALISM TRENDS
# =============================================================================

cat("\n6. CREATING NET LIBERALISM VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

net_lib_data <- generation_trends %>%
  filter(!is.na(net_liberalism_mean))

p_net <- ggplot(net_lib_data, 
                aes(x = survey_year, y = net_liberalism_mean, 
                    color = generation_label, group = generation_label)) +
  
  geom_hline(yintercept = 0, linetype = "solid", color = "gray50", linewidth = 0.5) +
  
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  
  # Add annotations
  annotate("text", x = 2012, y = 0.3, 
           label = "Pro-Immigration\nDominance", 
           hjust = 0.5, vjust = -0.5, size = 4, fontface = "italic", color = "gray40") +
  annotate("text", x = 2012, y = -0.3, 
           label = "Anti-Immigration\nDominance", 
           hjust = 0.5, vjust = 1.5, size = 4, fontface = "italic", color = "gray40") +
  
  scale_color_manual(values = generation_palette, name = "Immigrant Generation") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  
  labs(
    title = "Net Immigration Policy Attitudes by Generation",
    subtitle = "Positive values indicate net pro-immigration stance (liberalism - restrictionism)",
    x = "Survey Year",
    y = "Net Liberalism Score",
    caption = "Source: Analysis of NSL data. Zero line indicates balanced attitudes."
  ) +
  
  theme_publication_enhanced()

ggsave("outputs/figure_v4_0_net_liberalism_enhanced.png", 
       p_net, width = 10, height = 7, dpi = 300)

cat("Net liberalism visualization saved.\n")

# =============================================================================
# 7. VISUALIZATION 5: COMPOSITE FIGURE FOR PUBLICATION
# =============================================================================

cat("\n7. CREATING COMPOSITE PUBLICATION FIGURE\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Panel A: Liberalism trends
panel_a <- generation_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, 
             color = generation_label, group = generation_label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = generation_palette, name = "") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 5)) +
  labs(title = "A. Immigration Policy Liberalism",
       x = "", y = "Mean Score") +
  theme_publication_enhanced(base_size = 10) +
  theme(legend.position = "none")

# Panel B: Restrictionism trends
panel_b <- generation_trends %>%
  filter(!is.na(restrictionism_mean)) %>%
  ggplot(aes(x = survey_year, y = restrictionism_mean, 
             color = generation_label, group = generation_label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_color_manual(values = generation_palette, name = "") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 5)) +
  labs(title = "B. Immigration Policy Restrictionism",
       x = "", y = "Mean Score") +
  theme_publication_enhanced(base_size = 10) +
  theme(legend.position = "none")

# Panel C: Period effects
panel_c <- period_effects %>%
  filter(!is.na(liberalism_mean)) %>%
  mutate(period_short = stringr::str_wrap(period, width = 10)) %>%
  ggplot(aes(x = period_short, y = liberalism_mean)) +
  geom_bar(stat = "identity", fill = "#2166AC") +
  geom_errorbar(aes(ymin = liberalism_mean - liberalism_se, 
                    ymax = liberalism_mean + liberalism_se),
                width = 0.3) +
  labs(title = "C. Period Effects (Liberalism)",
       x = "", y = "Mean Score") +
  theme_publication_enhanced(base_size = 10) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 8))

# Panel D: Legend
legend_data <- data.frame(
  x = 1:3,
  y = 1:3,
  generation = c("1st Generation", "2nd Generation", "3rd+ Generation")
)

panel_d <- ggplot(legend_data, aes(x = x, y = y, color = generation)) +
  geom_point(size = 5) +
  scale_color_manual(values = generation_palette, name = "Immigrant Generation") +
  theme_void() +
  theme(legend.position = "bottom",
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 11, face = "bold"))

# Combine panels
composite <- (panel_a | panel_b) / (panel_c | panel_d) +
  plot_annotation(
    title = "Hispanic Immigration Attitudes: Comprehensive Analysis (2002-2023)",
    subtitle = "Trends, period effects, and generational patterns",
    caption = "Source: Pew Research Center National Survey of Latinos. Error bars show ±1 SE.",
    theme = theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray40"),
      plot.caption = element_text(size = 9, color = "gray50")
    )
  )

ggsave("outputs/figure_v4_0_composite_publication_final.png",
       composite, width = 12, height = 10, dpi = 300)

cat("Composite publication figure saved.\n")

# =============================================================================
# 8. SUMMARY
# =============================================================================

cat("\n8. VISUALIZATION SUMMARY\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
cat("All visualizations created successfully:\n")
cat("1. Enhanced generation trends (dual panel)\n")
cat("2. Period effects with error bars\n")
cat("3. Generation comparison across time points\n")
cat("4. Net liberalism trends\n")
cat("5. Composite publication figure\n")
cat("\nAll outputs saved to outputs/ directory\n")

# =============================================================================
# END OF ADVANCED VISUALIZATIONS - SIMPLIFIED VERSION
# =============================================================================