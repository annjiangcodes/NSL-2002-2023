# =============================================================================
# IMMIGRATION ATTITUDES ANALYSIS v2.6 COMPREHENSIVE FIXED
# =============================================================================
# Purpose: Address generation coding issues and use ALL available data points
# Key Fixes:
# - Use immigration attitude data even when generation coding failed
# - Properly handle years 2010-2018 with poor generation coverage
# - Extract maximum possible trend data for three indices approach
# - Create robust visualizations with all available data points
# Date: January 2025
# Version: 2.6 Comprehensive Fixed
# =============================================================================

library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)
library(viridis)
library(scales)

cat("=================================================================\n")
cat("IMMIGRATION ATTITUDES ANALYSIS v2.6 COMPREHENSIVE FIXED\n") 
cat("=================================================================\n")

# =============================================================================
# 1. LOAD DATA AND ASSESS WHAT'S ACTUALLY AVAILABLE
# =============================================================================

cat("\n1. LOADING DATA AND COMPREHENSIVE ASSESSMENT\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Load v2.4 dataset
data <- read_csv("data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv", show_col_types = FALSE)

cat("Dataset dimensions:", dim(data), "\n")
cat("Years available:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n")

# Key insight from diagnostic: We have attitude data but missing generation data
# Strategy: Use ALL attitude data, create generation-stratified analysis where possible,
# and overall trends where generation data is missing

cat("\n1.1 Immigration Variables Actually Available:\n")
immigration_vars <- c("legalization_support", "daca_support", "immigrants_strengthen",
                     "immigration_level_opinion", "border_wall_support", "deportation_policy_support", 
                     "border_security_support", "immigration_importance", "deportation_worry")

for (var in immigration_vars) {
  total_non_missing <- sum(!is.na(data[[var]]))
  years_with_data <- data %>% 
    filter(!is.na(!!sym(var))) %>% 
    pull(survey_year) %>% 
    unique() %>% 
    sort()
  cat(sprintf("  %s: %d observations across years %s\n", 
              var, total_non_missing, paste(years_with_data, collapse = ", ")))
}

# =============================================================================
# 2. CREATE COMPREHENSIVE TREND ANALYSIS (ALL DATA)
# =============================================================================

cat("\n2. COMPREHENSIVE TREND ANALYSIS USING ALL AVAILABLE DATA\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# 2.1 Create year-level aggregates (regardless of generation availability)
cat("\n2.1 Creating Year-Level Aggregates for All Three Indices\n")

yearly_aggregates <- data %>%
  group_by(survey_year) %>%
  summarise(
    total_obs = n(),
    obs_with_generation = sum(!is.na(immigrant_generation)),
    
    # Liberalism Index components
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    liberalism_se = sd(liberalism_index, na.rm = TRUE) / sqrt(sum(!is.na(liberalism_index))),
    liberalism_n = sum(!is.na(liberalism_index)),
    
    # Individual liberalism components for validation
    legalization_mean = mean(legalization_support, na.rm = TRUE),
    legalization_n = sum(!is.na(legalization_support)),
    daca_mean = mean(daca_support, na.rm = TRUE),
    daca_n = sum(!is.na(daca_support)),
    
    # Restrictionism Index components
    restrictionism_mean = mean(restrictionism_index, na.rm = TRUE),
    restrictionism_se = sd(restrictionism_index, na.rm = TRUE) / sqrt(sum(!is.na(restrictionism_index))),
    restrictionism_n = sum(!is.na(restrictionism_index)),
    
    # Individual restrictionism components for validation
    immigration_level_mean = mean(immigration_level_opinion, na.rm = TRUE),
    immigration_level_n = sum(!is.na(immigration_level_opinion)),
    border_wall_mean = mean(border_wall_support, na.rm = TRUE),
    border_wall_n = sum(!is.na(border_wall_support)),
    border_security_mean = mean(border_security_support, na.rm = TRUE),
    border_security_n = sum(!is.na(border_security_support)),
    
    # Concern Index  
    concern_mean = mean(concern_index, na.rm = TRUE),
    concern_se = sd(concern_index, na.rm = TRUE) / sqrt(sum(!is.na(concern_index))),
    concern_n = sum(!is.na(concern_index)),
    
    .groups = "drop"
  ) %>%
  # Remove rows with no index data
  filter(liberalism_n >= 10 | restrictionism_n >= 10 | concern_n >= 10) %>%
  # Replace NaN with NA
  mutate(across(where(is.numeric), ~ifelse(is.nan(.x), NA, .x)))

cat("Years with sufficient data for trend analysis:\n")
print(yearly_aggregates %>% select(survey_year, liberalism_n, restrictionism_n, concern_n))

# 2.2 Create generation-stratified analysis where possible
cat("\n2.2 Creating Generation-Stratified Analysis (Where Possible)\n")

generation_yearly <- data %>%
  filter(!is.na(immigrant_generation)) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation", 
      immigrant_generation == 3 ~ "Third+ Generation"
    )
  ) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    n_total = n(),
    
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    liberalism_se = sd(liberalism_index, na.rm = TRUE) / sqrt(sum(!is.na(liberalism_index))),
    liberalism_n = sum(!is.na(liberalism_index)),
    
    restrictionism_mean = mean(restrictionism_index, na.rm = TRUE),
    restrictionism_se = sd(restrictionism_index, na.rm = TRUE) / sqrt(sum(!is.na(restrictionism_index))),
    restrictionism_n = sum(!is.na(restrictionism_index)),
    
    concern_mean = mean(concern_index, na.rm = TRUE),
    concern_se = sd(concern_index, na.rm = TRUE) / sqrt(sum(!is.na(concern_index))),
    concern_n = sum(!is.na(concern_index)),
    
    .groups = "drop"
  ) %>%
  filter(n_total >= 10) %>%  # Minimum sample size
  mutate(across(where(is.numeric), ~ifelse(is.nan(.x), NA, .x)))

