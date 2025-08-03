# =============================================================================
# DISAGGREGATED SUB-VARIABLE ANALYSIS v4.3
# =============================================================================
# Purpose: Analyze and visualize each immigration attitude sub-variable separately
#          to understand heterogeneity within indices and validate aggregate patterns
# Version: 4.3
# Date: January 2025
# Note: Builds on v4.2 - for validation and deeper understanding
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(purrr)
library(stringr)
library(scales)
library(patchwork)
library(viridis)

cat("=============================================================\n")
cat("DISAGGREGATED SUB-VARIABLE ANALYSIS v4.3\n")
cat("=============================================================\n")

# =============================================================================
# 1. DATA LOADING AND PREPARATION
# =============================================================================

cat("\n1. LOADING DATA AND PREPARING SUB-VARIABLES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load the comprehensive dataset
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", 
                 show_col_types = FALSE)

# Add generation labels
data <- data %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation"
    ),
    generation_label = factor(generation_label,
                             levels = c("1st Generation", "2nd Generation", "3rd+ Generation"))
  )

# Define sub-variables by index category
liberalism_vars <- c(
  "legalization_support" = "Support for Legalization",
  "daca_support" = "DACA Support",
  "immigrants_strengthen" = "Immigrants Strengthen Country"
)

restrictionism_vars <- c(
  "immigration_level_opinion" = "Reduce Immigration Levels",
  "border_wall_support" = "Border Wall Support",
  "deportation_policy_support" = "Deportation Policy Support",
  "border_security_support" = "Border Security Support",
  "immigration_importance" = "Immigration as Important Issue"
)

concern_vars <- c(
  "deportation_worry" = "Deportation Worry"
)

all_vars <- c(liberalism_vars, restrictionism_vars, concern_vars)

# Check which variables are actually available
available_vars <- names(all_vars)[names(all_vars) %in% names(data)]
cat("\nAvailable sub-variables:", length(available_vars), "out of", length(all_vars), "\n")
cat(paste("-", available_vars, collapse = "\n"), "\n")

# =============================================================================
# 2. CALCULATE TRENDS FOR EACH SUB-VARIABLE
# =============================================================================

cat("\n2. CALCULATING GENERATION TRENDS FOR EACH SUB-VARIABLE\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Function to calculate generation trends for a single variable
calc_single_var_trends <- function(data, var_name, var_label) {
  # Use standardized version if available
  std_var <- paste0(var_name, "_std")
  use_var <- ifelse(std_var %in% names(data), std_var, var_name)
  
  trends <- data %>%
    filter(!is.na(generation_label), !is.na(!!sym(use_var))) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      n = n(),
      mean_val = mean(!!sym(use_var), na.rm = TRUE),
      se_val = sd(!!sym(use_var), na.rm = TRUE) / sqrt(n),
      ci_lower = mean_val - 1.96 * se_val,
      ci_upper = mean_val + 1.96 * se_val,
      .groups = "drop"
    ) %>%
    filter(n >= 30) %>%
    mutate(
      variable = var_name,
      variable_label = var_label,
      standardized = grepl("_std", use_var)
    )
  
  return(trends)
}

# Calculate trends for all available variables
all_trends <- map2_dfr(
  available_vars,
  all_vars[available_vars],
  ~calc_single_var_trends(data, .x, .y)
)

# Add category labels
all_trends <- all_trends %>%
  mutate(
    category = case_when(
      variable %in% names(liberalism_vars) ~ "Liberalism Components",
      variable %in% names(restrictionism_vars) ~ "Restrictionism Components",
      variable %in% names(concern_vars) ~ "Concern",
      TRUE ~ "Other"
    )
  )

# Summary of data availability
coverage_summary <- all_trends %>%
  group_by(variable, variable_label) %>%
  summarise(
    years_available = n_distinct(survey_year),
    total_obs = sum(n),
    .groups = "drop"
  ) %>%
  arrange(desc(years_available))

cat("\nData coverage by sub-variable:\n")
print(coverage_summary)

# =============================================================================
# 3. STATISTICAL ANALYSIS OF SUB-VARIABLES
# =============================================================================

