# ============================================================================
# LONGITUDINAL ANALYSIS v2.4: COMPREHENSIVE IMMIGRATION ATTITUDES ANALYSIS
# ============================================================================
# Purpose: Conduct longitudinal analysis of three thematic indices across
#          immigrant generations AND for all Hispanic respondents using our
#          clean v2.4 dataset. Includes weighted regression and visualizations.
# Version: 2.4
# Date: Current analysis session
# Data: COMPLETE_LONGITUDINAL_DATASET_v2_4.csv
# ============================================================================

library(haven)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(stringr)
library(ggplot2)
library(viridis)
library(forcats)
library(broom)
library(survey)
library(scales)

cat("=== LONGITUDINAL ANALYSIS v2.4 ===\n")

# ============================================================================
# LOAD AND PREPARE DATA
# ============================================================================

# Load the complete clean dataset
data <- read_csv("data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv")

cat(sprintf("Loaded dataset: %d observations across %d years\n", 
            nrow(data), length(unique(data$survey_year))))

# Create generation labels
data <- data %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation\n(Foreign-born)",
      immigrant_generation == 2 ~ "2nd Generation\n(US-born, foreign parents)",  
      immigrant_generation == 3 ~ "3rd+ Generation\n(US-born, US-born parents)",
      TRUE ~ "Unknown Generation"
    ),
    generation_label = factor(generation_label, levels = c(
      "1st Generation\n(Foreign-born)",
      "2nd Generation\n(US-born, foreign parents)",
      "3rd+ Generation\n(US-born, US-born parents)"
    ))
  )

# ============================================================================
# DATA PREPARATION FOR ANALYSIS
# ============================================================================

# Prepare analysis dataset with valid indices
analysis_data <- data %>%
  filter(!is.na(liberalism_index) | !is.na(restrictionism_index) | !is.na(concern_index)) %>%
  mutate(
    # Add uniform weights for now (can be replaced with actual survey weights)
    weight = 1.0
  )

cat(sprintf("Analysis dataset: %d observations with valid indices\n", nrow(analysis_data)))

# Summary of data coverage
coverage_by_year_gen <- analysis_data %>%
  group_by(survey_year, generation_label) %>%
  summarize(
    n_respondents = n(),
    liberalism_n = sum(!is.na(liberalism_index)),
    restrictionism_n = sum(!is.na(restrictionism_index)),
    concern_n = sum(!is.na(concern_index)),
    .groups = "drop"
  ) %>%
  filter(!is.na(generation_label))

print("=== Coverage by Year and Generation ===")
print(coverage_by_year_gen)

# ============================================================================
# WEIGHTED DESCRIPTIVE STATISTICS
# ============================================================================

# Function to calculate weighted means and CIs
calculate_weighted_stats <- function(data, group_vars, index_name) {
  data %>%
    filter(!is.na(.data[[index_name]])) %>%
    group_by(across(all_of(group_vars))) %>%
    summarize(
      n = n(),
      mean_value = weighted.mean(.data[[index_name]], weight, na.rm = TRUE),
      se = sqrt(sum(weight * (.data[[index_name]] - mean_value)^2, na.rm = TRUE) / 
                (sum(weight, na.rm = TRUE) * (n() - 1))),
      ci_lower = mean_value - 1.96 * se,
      ci_upper = mean_value + 1.96 * se,
      .groups = "drop"
    ) %>%
    mutate(index = index_name)
}

# Calculate stats by generation
stats_by_generation <- bind_rows(
  calculate_weighted_stats(analysis_data, c("survey_year", "generation_label"), "liberalism_index"),
  calculate_weighted_stats(analysis_data, c("survey_year", "generation_label"), "restrictionism_index"),
  calculate_weighted_stats(analysis_data, c("survey_year", "generation_label"), "concern_index")
) %>%
  filter(!is.na(generation_label))

# Calculate stats for all Hispanic respondents
stats_all_hispanic <- bind_rows(
  calculate_weighted_stats(analysis_data, "survey_year", "liberalism_index"),
  calculate_weighted_stats(analysis_data, "survey_year", "restrictionism_index"),
  calculate_weighted_stats(analysis_data, "survey_year", "concern_index")
) %>%
  mutate(generation_label = "All Hispanic\nRespondents")