cat("Generation-stratified data available for years:\n")
gen_coverage <- generation_yearly %>%
  group_by(survey_year) %>%
  summarise(generations_available = n(), .groups = "drop")
print(gen_coverage)

# =============================================================================
# 3. STATISTICAL TREND ANALYSIS
# =============================================================================

cat("\n3. STATISTICAL TREND ANALYSIS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# 3.1 Overall trends (all respondents)
cat("\n3.1 Overall Population Trends (All Hispanic Respondents)\n")

run_overall_trend_test <- function(index_name, data_col, data_n_col) {
  trend_data <- yearly_aggregates %>%
    filter(!is.na(!!sym(data_col)), !!sym(data_n_col) >= 50) %>%  # Minimum 50 obs per year
    mutate(year_centered = survey_year - min(survey_year))
  
  if (nrow(trend_data) < 3) {
    cat(sprintf("  %s: Insufficient years (n = %d)\n", index_name, nrow(trend_data)))
    return(NULL)
  }
  
  model <- lm(as.formula(paste(data_col, "~ year_centered")), 
              data = trend_data, weights = trend_data[[data_n_col]])
  summary_model <- summary(model)
  
  if (nrow(summary_model$coefficients) >= 2) {
    slope <- coef(model)[2]
    se <- summary_model$coefficients[2, 2]
    p_value <- summary_model$coefficients[2, 4]
    
    significance <- ifelse(p_value < 0.001, "***", 
                         ifelse(p_value < 0.01, "**",
                               ifelse(p_value < 0.05, "*", "ns")))
    
    direction <- ifelse(slope > 0, "INCREASING", "DECREASING")
    
    cat(sprintf("  %s: slope = %+.6f, p = %.2e %s (%s trend)\n", 
                index_name, slope, p_value, significance, direction))
    cat(sprintf("    Years: %s (n = %d data points)\n", 
                paste(trend_data$survey_year, collapse = ", "), nrow(trend_data)))
    
    return(list(
      index = index_name,
      scope = "Overall Population",
      slope = slope,
      se = se,
      p_value = p_value,
      significance = significance,
      direction = direction,
      n_years = nrow(trend_data),
      years = paste(trend_data$survey_year, collapse = ", ")
    ))
  }
  return(NULL)
}

overall_results <- bind_rows(
  run_overall_trend_test("Immigration Policy Liberalism", "liberalism_mean", "liberalism_n"),
  run_overall_trend_test("Immigration Policy Restrictionism", "restrictionism_mean", "restrictionism_n"),
  run_overall_trend_test("Deportation Concern", "concern_mean", "concern_n")
)

# 3.2 Generation-stratified trends (where data allows)
cat("\n3.2 Generation-Stratified Trends\n")

run_generation_trend_test <- function(index_name, data_col, data_n_col) {
  cat(sprintf("\nTesting %s by generation:\n", index_name))
  
  results <- list()
  
  for (gen in c("First Generation", "Second Generation", "Third+ Generation")) {
    gen_data <- generation_yearly %>%
      filter(generation_label == gen, 
             !is.na(!!sym(data_col)), 
             !!sym(data_n_col) >= 20) %>%  # Minimum 20 obs per year per generation
      mutate(year_centered = survey_year - min(survey_year, na.rm = TRUE))
    
    if (nrow(gen_data) < 3) {
      cat(sprintf("  %s: Insufficient years (n = %d)\n", gen, nrow(gen_data)))
      next
    }
    
    model <- lm(as.formula(paste(data_col, "~ year_centered")), 
                data = gen_data, weights = gen_data[[data_n_col]])
    summary_model <- summary(model)
    
    if (nrow(summary_model$coefficients) >= 2) {
      slope <- coef(model)[2]
      se <- summary_model$coefficients[2, 2]
      p_value <- summary_model$coefficients[2, 4]
      
      significance <- ifelse(p_value < 0.001, "***", 
                           ifelse(p_value < 0.01, "**",
                                 ifelse(p_value < 0.05, "*", "ns")))
      
      direction <- ifelse(slope > 0, "INCREASING", "DECREASING")
      
      cat(sprintf("  %s: slope = %+.6f, p = %.2e %s (%s)\n", 
                  gen, slope, p_value, significance, direction))
      cat(sprintf("    Years: %s\n", paste(gen_data$survey_year, collapse = ", ")))
      
      results[[gen]] <- list(
        index = index_name,
        scope = gen,
        slope = slope,
        se = se,
        p_value = p_value,
        significance = significance,
        direction = direction,
        n_years = nrow(gen_data),
        years = paste(gen_data$survey_year, collapse = ", ")
      )
    }
  }
  
  return(do.call(rbind, lapply(results, data.frame, stringsAsFactors = FALSE)))
}

generation_results <- bind_rows(
  run_generation_trend_test("Immigration Policy Liberalism", "liberalism_mean", "liberalism_n"),
  run_generation_trend_test("Immigration Policy Restrictionism", "restrictionism_mean", "restrictionism_n"),
  run_generation_trend_test("Deportation Concern", "concern_mean", "concern_n")
)

# =============================================================================
# 4. COMPREHENSIVE VISUALIZATIONS WITH ALL DATA
# =============================================================================

cat("\n4. CREATING COMPREHENSIVE VISUALIZATIONS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Publication theme
publication_theme <- theme_minimal() +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 13, color = "gray40", hjust = 0),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold")
  )