cat("\n3. ANALYZING PATTERNS IN SUB-VARIABLES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Function to run trend regression for each generation
analyze_subvar_trends <- function(trends_data, var_name) {
  results <- trends_data %>%
    filter(variable == var_name) %>%
    group_by(generation_label) %>%
    filter(n() >= 3) %>%  # Need at least 3 time points
    do({
      # Check if we have valid data
      if(nrow(.) < 3 || all(is.na(.$mean_val))) {
        return(data.frame())
      }
      
      tryCatch({
        model <- lm(mean_val ~ survey_year, data = .)
        tidy_model <- broom::tidy(model)
        slope_data <- tidy_model %>%
          filter(term == "survey_year") %>%
          select(estimate, p.value)
        
        if(nrow(slope_data) == 0) {
          return(data.frame())
        }
        
        data.frame(
          variable = var_name,
          generation = .$generation_label[1],
          slope = slope_data$estimate,
          p_value = slope_data$p.value,
          direction = ifelse(slope_data$estimate > 0, "Increasing", "Decreasing"),
          significance = case_when(
            slope_data$p.value < 0.001 ~ "***",
            slope_data$p.value < 0.01 ~ "**",
            slope_data$p.value < 0.05 ~ "*",
            TRUE ~ "ns"
          ),
          n_years = nrow(.)
        )
      }, error = function(e) {
        return(data.frame())
      })
    }) %>%
    ungroup()
  
  return(results)
}

# Analyze trends for each variable
trend_results <- map_dfr(available_vars, ~analyze_subvar_trends(all_trends, .x))

cat("\nTrend analysis results by variable and generation:\n")
print(trend_results %>% 
      arrange(variable, generation) %>%
      select(variable, generation, slope, p_value, significance, direction))

# =============================================================================
# 4. THEME AND COLOR SETUP FOR VISUALIZATIONS
# =============================================================================

# Publication theme
theme_v43 <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(size = 13, face = "bold", margin = margin(b = 5)),
    plot.subtitle = element_text(size = 10, color = "gray40", margin = margin(b = 10)),
    plot.caption = element_text(size = 8, color = "gray50", hjust = 0),
    axis.title = element_text(size = 10, face = "bold"),
    axis.text = element_text(size = 9),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 9),
    legend.position = "bottom",
    strip.text = element_text(size = 10, face = "bold"),
    strip.background = element_rect(fill = "gray95", color = NA),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(1, "lines")
  )

# Color palette
gen_colors <- c(
  "1st Generation" = "#E41A1C",
  "2nd Generation" = "#377EB8",
  "3rd+ Generation" = "#4DAF4A"
)

# =============================================================================
# 5. VISUALIZATION 1: SMALL MULTIPLES BY CATEGORY
# =============================================================================

cat("\n5. CREATING DISAGGREGATED VISUALIZATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create small multiples for liberalism components
if(any(all_trends$category == "Liberalism Components")) {
  p_lib_components <- all_trends %>%
    filter(category == "Liberalism Components") %>%
    ggplot(aes(x = survey_year, y = mean_val, color = generation_label)) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
                alpha = 0.2, linetype = 0) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 2) +
    facet_wrap(~variable_label, scales = "free_y", ncol = 2) +
    scale_color_manual(values = gen_colors, name = "Generation") +
    scale_fill_manual(values = gen_colors, guide = "none") +
    scale_x_continuous(breaks = seq(2000, 2025, by = 5)) +
    labs(
      title = "Liberalism Components: Disaggregated Trends",
      subtitle = "Each component shows different patterns across generations",
      x = "Survey Year",
      y = "Standardized Score",
      caption = "Note: Different components have different year coverage. 95% confidence intervals shown."
    ) +
    theme_v43
  
  ggsave("outputs/figure_v4_3_liberalism_components.png", 
         p_lib_components, width = 12, height = 8, dpi = 300)
  cat("Created liberalism components visualization\n")
}