# Combine datasets
all_stats <- bind_rows(stats_by_generation, stats_all_hispanic)

# ============================================================================
# WEIGHTED REGRESSION ANALYSIS
# ============================================================================

# Function to run weighted regression analysis
run_weighted_regression <- function(data, index_name, group_var = NULL) {
  if (!is.null(group_var)) {
    # Analysis by groups (e.g., generation)
    data %>%
      filter(!is.na(.data[[index_name]]) & !is.na(.data[[group_var]])) %>%
      group_by(.data[[group_var]]) %>%
      do({
        if (nrow(.) > 5 && length(unique(.$survey_year)) > 2) {
          # Create survey design
          design <- svydesign(ids = ~1, weights = ~weight, data = .)
          
          # Run regression
          model <- svyglm(as.formula(paste(index_name, "~ survey_year")), design = design)
          
          # Extract results
          coef_summary <- summary(model)$coefficients
          if (nrow(coef_summary) >= 2) {
            tibble(
              slope = coef_summary[2, 1],
              se = coef_summary[2, 2],
              t_value = coef_summary[2, 3],
              p_value = coef_summary[2, 4],
              ci_lower = slope - 1.96 * se,
              ci_upper = slope + 1.96 * se,
              n_years = length(unique(.$survey_year)),
              n_obs = nrow(.)
            )
          } else {
            tibble(slope = NA, se = NA, t_value = NA, p_value = NA, 
                   ci_lower = NA, ci_upper = NA, n_years = NA, n_obs = nrow(.))
          }
        } else {
          tibble(slope = NA, se = NA, t_value = NA, p_value = NA,
                 ci_lower = NA, ci_upper = NA, n_years = NA, n_obs = nrow(.))
        }
      }) %>%
      ungroup() %>%
      mutate(index = index_name)
  } else {
    # Analysis for all respondents
    filtered_data <- data %>% filter(!is.na(.data[[index_name]]))
    
    if (nrow(filtered_data) > 5 && length(unique(filtered_data$survey_year)) > 2) {
      # Create survey design
      design <- svydesign(ids = ~1, weights = ~weight, data = filtered_data)
      
      # Run regression
      model <- svyglm(as.formula(paste(index_name, "~ survey_year")), design = design)
      
      # Extract results
      coef_summary <- summary(model)$coefficients
      if (nrow(coef_summary) >= 2) {
        tibble(
          slope = coef_summary[2, 1],
          se = coef_summary[2, 2],
          t_value = coef_summary[2, 3],
          p_value = coef_summary[2, 4],
          ci_lower = slope - 1.96 * se,
          ci_upper = slope + 1.96 * se,
          n_years = length(unique(filtered_data$survey_year)),
          n_obs = nrow(filtered_data),
          group = "All Hispanic Respondents",
          index = index_name
        )
      } else {
        tibble(slope = NA, se = NA, t_value = NA, p_value = NA,
               ci_lower = NA, ci_upper = NA, n_years = NA, n_obs = nrow(filtered_data),
               group = "All Hispanic Respondents", index = index_name)
      }
    } else {
      tibble(slope = NA, se = NA, t_value = NA, p_value = NA,
             ci_lower = NA, ci_upper = NA, n_years = NA, n_obs = nrow(filtered_data),
             group = "All Hispanic Respondents", index = index_name)
    }
  }
}

# Run regression analyses
cat("Running weighted regression analyses...\n")

# By generation
regression_by_generation <- bind_rows(
  run_weighted_regression(analysis_data, "liberalism_index", "generation_label"),
  run_weighted_regression(analysis_data, "restrictionism_index", "generation_label"),
  run_weighted_regression(analysis_data, "concern_index", "generation_label")
) %>%
  filter(!is.na(generation_label))

# For all Hispanic respondents
regression_all_hispanic <- bind_rows(
  run_weighted_regression(analysis_data, "liberalism_index"),
  run_weighted_regression(analysis_data, "restrictionism_index"),
  run_weighted_regression(analysis_data, "concern_index")
)

# Combine regression results
all_regression_results <- bind_rows(
  regression_by_generation %>% rename(group = generation_label),
  regression_all_hispanic
)

print("=== Regression Results ===")
print(all_regression_results)

# ============================================================================
# VISUALIZATION 1: TREND LINES WITH CONFIDENCE INTERVALS
# ============================================================================

