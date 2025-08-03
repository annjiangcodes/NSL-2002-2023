# =============================================================================
# ENHANCED LONGITUDINAL ANALYSIS v4.0 - SIMPLIFIED VERSION
# =============================================================================
# Purpose: Simplified implementation focusing on core analyses
# Version: 4.0 Simplified
# Date: January 2025
# =============================================================================

# Load required libraries
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(purrr)
library(stringr)
library(broom)

cat("=============================================================\n")
cat("ENHANCED LONGITUDINAL ANALYSIS v4.0 - SIMPLIFIED\n")
cat("=============================================================\n")

# =============================================================================
# 1. DATA LOADING AND PREPARATION
# =============================================================================

cat("\n1. LOADING AND PREPARING DATA\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load the comprehensive dataset
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", 
                 show_col_types = FALSE)

cat(sprintf("Dataset loaded: %d observations, %d variables\n", 
            nrow(data), ncol(data)))
cat(sprintf("Years covered: %s\n", 
            paste(sort(unique(data$survey_year)), collapse = ", ")))

# =============================================================================
# 2. ENHANCED VARIABLE CONSTRUCTION
# =============================================================================

cat("\n2. CONSTRUCTING ENHANCED VARIABLES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create additional analytical variables
data <- data %>%
  mutate(
    # Net liberalism measure
    net_liberalism = liberalism_index - restrictionism_index,
    
    # Ambivalence index (high values = holding both liberal and restrictive views)
    ambivalence_index = abs(liberalism_index) + abs(restrictionism_index),
    
    # Period categorization
    period = case_when(
      survey_year %in% c(2002, 2004) ~ "Early Bush Era",
      survey_year %in% c(2006, 2007) ~ "Immigration Debates",
      survey_year %in% c(2008, 2009, 2010) ~ "Economic Crisis",
      survey_year %in% c(2011:2015) ~ "Obama Era",
      survey_year %in% c(2016:2018) ~ "Trump Era",
      survey_year >= 2021 ~ "COVID & Biden Era",
      TRUE ~ "Other"
    ),
    period = factor(period, levels = c("Early Bush Era", "Immigration Debates",
                                      "Economic Crisis", "Obama Era", 
                                      "Trump Era", "COVID & Biden Era")),
    
    # Generation labels with proper ordering
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation",
      TRUE ~ NA_character_
    ),
    generation_label = factor(generation_label, 
                             levels = c("1st Generation", 
                                       "2nd Generation", 
                                       "3rd+ Generation"))
  )

# Summary of new variables
cat("\nNew variables created:\n")
cat("- net_liberalism: Range", 
    sprintf("[%.2f, %.2f]\n", 
            min(data$net_liberalism, na.rm = TRUE),
            max(data$net_liberalism, na.rm = TRUE)))
cat("- ambivalence_index: Range", 
    sprintf("[%.2f, %.2f]\n", 
            min(data$ambivalence_index, na.rm = TRUE),
            max(data$ambivalence_index, na.rm = TRUE)))
cat("- period: ", length(unique(data$period)), "time periods\n")

# =============================================================================
# 3. AGGREGATED ANALYSES - OVERALL HISPANIC POPULATION
# =============================================================================

