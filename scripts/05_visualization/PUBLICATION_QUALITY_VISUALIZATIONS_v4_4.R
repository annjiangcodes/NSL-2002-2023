# =============================================================================
# PUBLICATION QUALITY VISUALIZATIONS v4.4 - CONSISTENT STYLING
# =============================================================================
# Purpose: Create all visualizations with consistent publication-quality styling
#          Professional color schemes, white backgrounds, high-quality output
# Version: 4.4
# Date: January 2025
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(scales)
library(patchwork)
library(RColorBrewer)
library(viridis)

cat("=============================================================\n")
cat("PUBLICATION QUALITY VISUALIZATIONS v4.4\n")
cat("Creating consistent, professional visualizations\n")
cat("=============================================================\n")

# =============================================================================
# 1. CONSISTENT THEME DEFINITION
# =============================================================================

# Define publication theme with white background
theme_publication <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
  theme(
    # Text elements
    plot.title = element_text(size = rel(1.4), face = "bold", 
                             color = "black", margin = margin(b = 10)),
    plot.subtitle = element_text(size = rel(1.1), color = "#4A4A4A", 
                                margin = margin(b = 10)),
    plot.caption = element_text(size = rel(0.8), color = "#6A6A6A", 
                               hjust = 0, margin = margin(t = 10)),
    
    # Axis elements
    axis.title = element_text(size = rel(1), face = "bold", color = "black"),
    axis.text = element_text(size = rel(0.9), color = "black"),
    axis.line = element_line(color = "#333333", size = 0.5),
    axis.ticks = element_line(color = "#333333", size = 0.5),
    
    # Legend
    legend.title = element_text(size = rel(1), face = "bold", color = "black"),
    legend.text = element_text(size = rel(0.9), color = "black"),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key = element_rect(fill = "white", color = NA),
    legend.position = "bottom",
    
    # Panel elements
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_line(color = "#E0E0E0", size = 0.5),
    panel.grid.minor = element_line(color = "#F0F0F0", size = 0.25),
    panel.border = element_rect(fill = NA, color = "#CCCCCC", size = 0.5),
    
    # Strip elements (for facets)
    strip.background = element_rect(fill = "#F5F5F5", color = "#CCCCCC"),
    strip.text = element_text(size = rel(1), face = "bold", color = "black"),
    
    # Overall plot
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(20, 20, 20, 20)
  )
}

# Define consistent color palette
generation_colors <- c(
  "1st Generation" = "#E41A1C",    # Red
  "2nd Generation" = "#377EB8",    # Blue
  "3rd+ Generation" = "#4DAF4A"    # Green
)

# Alternative professional palette
generation_colors_alt <- c(
  "1st Generation" = "#D62728",    # Darker red
  "2nd Generation" = "#1F77B4",    # Darker blue
  "3rd+ Generation" = "#2CA02C"    # Darker green
)

# =============================================================================
# 2. LOAD DATA
# =============================================================================

cat("\n1. LOADING DATA\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load analysis outputs
generation_trends <- read_csv("outputs/generation_year_trends_v4_0.csv", show_col_types = FALSE)
overall_trends <- read_csv("outputs/overall_trends_v4_0.csv", show_col_types = FALSE)
period_effects <- read_csv("outputs/period_effects_v4_0.csv", show_col_types = FALSE)
disaggregated_trends <- read_csv("outputs/disaggregated_trends_v4_3.csv", show_col_types = FALSE)

cat("Data loaded successfully\n")

# =============================================================================
# 3. MAIN GENERATION TRENDS - MAGNIFIED
# =============================================================================

cat("\n2. CREATING MAIN GENERATION TRENDS VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate appropriate y-limits
lib_data <- generation_trends %>% filter(!is.na(liberalism_mean))
res_data <- generation_trends %>% filter(!is.na(restrictionism_mean))

lib_range <- range(lib_data$liberalism_mean)
lib_expand <- diff(lib_range) * 0.15
lib_limits <- c(lib_range[1] - lib_expand, lib_range[2] + lib_expand)

res_range <- range(res_data$restrictionism_mean)
res_expand <- diff(res_range) * 0.15
res_limits <- c(res_range[1] - res_expand, res_range[2] + res_expand)

# Create liberalism panel
p_lib <- lib_data %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, color = generation_label)) +
  
  # Reference line at zero
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666", size = 0.5) +
  
  # Confidence ribbons
  geom_ribbon(aes(ymin = liberalism_ci_lower, ymax = liberalism_ci_upper, 
                  fill = generation_label),
              alpha = 0.15, color = NA) +
  
  # Lines and points
  geom_line(size = 1.5) +
  geom_point(size = 3, shape = 16) +
  
  # Scales
  scale_color_manual(values = generation_colors, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_colors, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2024, by = 4), 
                     limits = c(2001, 2024)) +
  scale_y_continuous(limits = lib_limits,
                     labels = function(x) sprintf("%.2f", x)) +
  
  # Labels
  labs(
    title = "Immigration Policy Liberalism",
    x = NULL,
    y = "Standardized Score"
  ) +
  
  theme_publication() +
  theme(legend.position = "none")