# Create index labels
all_stats <- all_stats %>%
  mutate(
    index_label = case_when(
      index == "liberalism_index" ~ "Immigration Policy Liberalism",
      index == "restrictionism_index" ~ "Immigration Policy Restrictionism", 
      index == "concern_index" ~ "Deportation Concern",
      TRUE ~ index
    ),
    index_label = factor(index_label, levels = c(
      "Immigration Policy Liberalism",
      "Immigration Policy Restrictionism",
      "Deportation Concern"
    ))
  )

# Create the trend lines visualization
p1 <- ggplot(all_stats, aes(x = survey_year, y = mean_value, color = generation_label)) +
  geom_point(aes(size = n), alpha = 0.7) +
  geom_line(aes(group = generation_label), linewidth = 1) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label), 
              alpha = 0.2, color = NA) +
  facet_wrap(~index_label, scales = "free_y", ncol = 1) +
  scale_color_viridis_d(name = "Population Group", option = "D", end = 0.8) +
  scale_fill_viridis_d(name = "Population Group", option = "D", end = 0.8) +
  scale_size_continuous(name = "Sample Size", range = c(1, 4), 
                       breaks = c(100, 500, 1000, 2000),
                       labels = c("100", "500", "1K", "2K")) +
  scale_x_continuous(breaks = seq(2002, 2022, 4), 
                     labels = seq(2002, 2022, 4)) +
  labs(
    title = "Longitudinal Trends in Immigration Attitudes Among Hispanic Americans",
    subtitle = "Three Thematic Indices by Immigrant Generation, 2002-2022",
    x = "Survey Year",
    y = "Standardized Index Value",
    caption = "Note: Points sized by sample size. Ribbons show 95% confidence intervals.\nHigher values indicate stronger attitudes in the named direction."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    strip.text = element_text(size = 11, face = "bold"),
    legend.position = "bottom",
    legend.box = "horizontal",
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  guides(
    color = guide_legend(override.aes = list(size = 3)),
    fill = guide_legend(override.aes = list(alpha = 0.5)),
    size = guide_legend(override.aes = list(color = "black"))
  )

# Save trend lines plot
ggsave("outputs/figure_longitudinal_trends_v2_4.png", p1, 
       width = 12, height = 10, dpi = 300, bg = "white")

cat("Saved: outputs/figure_longitudinal_trends_v2_4.png\n")

# ============================================================================
# VISUALIZATION 2: REGRESSION COEFFICIENTS (SLOPES)
# ============================================================================

# Prepare regression data for plotting
regression_plot_data <- all_regression_results %>%
  filter(!is.na(slope)) %>%
  mutate(
    index_label = case_when(
      index == "liberalism_index" ~ "Immigration Policy\nLiberalism",
      index == "restrictionism_index" ~ "Immigration Policy\nRestrictionism", 
      index == "concern_index" ~ "Deportation\nConcern",
      TRUE ~ index
    ),
    index_label = factor(index_label, levels = c(
      "Immigration Policy\nLiberalism",
      "Immigration Policy\nRestrictionism",
      "Deportation\nConcern"
    )),
    significance = case_when(
      p_value < 0.001 ~ "***",
      p_value < 0.01 ~ "**", 
      p_value < 0.05 ~ "*",
      p_value < 0.1 ~ "†",
      TRUE ~ ""
    ),
    group_short = case_when(
      str_detect(group, "1st Generation") ~ "1st Gen",
      str_detect(group, "2nd Generation") ~ "2nd Gen", 
      str_detect(group, "3rd") ~ "3rd+ Gen",
      str_detect(group, "All Hispanic") ~ "All Hispanic",
      TRUE ~ group
    )
  )

# Create regression coefficients plot
p2 <- ggplot(regression_plot_data, aes(x = group_short, y = slope, fill = group_short)) +
  geom_col(alpha = 0.8, color = "white", linewidth = 0.5) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), 
                width = 0.25, color = "black", linewidth = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red", alpha = 0.7) +
  geom_text(aes(label = significance, y = slope + sign(slope) * 0.005), 
            size = 4, fontface = "bold") +
  facet_wrap(~index_label, scales = "free_y", ncol = 3) +
  scale_fill_viridis_d(name = "Population Group", option = "D", end = 0.8) +
  scale_y_continuous(labels = label_number(accuracy = 0.001, style_positive = "plus")) +
  labs(
    title = "Annual Change in Immigration Attitudes (2002-2022)",
    subtitle = "Regression Slopes by Immigrant Generation and Index",
    x = "Population Group",
    y = "Annual Change (Standardized Units per Year)",
    caption = "Note: Error bars show 95% confidence intervals. Significance: *** p<0.001, ** p<0.01, * p<0.05, † p<0.1\nPositive values indicate increasing attitudes in the named direction over time."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    strip.text = element_text(size = 10, face = "bold"),
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9)
  )