# Create small multiples for restrictionism components
if(any(all_trends$category == "Restrictionism Components")) {
  p_res_components <- all_trends %>%
    filter(category == "Restrictionism Components") %>%
    ggplot(aes(x = survey_year, y = mean_val, color = generation_label)) +
    geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
                alpha = 0.2, linetype = 0) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 2) +
    facet_wrap(~variable_label, scales = "free_y", ncol = 2) +
    scale_color_manual(values = gen_colors, name = "Generation") +
    scale_fill_manual(values = gen_colors, guide = "none") +
    scale_x_continuous(breaks = seq(2000, 2025, by = 5)) +
    labs(
      title = "Restrictionism Components: Disaggregated Trends",
      subtitle = "Components show varying patterns and some surprising relationships",
      x = "Survey Year",
      y = "Standardized Score",
      caption = "Note: Higher values indicate more restrictive attitudes. 95% confidence intervals shown."
    ) +
    theme_v43
  
  ggsave("outputs/figure_v4_3_restrictionism_components.png", 
         p_res_components, width = 12, height = 10, dpi = 300)
  cat("Created restrictionism components visualization\n")
}

# =============================================================================
# 6. VISUALIZATION 2: COMPONENT COMPARISON
# =============================================================================

cat("\n6. CREATING COMPONENT COMPARISON VISUALIZATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Select key variables with good coverage for direct comparison
key_vars <- c("legalization_support", "deportation_policy_support", 
              "border_security_support", "deportation_worry")
key_vars_available <- intersect(key_vars, available_vars)

if(length(key_vars_available) >= 2) {
  # Create comparison plot
  p_comparison <- all_trends %>%
    filter(variable %in% key_vars_available) %>%
    ggplot(aes(x = survey_year, y = mean_val)) +
    geom_line(aes(color = generation_label), linewidth = 1.2) +
    geom_point(aes(color = generation_label), size = 2) +
    facet_grid(variable_label ~ generation_label, scales = "free_y") +
    scale_color_manual(values = gen_colors, guide = "none") +
    scale_x_continuous(breaks = seq(2000, 2025, by = 5)) +
    labs(
      title = "Key Immigration Attitudes Across Generations",
      subtitle = "Comparing different attitude dimensions side by side",
      x = "Survey Year",
      y = "Standardized Score",
      caption = "Each row represents a different attitude measure. Scales vary by measure."
    ) +
    theme_v43 +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave("outputs/figure_v4_3_component_comparison.png",
         p_comparison, width = 12, height = 10, dpi = 300)
  cat("Created component comparison visualization\n")
}

# =============================================================================
# 7. VISUALIZATION 3: HETEROGENEITY WITHIN INDICES
# =============================================================================

cat("\n7. ANALYZING HETEROGENEITY WITHIN INDICES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate variance across components within each category
heterogeneity_data <- all_trends %>%
  group_by(survey_year, generation_label, category) %>%
  summarise(
    n_components = n(),
    mean_across_components = mean(mean_val, na.rm = TRUE),
    sd_across_components = sd(mean_val, na.rm = TRUE),
    min_val = min(mean_val, na.rm = TRUE),
    max_val = max(mean_val, na.rm = TRUE),
    range_val = max_val - min_val,
    .groups = "drop"
  ) %>%
  filter(n_components >= 2)  # Need at least 2 components

# Create heterogeneity plot
if(nrow(heterogeneity_data) > 0) {
  p_heterogeneity <- heterogeneity_data %>%
    ggplot(aes(x = survey_year, y = range_val, color = generation_label)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 2.5) +
    facet_wrap(~category, scales = "free_y") +
    scale_color_manual(values = gen_colors, name = "Generation") +
    labs(
      title = "Within-Index Heterogeneity Over Time",
      subtitle = "Range of scores across components shows internal consistency",
      x = "Survey Year",
      y = "Range of Component Scores",
      caption = "Larger values indicate more heterogeneity within index components."
    ) +
    theme_v43
  
  ggsave("outputs/figure_v4_3_heterogeneity.png",
         p_heterogeneity, width = 10, height = 6, dpi = 300)
  cat("Created heterogeneity visualization\n")
}

# =============================================================================
# 8. VISUALIZATION 4: DIVERGENT PATTERNS
# =============================================================================

cat("\n8. IDENTIFYING DIVERGENT PATTERNS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Identify variables that show different patterns than expected
# Focus on variables where generations show opposite trends
divergent_vars <- trend_results %>%
  group_by(variable) %>%
  summarise(
    directions = n_distinct(direction),
    has_significant = any(significance != "ns"),
    .groups = "drop"
  ) %>%
  filter(directions > 1 | has_significant)

cat("\nVariables showing divergent or significant patterns:\n")
print(divergent_vars)

# Create focused plot on divergent variables
if(nrow(divergent_vars) > 0) {
  divergent_var_names <- divergent_vars$variable[1:min(4, nrow(divergent_vars))]
  
  p_divergent <- all_trends %>%
    filter(variable %in% divergent_var_names) %>%
    ggplot(aes(x = survey_year, y = mean_val, color = generation_label)) +
    geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.8) +
    geom_line(linewidth = 1.5) +
    geom_point(size = 3) +
    facet_wrap(~variable_label, scales = "free_y") +
    scale_color_manual(values = gen_colors, name = "Generation") +
    labs(
      title = "Variables Showing Divergent Generational Patterns",
      subtitle = "These attitudes don't follow the expected aggregate pattern",
      x = "Survey Year",
      y = "Standardized Score",
      caption = "Dashed lines show linear trends. These variables show the most heterogeneity."
    ) +
    theme_v43
  
  ggsave("outputs/figure_v4_3_divergent_patterns.png",
         p_divergent, width = 10, height = 8, dpi = 300)
  cat("Created divergent patterns visualization\n")
}

# =============================================================================
# 9. ANALYSIS SUMMARY
# =============================================================================

cat("\n9. SUMMARY OF DISAGGREGATED ANALYSIS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Component contribution analysis
contribution_summary <- trend_results %>%
  group_by(category = case_when(
    variable %in% names(liberalism_vars) ~ "Liberalism",
    variable %in% names(restrictionism_vars) ~ "Restrictionism",
    TRUE ~ "Other"
  )) %>%
  summarise(
    n_increasing = sum(direction == "Increasing"),
    n_decreasing = sum(direction == "Decreasing"),
    n_significant = sum(significance != "ns"),
    avg_abs_slope = mean(abs(slope)),
    .groups = "drop"
  )

cat("\nSummary by index category:\n")
print(contribution_summary)

# Identify key drivers
key_drivers <- trend_results %>%
  filter(significance != "ns") %>%
  arrange(desc(abs(slope))) %>%
  select(variable, generation, slope, significance, direction)

cat("\nKey drivers (significant trends):\n")
if(nrow(key_drivers) > 0) {
  print(key_drivers)
} else {
  cat("No statistically significant trends found at p < 0.05\n")
}

# =============================================================================
# 10. SAVE RESULTS AND CREATE SUMMARY REPORT
# =============================================================================

cat("\n10. SAVING RESULTS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Save detailed results
write_csv(all_trends, "outputs/disaggregated_trends_v4_3.csv")
write_csv(trend_results, "outputs/disaggregated_trend_analysis_v4_3.csv")
write_csv(heterogeneity_data, "outputs/heterogeneity_analysis_v4_3.csv")

# Create summary report
summary_report <- list(
  total_variables = length(all_vars),
  available_variables = length(available_vars),
  coverage_summary = coverage_summary,
  trend_results = trend_results,
  contribution_summary = contribution_summary,
  key_drivers = key_drivers,
  divergent_patterns = divergent_vars
)

saveRDS(summary_report, "outputs/disaggregated_analysis_summary_v4_3.rds")

cat("\nAnalysis complete! Key findings:\n")
cat("1. Analyzed", length(available_vars), "sub-variables separately\n")
cat("2. Found", nrow(key_drivers), "statistically significant trends\n")
cat("3. Identified", nrow(divergent_vars), "variables with divergent patterns\n")
cat("4. Created visualizations showing heterogeneity within indices\n")

# Save workspace
save.image("outputs/disaggregated_analysis_v4_3_workspace.RData")

cat("\nAll outputs saved to outputs/ directory\n")

# =============================================================================
# END OF DISAGGREGATED SUB-VARIABLE ANALYSIS v4.3
# =============================================================================