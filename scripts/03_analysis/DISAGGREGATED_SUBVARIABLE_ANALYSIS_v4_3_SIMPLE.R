# =============================================================================
# DISAGGREGATED SUB-VARIABLE ANALYSIS v4.3 - SIMPLIFIED VERSION
# =============================================================================
# Purpose: Analyze and visualize each immigration attitude sub-variable separately
# Version: 4.3 Simplified
# Date: January 2025
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(purrr)
library(stringr)
library(scales)
library(patchwork)

cat("=============================================================\n")
cat("DISAGGREGATED SUB-VARIABLE ANALYSIS v4.3 - SIMPLIFIED\n")
cat("=============================================================\n")

# =============================================================================
# 1. DATA LOADING AND PREPARATION
# =============================================================================

cat("\n1. LOADING DATA AND PREPARING SUB-VARIABLES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load data
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", 
                 show_col_types = FALSE)

# Add generation labels
data <- data %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation"
    )
  )

# Define sub-variables with clear labels
sub_vars <- list(
  # Liberalism components
  "legalization_support_std" = "Support for Legalization",
  "daca_support_std" = "DACA Support",
  # Restrictionism components  
  "immigration_level_opinion_std" = "Reduce Immigration Levels",
  "border_wall_support_std" = "Border Wall Support",
  "deportation_policy_support_std" = "Deportation Support",
  "border_security_support_std" = "Border Security",
  "immigration_importance_std" = "Immigration as Top Issue",
  # Concern
  "deportation_worry_std" = "Deportation Worry"
)

# Check which are available
available_vars <- names(sub_vars)[names(sub_vars) %in% names(data)]
cat("\nAvailable standardized variables:", length(available_vars), "\n")

# =============================================================================
# 2. CALCULATE TRENDS FOR EACH SUB-VARIABLE
# =============================================================================

cat("\n2. CALCULATING TRENDS BY GENERATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Function to get trends for one variable
get_var_trends <- function(var_name, var_label) {
  data %>%
    filter(!is.na(generation_label), !is.na(!!sym(var_name))) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      n = n(),
      mean_val = mean(!!sym(var_name), na.rm = TRUE),
      se_val = sd(!!sym(var_name), na.rm = TRUE) / sqrt(n),
      .groups = "drop"
    ) %>%
    filter(n >= 30) %>%
    mutate(
      variable = var_name,
      variable_label = var_label,
      ci_lower = mean_val - 1.96 * se_val,
      ci_upper = mean_val + 1.96 * se_val
    )
}

# Get trends for all variables
all_trends <- map2_dfr(available_vars, sub_vars[available_vars], get_var_trends)

# Check coverage
coverage <- all_trends %>%
  group_by(variable_label) %>%
  summarise(
    years = n_distinct(survey_year),
    total_n = sum(n),
    .groups = "drop"
  ) %>%
  arrange(desc(years))

cat("\nVariable coverage:\n")
print(coverage)

# =============================================================================
# 3. CATEGORIZE VARIABLES
# =============================================================================

# Add categories
all_trends <- all_trends %>%
  mutate(
    category = case_when(
      variable %in% c("legalization_support_std", "daca_support_std") ~ "Pro-Immigration",
      variable %in% c("border_wall_support_std", "deportation_policy_support_std", 
                     "border_security_support_std", "immigration_level_opinion_std",
                     "immigration_importance_std") ~ "Restrictive",
      variable == "deportation_worry_std" ~ "Concern",
      TRUE ~ "Other"
    )
  )

# =============================================================================
# 4. VISUALIZATION SETUP
# =============================================================================

# Theme
theme_v43 <- theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "bottom",
    strip.text = element_text(face = "bold"),
    panel.spacing = unit(1, "lines")
  )

# Colors
gen_colors <- c(
  "1st Generation" = "#E41A1C",
  "2nd Generation" = "#377EB8",
  "3rd+ Generation" = "#4DAF4A"
)

# =============================================================================
# 5. CREATE VISUALIZATIONS
# =============================================================================

cat("\n3. CREATING VISUALIZATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# 5.1 Small multiples for all variables
p_all <- all_trends %>%
  ggplot(aes(x = survey_year, y = mean_val, color = generation_label)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
              alpha = 0.2, linetype = 0) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.5) +
  facet_wrap(~variable_label, scales = "free_y", ncol = 3) +
  scale_color_manual(values = gen_colors, name = "Generation") +
  scale_fill_manual(values = gen_colors, guide = "none") +
  scale_x_continuous(breaks = seq(2000, 2025, by = 10)) +
  labs(
    title = "Disaggregated Immigration Attitudes by Component",
    subtitle = "Each sub-variable shows distinct patterns across generations",
    x = "Survey Year",
    y = "Standardized Score"
  ) +
  theme_v43

ggsave("outputs/figure_v4_3_all_subvariables.png", 
       p_all, width = 14, height = 10, dpi = 300)
cat("Created all sub-variables visualization\n")