# Save regression coefficients plot
ggsave("outputs/figure_regression_slopes_v2_4.png", p2, 
       width = 12, height = 8, dpi = 300, bg = "white")

cat("Saved: outputs/figure_regression_slopes_v2_4.png\n")

# ============================================================================
# VISUALIZATION 3: GENERATION COMPARISON HEATMAP
# ============================================================================

# Prepare data for heatmap showing latest vs earliest values
heatmap_data <- all_stats %>%
  filter(!is.na(generation_label) & generation_label != "All Hispanic\nRespondents") %>%
  group_by(generation_label, index_label) %>%
  arrange(survey_year) %>%
  filter(row_number() == 1 | row_number() == n()) %>%
  mutate(
    period = ifelse(row_number() == 1, "Earliest", "Latest")
  ) %>%
  ungroup() %>%
  select(generation_label, index_label, period, mean_value, survey_year) %>%
  pivot_wider(names_from = period, values_from = c(mean_value, survey_year)) %>%
  mutate(
    change = mean_value_Latest - mean_value_Earliest,
    change_label = case_when(
      abs(change) < 0.1 ~ "Stable",
      change > 0 ~ "Increase",
      change < 0 ~ "Decrease"
    ),
    change_magnitude = case_when(
      abs(change) < 0.1 ~ "Small",
      abs(change) < 0.3 ~ "Moderate", 
      TRUE ~ "Large"
    )
  )

# Create heatmap
p3 <- ggplot(heatmap_data, aes(x = generation_label, y = index_label, fill = change)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = sprintf("%.2f", change)), 
            color = "white", fontface = "bold", size = 4) +
  scale_fill_gradient2(
    name = "Change\n(Latest - Earliest)",
    low = "#d73027", mid = "#ffffbf", high = "#1a9850",
    midpoint = 0, limits = c(-1, 1),
    labels = label_number(accuracy = 0.1, style_positive = "plus")
  ) +
  labs(
    title = "Change in Immigration Attitudes: Earliest vs Latest Survey Years",
    subtitle = "Difference Between Most Recent and First Available Measurements",
    x = "Immigrant Generation",
    y = "Immigration Attitude Index",
    caption = "Note: Values show standardized difference between latest and earliest survey years.\nPositive values indicate increase in attitudes over time."
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank(),
    legend.position = "right"
  )

# Save heatmap
ggsave("outputs/figure_change_heatmap_v2_4.png", p3, 
       width = 10, height = 6, dpi = 300, bg = "white")

cat("Saved: outputs/figure_change_heatmap_v2_4.png\n")

# ============================================================================
# SAVE ANALYSIS RESULTS
# ============================================================================

# Save regression results
write_csv(all_regression_results, "outputs/summaries/regression_results_v2_4.csv")

# Save descriptive statistics
write_csv(all_stats, "outputs/summaries/descriptive_stats_v2_4.csv")

# Save coverage summary
write_csv(coverage_by_year_gen, "outputs/summaries/coverage_by_year_generation_v2_4.csv")

cat("\n=== LONGITUDINAL ANALYSIS v2.4 COMPLETE ===\n")
cat("Visualizations saved:\n")
cat("  - outputs/figure_longitudinal_trends_v2_4.png\n")
cat("  - outputs/figure_regression_slopes_v2_4.png\n")
cat("  - outputs/figure_change_heatmap_v2_4.png\n")
cat("Analysis results saved:\n")
cat("  - outputs/summaries/regression_results_v2_4.csv\n")
cat("  - outputs/summaries/descriptive_stats_v2_4.csv\n")
cat("  - outputs/summaries/coverage_by_year_generation_v2_4.csv\n")