# Create restrictionism panel
p_res <- res_data %>%
  ggplot(aes(x = survey_year, y = restrictionism_mean, color = generation_label)) +
  
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666", size = 0.5) +
  
  geom_ribbon(aes(ymin = restrictionism_ci_lower, ymax = restrictionism_ci_upper, 
                  fill = generation_label),
              alpha = 0.15, color = NA) +
  
  geom_line(size = 1.5) +
  geom_point(size = 3, shape = 16) +
  
  scale_color_manual(values = generation_colors, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_colors, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2024, by = 4),
                     limits = c(2001, 2024)) +
  scale_y_continuous(limits = res_limits,
                     labels = function(x) sprintf("%.2f", x)) +
  
  labs(
    title = "Immigration Policy Restrictionism",
    x = "Survey Year",
    y = "Standardized Score"
  ) +
  
  theme_publication()

# Combine panels
p_main <- p_lib / p_res +
  plot_annotation(
    title = "Generational Trends in U.S. Hispanic Immigration Attitudes (2002-2023)",
    subtitle = "Survey-weighted means with 95% confidence intervals",
    caption = "Source: Pew Research Center National Survey of Latinos. Zero line represents population mean.",
    theme = theme(
      plot.title = element_text(size = 18, face = "bold", margin = margin(b = 10)),
      plot.subtitle = element_text(size = 14, color = "#4A4A4A", margin = margin(b = 20)),
      plot.caption = element_text(size = 10, color = "#6A6A6A", hjust = 0),
      plot.background = element_rect(fill = "white", color = NA)
    )
  )

ggsave("outputs/figure_v4_4_main_generation_trends.png", 
       p_main, width = 12, height = 10, dpi = 300, bg = "white")
cat("Created main generation trends visualization\n")

# =============================================================================
# 4. DISAGGREGATED SUB-VARIABLES
# =============================================================================

cat("\n3. CREATING DISAGGREGATED SUB-VARIABLES VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Select key variables
key_vars <- c("Support for Legalization", "DACA Support", 
              "Deportation Support", "Border Wall Support",
              "Border Security", "Deportation Worry")

p_disagg <- disaggregated_trends %>%
  filter(variable_label %in% key_vars) %>%
  mutate(
    variable_label = factor(variable_label, levels = key_vars),
    category_color = case_when(
      category == "Pro-Immigration" ~ "#2E7D32",
      category == "Restrictive" ~ "#C62828",
      category == "Concern" ~ "#F57C00",
      TRUE ~ "#757575"
    )
  ) %>%
  ggplot(aes(x = survey_year, y = mean_val, color = generation_label)) +
  
  # Zero reference line
  geom_hline(yintercept = 0, linetype = "dashed", color = "#666666", size = 0.4) +
  
  # Confidence intervals
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
              alpha = 0.1, color = NA) +
  
  # Lines and points
  geom_line(size = 1.2) +
  geom_point(size = 2, shape = 16) +
  
  # Faceting
  facet_wrap(~variable_label, ncol = 3, scales = "free_y") +
  
  # Scales
  scale_color_manual(values = generation_colors, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_colors, guide = "none") +
  scale_x_continuous(breaks = seq(2005, 2020, by = 5)) +
  
  # Labels
  labs(
    title = "Disaggregated Immigration Attitude Components",
    subtitle = "Individual sub-variables reveal heterogeneous patterns across generations",
    x = "Survey Year",
    y = "Standardized Score",
    caption = "Source: NSL data. Each panel shows a different attitude component. Note varying scales and year coverage."
  ) +
  
  theme_publication() +
  theme(
    strip.background = element_rect(fill = "#F0F0F0", color = "#CCCCCC"),
    strip.text = element_text(size = 11, face = "bold"),
    panel.spacing = unit(1, "lines")
  )