generation_colors <- c("#2166ac", "#762a83", "#5aae61")
names(generation_colors) <- c("First Generation", "Second Generation", "Third+ Generation")

# 4.1 Overall population trends (maximum data utilization)
cat("4.1 Creating overall population trends visualization\n")

overall_plot_data <- yearly_aggregates %>%
  select(survey_year, liberalism_mean, liberalism_se, liberalism_n,
         restrictionism_mean, restrictionism_se, restrictionism_n,
         concern_mean, concern_se, concern_n) %>%
  pivot_longer(
    cols = c(liberalism_mean, restrictionism_mean, concern_mean),
    names_to = "index_type",
    values_to = "mean_value"
  ) %>%
  mutate(
    se_col = case_when(
      index_type == "liberalism_mean" ~ liberalism_se,
      index_type == "restrictionism_mean" ~ restrictionism_se,  
      index_type == "concern_mean" ~ concern_se
    ),
    n_col = case_when(
      index_type == "liberalism_mean" ~ liberalism_n,
      index_type == "restrictionism_mean" ~ restrictionism_n,
      index_type == "concern_mean" ~ concern_n
    ),
    Index = case_when(
      index_type == "liberalism_mean" ~ "Immigration Policy\nLiberalism",
      index_type == "restrictionism_mean" ~ "Immigration Policy\nRestrictionism",
      index_type == "concern_mean" ~ "Deportation\nConcern"
    )
  ) %>%
  filter(!is.na(mean_value), n_col >= 50)