cat("\n3. AGGREGATED ANALYSES - OVERALL HISPANIC POPULATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# 3.1 Overall yearly trends
overall_trends <- data %>%
  group_by(survey_year) %>%
  summarise(
    n = n(),
    
    # Liberalism index
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    liberalism_se = sd(liberalism_index, na.rm = TRUE) / 
                    sqrt(sum(!is.na(liberalism_index))),
    liberalism_n = sum(!is.na(liberalism_index)),
    
    # Restrictionism index  
    restrictionism_mean = mean(restrictionism_index, na.rm = TRUE),
    restrictionism_se = sd(restrictionism_index, na.rm = TRUE) / 
                       sqrt(sum(!is.na(restrictionism_index))),
    restrictionism_n = sum(!is.na(restrictionism_index)),
    
    # Concern index
    concern_mean = mean(concern_index, na.rm = TRUE),
    concern_se = sd(concern_index, na.rm = TRUE) / 
                 sqrt(sum(!is.na(concern_index))),
    concern_n = sum(!is.na(concern_index)),
    
    # Net liberalism
    net_liberalism_mean = mean(net_liberalism, na.rm = TRUE),
    net_liberalism_se = sd(net_liberalism, na.rm = TRUE) / 
                       sqrt(sum(!is.na(net_liberalism))),
    
    # Ambivalence
    ambivalence_mean = mean(ambivalence_index, na.rm = TRUE),
    ambivalence_se = sd(ambivalence_index, na.rm = TRUE) / 
                    sqrt(sum(!is.na(ambivalence_index))),
    
    .groups = "drop"
  )

cat("\nOverall population trends summary:\n")
print(overall_trends %>% select(survey_year, n, liberalism_mean, restrictionism_mean))

# 3.2 Period effects analysis
period_effects <- data %>%
  group_by(period) %>%
  summarise(
    years = paste(unique(survey_year), collapse = ", "),
    n = n(),
    
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    liberalism_se = sd(liberalism_index, na.rm = TRUE) / 
                   sqrt(sum(!is.na(liberalism_index))),
    
    restrictionism_mean = mean(restrictionism_index, na.rm = TRUE),
    restrictionism_se = sd(restrictionism_index, na.rm = TRUE) / 
                      sqrt(sum(!is.na(restrictionism_index))),
    
    net_liberalism_mean = mean(net_liberalism, na.rm = TRUE),
    net_liberalism_se = sd(net_liberalism, na.rm = TRUE) / 
                      sqrt(sum(!is.na(net_liberalism))),
    
    .groups = "drop"
  )

cat("\nPeriod effects summary:\n")
print(period_effects %>% select(period, n, liberalism_mean, restrictionism_mean))

# =============================================================================
# 4. GENERATION-SPECIFIC DISAGGREGATED ANALYSES
# =============================================================================

cat("\n4. GENERATION-SPECIFIC DISAGGREGATED ANALYSES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# 4.1 Generation by year trends
generation_year_trends <- data %>%
  filter(!is.na(generation_label)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    n = n(),
    
    # Liberalism
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    liberalism_se = sd(liberalism_index, na.rm = TRUE) / 
                   sqrt(sum(!is.na(liberalism_index))),
    liberalism_ci_lower = liberalism_mean - 1.96 * liberalism_se,
    liberalism_ci_upper = liberalism_mean + 1.96 * liberalism_se,
    
    # Restrictionism
    restrictionism_mean = mean(restrictionism_index, na.rm = TRUE),
    restrictionism_se = sd(restrictionism_index, na.rm = TRUE) / 
                      sqrt(sum(!is.na(restrictionism_index))),
    restrictionism_ci_lower = restrictionism_mean - 1.96 * restrictionism_se,
    restrictionism_ci_upper = restrictionism_mean + 1.96 * restrictionism_se,
    
    # Net liberalism
    net_liberalism_mean = mean(net_liberalism, na.rm = TRUE),
    net_liberalism_se = sd(net_liberalism, na.rm = TRUE) / 
                      sqrt(sum(!is.na(net_liberalism))),
    
    .groups = "drop"
  ) %>%
  filter(n >= 30)  # Minimum sample size for reliability

cat("\nGeneration-specific coverage by year:\n")
gen_coverage <- generation_year_trends %>%
  group_by(survey_year) %>%
  summarise(
    generations_covered = n(),
    total_n = sum(n),
    .groups = "drop"
  )
print(gen_coverage)

# 4.2 Test for generational convergence/divergence
convergence_test <- generation_year_trends %>%
  group_by(survey_year) %>%
  summarise(
    n_generations = n(),
    liberalism_variance = var(liberalism_mean, na.rm = TRUE),
    restrictionism_variance = var(restrictionism_mean, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_generations >= 2)

cat("\nGenerational convergence test (between-generation variance):\n")
print(convergence_test)

# Print detailed generation trends
cat("\nDetailed generation trends (selected years):\n")
print(generation_year_trends %>%
      filter(survey_year %in% c(2002, 2012, 2022)) %>%
      select(survey_year, generation_label, n, liberalism_mean, restrictionism_mean) %>%
      arrange(survey_year, generation_label))

# =============================================================================
# 5. STATISTICAL TREND ANALYSIS
# =============================================================================

cat("\n5. STATISTICAL TREND ANALYSIS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Function to run weighted regression
run_trend_regression <- function(data, outcome_var, group_var = NULL) {
  if (!is.null(group_var)) {
    # Group-specific analysis
    groups <- unique(data[[group_var]])
    results <- list()
    
    for (g in groups) {
      if (is.na(g)) next
      
      group_data <- data %>% 
        filter(.data[[group_var]] == g, !is.na(.data[[outcome_var]]))
      
      if (nrow(group_data) >= 3) {
        model <- lm(as.formula(paste(outcome_var, "~ survey_year")), 
                   data = group_data)
        
        results[[as.character(g)]] <- tidy(model) %>%
          filter(term == "survey_year") %>%
          mutate(
            group = g,
            outcome = outcome_var,
            direction = ifelse(estimate > 0, "Increasing", "Decreasing"),
            significance = case_when(
              p.value < 0.001 ~ "***",
              p.value < 0.01 ~ "**",
              p.value < 0.05 ~ "*",
              TRUE ~ "ns"
            )
          )
      }
    }
    
    return(bind_rows(results))
  } else {
    # Overall analysis
    model <- lm(as.formula(paste(outcome_var, "~ survey_year")), data = data)
    
    return(tidy(model) %>%
      filter(term == "survey_year") %>%
      mutate(
        group = "Overall",
        outcome = outcome_var,
        direction = ifelse(estimate > 0, "Increasing", "Decreasing"),
        significance = case_when(
          p.value < 0.001 ~ "***",
          p.value < 0.01 ~ "**",
          p.value < 0.05 ~ "*",
          TRUE ~ "ns"
        )
      ))
  }
}

# 5.1 Overall population trends
overall_regression_results <- bind_rows(
  run_trend_regression(overall_trends, "liberalism_mean"),
  run_trend_regression(overall_trends, "restrictionism_mean"),
  run_trend_regression(overall_trends, "net_liberalism_mean")
)

cat("\nOverall population trend regression results:\n")
print(overall_regression_results %>% 
      select(outcome, estimate, p.value, significance, direction))

# 5.2 Generation-specific trends
generation_regression_results <- bind_rows(
  run_trend_regression(generation_year_trends, "liberalism_mean", "generation_label"),
  run_trend_regression(generation_year_trends, "restrictionism_mean", "generation_label"),
  run_trend_regression(generation_year_trends, "net_liberalism_mean", "generation_label")
)

cat("\nGeneration-specific trend regression results:\n")
print(generation_regression_results %>%
      select(group, outcome, estimate, p.value, significance, direction) %>%
      arrange(outcome, group))

# =============================================================================
# 6. SIMPLE VISUALIZATIONS
# =============================================================================

cat("\n6. CREATING SIMPLE VISUALIZATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# 6.1 Overall trends plot
p1 <- ggplot(overall_trends %>% filter(!is.na(liberalism_mean)), 
             aes(x = survey_year)) +
  geom_line(aes(y = liberalism_mean, color = "Liberalism"), size = 1.2) +
  geom_point(aes(y = liberalism_mean, color = "Liberalism"), size = 3) +
  geom_line(aes(y = restrictionism_mean, color = "Restrictionism"), size = 1.2) +
  geom_point(aes(y = restrictionism_mean, color = "Restrictionism"), size = 3) +
  scale_color_manual(values = c("Liberalism" = "#2166AC", 
                               "Restrictionism" = "#B2182B"),
                    name = "Index") +
  labs(title = "Overall Hispanic Immigration Attitudes Over Time",
       x = "Survey Year",
       y = "Mean Standardized Score") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("outputs/figure_v4_0_overall_trends_simple.png", p1, width = 10, height = 6)

# 6.2 Generation-specific trends
p2 <- generation_year_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, 
             color = generation_label, group = generation_label)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(title = "Immigration Policy Liberalism by Generation",
       x = "Survey Year",
       y = "Mean Liberalism Score",
       color = "Generation") +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("outputs/figure_v4_0_generation_liberalism_simple.png", p2, width = 10, height = 6)

# 6.3 Period effects bar plot
p3 <- period_effects %>%
  filter(!is.na(liberalism_mean)) %>%
  ggplot(aes(x = period, y = liberalism_mean)) +
  geom_bar(stat = "identity", fill = "#2166AC") +
  labs(title = "Immigration Policy Liberalism by Historical Period",
       x = "Period",
       y = "Mean Liberalism Score") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/figure_v4_0_period_effects_simple.png", p3, width = 10, height = 6)

cat("\nSimple visualizations created successfully.\n")

# =============================================================================
# 7. SAVE ANALYTICAL OUTPUTS
# =============================================================================

cat("\n7. SAVING ANALYTICAL OUTPUTS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Save trend data
write_csv(overall_trends, "outputs/overall_trends_v4_0.csv")
write_csv(generation_year_trends, "outputs/generation_year_trends_v4_0.csv")
write_csv(period_effects, "outputs/period_effects_v4_0.csv")

# Save regression results
write_csv(bind_rows(overall_regression_results, generation_regression_results),
          "outputs/regression_results_v4_0.csv")

# Save workspace
save.image("outputs/enhanced_analysis_v4_0_workspace.RData")

cat("\nAnalysis complete! All outputs saved.\n")
cat("Outputs created:\n")
cat("- overall_trends_v4_0.csv\n")
cat("- generation_year_trends_v4_0.csv\n")
cat("- period_effects_v4_0.csv\n")
cat("- regression_results_v4_0.csv\n")
cat("- enhanced_analysis_v4_0_workspace.RData\n")
cat("\nSimple visualizations:\n")
cat("- figure_v4_0_overall_trends_simple.png\n")
cat("- figure_v4_0_generation_liberalism_simple.png\n")
cat("- figure_v4_0_period_effects_simple.png\n")

# =============================================================================
# END OF ENHANCED LONGITUDINAL ANALYSIS - SIMPLIFIED VERSION
# =============================================================================