ggsave("outputs/figure_v4_4_disaggregated_components.png", 
       p_disagg, width = 14, height = 10, dpi = 300, bg = "white")
cat("Created disaggregated components visualization\n")

# =============================================================================
# 5. NET LIBERALISM TRENDS
# =============================================================================

cat("\n4. CREATING NET LIBERALISM VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate net liberalism
net_data <- generation_trends %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  mutate(
    net_liberalism = liberalism_mean - restrictionism_mean,
    net_se = sqrt(liberalism_se^2 + restrictionism_se^2),
    net_ci_lower = net_liberalism - 1.96 * net_se,
    net_ci_upper = net_liberalism + 1.96 * net_se
  )

p_net <- net_data %>%
  ggplot(aes(x = survey_year, y = net_liberalism, color = generation_label)) +
  
  # Zero line (important reference)
  geom_hline(yintercept = 0, linetype = "solid", color = "#333333", size = 0.8) +
  
  # Add shaded regions
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0, ymax = Inf,
           fill = "#2E7D32", alpha = 0.05) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = 0,
           fill = "#C62828", alpha = 0.05) +
  
  # Labels for regions
  annotate("text", x = 2012, y = 0.25, label = "Net Pro-Immigration", 
           size = 4.5, color = "#2E7D32", fontface = "italic") +
  annotate("text", x = 2012, y = -0.25, label = "Net Anti-Immigration", 
           size = 4.5, color = "#C62828", fontface = "italic") +
  
  # Confidence ribbons
  geom_ribbon(aes(ymin = net_ci_lower, ymax = net_ci_upper, fill = generation_label),
              alpha = 0.15, color = NA) +
  
  # Lines and points
  geom_line(size = 1.5) +
  geom_point(size = 3.5, shape = 16) +
  
  # Scales
  scale_color_manual(values = generation_colors, name = "Immigrant Generation") +
  scale_fill_manual(values = generation_colors, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2024, by = 4),
                     limits = c(2001, 2024)) +
  
  # Labels
  labs(
    title = "Net Immigration Policy Attitudes by Generation",
    subtitle = "Difference between liberalism and restrictionism indices (positive = net pro-immigration)",
    x = "Survey Year",
    y = "Net Liberalism Score",
    caption = "Source: NSL data. Calculated as liberalism index minus restrictionism index."
  ) +
  
  theme_publication()

ggsave("outputs/figure_v4_4_net_liberalism.png", 
       p_net, width = 11, height = 8, dpi = 300, bg = "white")
cat("Created net liberalism visualization\n")

# =============================================================================
# 6. PERIOD EFFECTS
# =============================================================================

cat("\n5. CREATING PERIOD EFFECTS VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare period data
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
               liberalism_se, restrictionism_se),
    period_short = case_when(
      period == "Early Bush Era" ~ "Early Bush\n(2002-04)",
      period == "Immigration Debates" ~ "Immigration\nDebates\n(2006-07)",
      period == "Economic Crisis" ~ "Economic\nCrisis\n(2008-10)",
      period == "Obama Era" ~ "Obama Era\n(2011-15)",
      period == "Trump Era" ~ "Trump Era\n(2016-18)",
      period == "COVID & Biden Era" ~ "COVID &\nBiden Era\n(2021-23)"
    )
  )

p_period <- period_data %>%
  ggplot(aes(x = period_short, y = value, fill = index_label)) +
  
  # Bars with dodging
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), 
           width = 0.7, color = "white", size = 0.5) +
  
  # Error bars
  geom_errorbar(aes(ymin = value - se, ymax = value + se),
                position = position_dodge(width = 0.8),
                width = 0.3, size = 0.8, color = "#333333") +
  
  # Zero line
  geom_hline(yintercept = 0, linetype = "solid", color = "#333333", size = 0.5) +
  
  # Scales
  scale_fill_manual(values = c("Liberalism" = "#2E7D32", 
                              "Restrictionism" = "#C62828"),
                   name = "Attitude Index") +
  
  # Labels
  labs(
    title = "Immigration Attitudes by Historical Period",
    subtitle = "Overall Hispanic population means with standard errors",
    x = "Historical Period",
    y = "Mean Standardized Score",
    caption = "Source: NSL data pooled by period. Error bars show ±1 standard error."
  ) +
  
  theme_publication() +
  theme(axis.text.x = element_text(size = 10))