p1 <- ggplot(overall_plot_data, aes(x = survey_year, y = mean_value)) +
  geom_line(linewidth = 1.5, alpha = 0.8, color = "#d73027") +
  geom_point(aes(size = n_col), alpha = 0.8, color = "#d73027") +
  geom_ribbon(aes(ymin = mean_value - 1.96 * se_col, 
                  ymax = mean_value + 1.96 * se_col), 
              alpha = 0.2, fill = "#d73027") +
  facet_wrap(~ Index, scales = "free_y", ncol = 1) +
  scale_size_continuous(name = "Sample Size", range = c(2, 8), guide = "legend") +
  scale_x_continuous(breaks = seq(2002, 2022, 3)) +
  labs(
    title = "Immigration Attitudes Among Hispanic Americans: Overall Population Trends (2002-2022)",
    subtitle = "All available data points utilized - maximizes temporal coverage across three thematic indices",
    x = "Survey Year",
    y = "Index Value (Standardized)\n(Higher values = More liberal/restrictionist/concerned)",
    caption = paste("Source: National Survey of Latinos, 2002-2022\n",
                   "Note: 95% confidence intervals shown. Point size indicates sample size.\n",
                   "Uses all available data regardless of generation coding issues.")
  ) +
  publication_theme +
  theme(strip.text = element_text(size = 11))

ggsave("outputs/figure_v2_6_comprehensive_overall_trends.png", p1, 
       width = 12, height = 14, dpi = 300, bg = "white")

# 4.2 Generation-stratified trends (where data allows)
cat("4.2 Creating generation-stratified trends visualization\n")