# 5.2 Grouped by category
p_category <- all_trends %>%
  filter(category != "Other") %>%
  ggplot(aes(x = survey_year, y = mean_val, color = generation_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2) +
  facet_grid(category ~ variable_label, scales = "free_y") +
  scale_color_manual(values = gen_colors, name = "Generation") +
  labs(
    title = "Immigration Attitudes: Pro-Immigration vs Restrictive Components",
    subtitle = "Components grouped by conceptual category",
    x = "Survey Year",
    y = "Standardized Score"
  ) +
  theme_v43 +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/figure_v4_3_by_category.png", 
       p_category, width = 14, height = 8, dpi = 300)
cat("Created category-grouped visualization\n")

# 5.3 Focus on key contrasts
key_vars <- c("legalization_support_std", "deportation_policy_support_std", 
              "border_wall_support_std", "deportation_worry_std")

if(all(key_vars %in% available_vars)) {
  p_key <- all_trends %>%
    filter(variable %in% key_vars) %>%
    ggplot(aes(x = survey_year, y = mean_val)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_line(aes(color = generation_label), linewidth = 1.5) +
    geom_point(aes(color = generation_label), size = 2.5) +
    facet_wrap(~variable_label, ncol = 2) +
    scale_color_manual(values = gen_colors, name = "Generation") +
    labs(
      title = "Key Immigration Attitude Components",
      subtitle = "Contrasting pro-immigration and enforcement attitudes",
      x = "Survey Year",
      y = "Standardized Score",
      caption = "Zero line represents population mean"
    ) +
    theme_v43
  
  ggsave("outputs/figure_v4_3_key_contrasts.png", 
         p_key, width = 10, height = 8, dpi = 300)
  cat("Created key contrasts visualization\n")
}

# =============================================================================
# 6. ANALYZE HETEROGENEITY
# =============================================================================

cat("\n4. ANALYZING HETEROGENEITY\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate spread within categories
heterogeneity <- all_trends %>%
  filter(category %in% c("Pro-Immigration", "Restrictive")) %>%
  group_by(survey_year, generation_label, category) %>%
  summarise(
    n_vars = n_distinct(variable),
    mean_score = mean(mean_val),
    sd_score = sd(mean_val),
    min_score = min(mean_val),
    max_score = max(mean_val),
    range_score = max_score - min_score,
    .groups = "drop"
  )

# Visualize heterogeneity
p_hetero <- heterogeneity %>%
  filter(n_vars > 1) %>%
  ggplot(aes(x = survey_year, y = range_score, color = generation_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  facet_wrap(~category) +
  scale_color_manual(values = gen_colors, name = "Generation") +
  labs(
    title = "Within-Category Heterogeneity Over Time",
    subtitle = "Range of scores shows consistency within attitude categories",
    x = "Survey Year",
    y = "Range of Component Scores",
    caption = "Larger values indicate more disagreement between components"
  ) +
  theme_v43

ggsave("outputs/figure_v4_3_heterogeneity.png", 
       p_hetero, width = 10, height = 6, dpi = 300)
cat("Created heterogeneity visualization\n")

# =============================================================================
# 7. IDENTIFY DIVERGENT PATTERNS
# =============================================================================

cat("\n5. IDENTIFYING DIVERGENT PATTERNS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Find variables where 1st and 3rd generation move in opposite directions
divergence_check <- all_trends %>%
  filter(generation_label %in% c("1st Generation", "3rd+ Generation")) %>%
  group_by(variable_label, survey_year) %>%
  summarise(
    gen1_val = mean_val[generation_label == "1st Generation"][1],
    gen3_val = mean_val[generation_label == "3rd+ Generation"][1],
    diff = gen1_val - gen3_val,
    .groups = "drop"
  ) %>%
  group_by(variable_label) %>%
  summarise(
    mean_diff = mean(diff, na.rm = TRUE),
    changing_sign = any(diff > 0, na.rm = TRUE) & any(diff < 0, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nVariables with divergent generational patterns:\n")
print(divergence_check %>% filter(changing_sign))

# =============================================================================
# 8. SUMMARY STATISTICS
# =============================================================================

cat("\n6. SUMMARY STATISTICS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Overall patterns by variable
summary_stats <- all_trends %>%
  group_by(variable_label, generation_label) %>%
  summarise(
    years = n(),
    mean_overall = mean(mean_val),
    trend = ifelse(last(mean_val) > first(mean_val), "↑", "↓"),
    change = last(mean_val) - first(mean_val),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = generation_label,
    values_from = c(mean_overall, trend, change),
    names_glue = "{generation_label}_{.value}"
  )

cat("\nSummary of trends by variable:\n")
print(summary_stats %>% select(variable_label, contains("trend")))

# =============================================================================
# 9. SAVE OUTPUTS
# =============================================================================

cat("\n7. SAVING RESULTS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Save data
write_csv(all_trends, "outputs/disaggregated_trends_v4_3.csv")
write_csv(heterogeneity, "outputs/heterogeneity_by_category_v4_3.csv")
write_csv(divergence_check, "outputs/divergence_analysis_v4_3.csv")

# Save workspace
save.image("outputs/disaggregated_analysis_v4_3_workspace.RData")

cat("\nAnalysis complete!\n")
cat("Key findings:\n")
cat("- Analyzed", length(available_vars), "sub-variables\n")
cat("- Created visualizations showing heterogeneity within indices\n")
cat("- Identified patterns of convergence and divergence\n")

# =============================================================================
# END OF DISAGGREGATED ANALYSIS v4.3
# =============================================================================