ggsave("outputs/figure_v4_4_period_effects.png", 
       p_period, width = 10, height = 7, dpi = 300, bg = "white")
cat("Created period effects visualization\n")

# =============================================================================
# 7. GENERATION GAP OVER TIME
# =============================================================================

cat("\n6. CREATING GENERATION GAP VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate gaps
gap_data <- generation_trends %>%
  select(survey_year, generation_label, liberalism_mean, restrictionism_mean) %>%
  pivot_wider(
    names_from = generation_label,
    values_from = c(liberalism_mean, restrictionism_mean)
  ) %>%
  mutate(
    lib_gap_1st_3rd = `liberalism_mean_1st Generation` - `liberalism_mean_3rd+ Generation`,
    res_gap_1st_3rd = `restrictionism_mean_1st Generation` - `restrictionism_mean_3rd+ Generation`
  ) %>%
  filter(!is.na(lib_gap_1st_3rd) | !is.na(res_gap_1st_3rd)) %>%
  pivot_longer(
    cols = c(lib_gap_1st_3rd, res_gap_1st_3rd),
    names_to = "gap_type",
    values_to = "gap_value"
  ) %>%
  mutate(
    gap_label = ifelse(gap_type == "lib_gap_1st_3rd",
                      "Liberalism Gap", "Restrictionism Gap")
  )

p_gap <- gap_data %>%
  filter(!is.na(gap_value)) %>%
  ggplot(aes(x = survey_year, y = gap_value, color = gap_label, fill = gap_label)) +
  
  # Zero line
  geom_hline(yintercept = 0, linetype = "solid", color = "#333333", size = 0.8) +
  
  # Areas
  geom_area(alpha = 0.3, position = "identity") +
  
  # Lines
  geom_line(size = 1.5) +
  geom_point(size = 3, shape = 16) +
  
  # Scales
  scale_color_manual(values = c("Liberalism Gap" = "#2E7D32",
                               "Restrictionism Gap" = "#C62828"),
                    name = "Attitude Dimension") +
  scale_fill_manual(values = c("Liberalism Gap" = "#2E7D32",
                              "Restrictionism Gap" = "#C62828"),
                   guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2024, by = 4),
                     limits = c(2001, 2024)) +
  
  # Annotations
  annotate("text", x = 2012, y = 0.05, label = "1st Gen More Liberal/Restrictive", 
           size = 3.5, color = "#666666", fontface = "italic") +
  annotate("text", x = 2012, y = -0.05, label = "3rd+ Gen More Liberal/Restrictive", 
           size = 3.5, color = "#666666", fontface = "italic") +
  
  # Labels
  labs(
    title = "The Generation Gap: First vs Third+ Generation Differences",
    subtitle = "Positive values indicate first generation holds stronger attitudes than third+ generation",
    x = "Survey Year",
    y = "Attitude Difference\n(1st Gen − 3rd+ Gen)",
    caption = "Source: NSL data. Shows the gap between foreign-born and third+ generation Hispanics."
  ) +
  
  theme_publication()

ggsave("outputs/figure_v4_4_generation_gap.png", 
       p_gap, width = 11, height = 7, dpi = 300, bg = "white")
cat("Created generation gap visualization\n")

# =============================================================================
# 8. SUMMARY
# =============================================================================

cat("\n7. VISUALIZATION CREATION COMPLETE\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
cat("All visualizations created with consistent styling:\n")
cat("- White backgrounds\n")
cat("- Professional color scheme\n") 
cat("- Consistent fonts and sizes\n")
cat("- Publication-quality output (300 DPI)\n")
cat("\nFiles created:\n")
cat("- figure_v4_4_main_generation_trends.png\n")
cat("- figure_v4_4_disaggregated_components.png\n")
cat("- figure_v4_4_net_liberalism.png\n")
cat("- figure_v4_4_period_effects.png\n")
cat("- figure_v4_4_generation_gap.png\n")

# =============================================================================
# END OF PUBLICATION QUALITY VISUALIZATIONS v4.4
# =============================================================================