if (nrow(generation_yearly) > 0) {
  gen_plot_data <- generation_yearly %>%
    filter(liberalism_n >= 20 | restrictionism_n >= 20 | concern_n >= 20) %>%
    select(survey_year, generation_label, 
           liberalism_mean, liberalism_se, liberalism_n,
           restrictionism_mean, restrictionism_se, restrictionism_n,
           concern_mean, concern_se, concern_n) %>%
    pivot_longer(
      cols = c(liberalism_mean, restrictionism_mean, concern_mean),
      names_to = "index_type", 
      values_to = "mean_value"
    ) %>%
    mutate(
      se_col = case_when(
        index_type == "liberalism_mean" ~ liberalism_se,
        index_type == "restrictionism_mean" ~ restrictionism_se,
        index_type == "concern_mean" ~ concern_se
      ),
      n_col = case_when(
        index_type == "liberalism_mean" ~ liberalism_n,
        index_type == "restrictionism_mean" ~ restrictionism_n,
        index_type == "concern_mean" ~ concern_n
      ),
      Index = case_when(
        index_type == "liberalism_mean" ~ "Immigration Policy Liberalism",
        index_type == "restrictionism_mean" ~ "Immigration Policy Restrictionism",
        index_type == "concern_mean" ~ "Deportation Concern"
      )
    ) %>%
    filter(!is.na(mean_value), n_col >= 20)
  
  p2 <- ggplot(gen_plot_data, aes(x = survey_year, y = mean_value, color = generation_label)) +
    geom_line(linewidth = 1.2, alpha = 0.8) +
    geom_point(size = 3, alpha = 0.9) +
    geom_ribbon(aes(ymin = mean_value - 1.96 * se_col, 
                    ymax = mean_value + 1.96 * se_col,
                    fill = generation_label), 
                alpha = 0.2, color = NA) +
    facet_wrap(~ Index, scales = "free_y", ncol = 1) +
    scale_color_manual(values = generation_colors) +
    scale_fill_manual(values = generation_colors) +
    scale_x_continuous(breaks = seq(2002, 2022, 3)) +
    labs(
      title = "Immigration Attitudes by Generation: Comprehensive Three-Index Analysis (2002-2022)",
      subtitle = "Generation-stratified trends using all years with sufficient generation coding",
      x = "Survey Year",
      y = "Index Value (Standardized)\n(Higher values = More liberal/restrictionist/concerned)",
      color = "Generational Status",
      fill = "Generational Status",
      caption = paste("Source: National Survey of Latinos, 2002-2022\n",
                     "Note: 95% confidence intervals shown. Minimum 20 observations per generation per year.\n",
                     "Missing years indicate insufficient generation coding in original surveys.")
    ) +
    publication_theme +
    theme(strip.text = element_text(size = 11))
  
  ggsave("outputs/figure_v2_6_comprehensive_generation_trends.png", p2, 
         width = 12, height = 14, dpi = 300, bg = "white")
}

# =============================================================================
# 5. SAVE COMPREHENSIVE RESULTS
# =============================================================================

cat("\n5. SAVING COMPREHENSIVE RESULTS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Save all results
if (!is.null(overall_results)) {
  write_csv(overall_results, "outputs/comprehensive_overall_trends_v2_6.csv")
  cat("Overall population trends saved\n")
}

if (!is.null(generation_results) && nrow(generation_results) > 0) {
  write_csv(generation_results, "outputs/comprehensive_generation_trends_v2_6.csv")
  cat("Generation-stratified trends saved\n")
}

write_csv(yearly_aggregates, "outputs/comprehensive_yearly_data_v2_6.csv")
write_csv(generation_yearly, "outputs/comprehensive_generation_yearly_v2_6.csv")

# Summary statistics
cat("\n=================================================================\n")
cat("COMPREHENSIVE ANALYSIS SUMMARY\n")
cat("=================================================================\n")

cat("Data utilization maximized:\n")
cat(sprintf("- Overall population trends: %d years of data\n", nrow(yearly_aggregates)))
cat(sprintf("- Generation-stratified data: %d year-generation combinations\n", nrow(generation_yearly)))

if (!is.null(overall_results)) {
  cat("\nOverall population trends found:\n")
  for (i in 1:nrow(overall_results)) {
    result <- overall_results[i, ]
    cat(sprintf("- %s: %s trend (slope = %+.4f, p = %.2e) across %s years\n",
                result$index, result$direction, result$slope, result$p_value, result$n_years))
  }
}

if (!is.null(generation_results) && nrow(generation_results) > 0) {
  cat("\nGeneration-stratified trends found:\n")
  for (i in 1:nrow(generation_results)) {
    result <- generation_results[i, ]
    cat(sprintf("- %s (%s): %s trend (slope = %+.4f, p = %.2e)\n",
                result$index, result$scope, result$direction, result$slope, result$p_value))
  }
}

save.image("outputs/analysis_v2_6_comprehensive_fixed_workspace.RData")

cat("\n=================================================================\n")
cat("COMPREHENSIVE FIXED ANALYSIS COMPLETE\n")
cat("All available data points utilized for maximum temporal coverage\n")
cat("=================================================================\n")