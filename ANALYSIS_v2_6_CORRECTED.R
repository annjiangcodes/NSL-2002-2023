# =============================================================================
# IMMIGRATION ATTITUDES ANALYSIS v2.6 CORRECTED - THREE INDICES FOCUS
# =============================================================================
# Purpose: Fix missing data points and focus on agreed three-indices approach
# Key Updates: 
# - Focus on three indices: Liberalism, Restrictionism, Deportation Concern
# - Use all available data points to address visualization gaps
# - Proper aggregation for longitudinal trends
# Date: January 2025
# Version: 2.6 Corrected
# =============================================================================

# Load required libraries
library(dplyr)
library(ggplot2)
library(survey)
library(broom)
library(haven)
library(viridis)
library(scales)
library(stringr)
library(readr)
library(purrr)
library(forcats)

cat("=================================================================\n")
cat("IMMIGRATION ATTITUDES ANALYSIS v2.6 CORRECTED - THREE INDICES\n") 
cat("=================================================================\n")

# =============================================================================
# 1. DATA LOADING AND DIAGNOSTIC
# =============================================================================

cat("\n1. DATA LOADING AND DIAGNOSTIC\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Load the most recent complete dataset
if (file.exists("data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv")) {
  data <- read_csv("data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv")
  cat("✓ Loaded v2.4 dataset\n")
} else {
  cat("✗ v2.4 dataset not found, loading fallback\n")
  data <- read_csv("data/final/longitudinal_survey_data_2002_2023_FINAL.csv")
}

cat("Dataset dimensions:", dim(data), "\n")
cat("Years available:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n")

# Check the three indices availability
cat("\n1.1 Three Indices Availability Check\n")
indices_check <- data %>%
  summarise(
    liberalism_available = sum(!is.na(liberalism_index)),
    restrictionism_available = sum(!is.na(restrictionism_index)), 
    concern_available = sum(!is.na(concern_index)),
    total_rows = n()
  )

cat("Liberalism Index: ", indices_check$liberalism_available, " observations\n")
cat("Restrictionism Index: ", indices_check$restrictionism_available, " observations\n") 
cat("Deportation Concern Index: ", indices_check$concern_available, " observations\n")

# Check yearly coverage for each index
yearly_coverage <- data %>%
  group_by(survey_year) %>%
  summarise(
    n_total = n(),
    n_gen = sum(!is.na(immigrant_generation)),
    n_lib = sum(!is.na(liberalism_index)),
    n_rest = sum(!is.na(restrictionism_index)),
    n_conc = sum(!is.na(concern_index)),
    .groups = "drop"
  )

cat("\n1.2 Yearly Coverage by Index\n")
print(yearly_coverage)

# =============================================================================
# 2. PREPARE ANALYSIS DATASET WITH FOCUS ON THREE INDICES
# =============================================================================

cat("\n2. PREPARING ANALYSIS DATASET - THREE INDICES FOCUS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Create analysis dataset with any respondent having at least one index and generation data
analysis_data <- data %>%
  filter(
    !is.na(immigrant_generation),
    (!is.na(liberalism_index) | !is.na(restrictionism_index) | !is.na(concern_index))
  ) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation", 
      immigrant_generation == 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    ),
    year_centered = survey_year - 2002
  ) %>%
  filter(!is.na(generation_label))

cat("Analysis sample size:", nrow(analysis_data), "observations\n")

# Check sample sizes by generation and year for each index
sample_check <- analysis_data %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    n_total = n(),
    n_liberalism = sum(!is.na(liberalism_index)),
    n_restrictionism = sum(!is.na(restrictionism_index)),
    n_concern = sum(!is.na(concern_index)),
    .groups = "drop"
  ) %>%
  filter(n_total >= 10)  # Only show years/generations with meaningful sample

cat("\n2.1 Sample Sizes by Year and Generation (≥10 observations)\n")
print(sample_check, n = Inf)

# =============================================================================
# 3. INDIVIDUAL-LEVEL REGRESSION ANALYSIS FOR ALL THREE INDICES
# =============================================================================

cat("\n3. INDIVIDUAL-LEVEL REGRESSION ANALYSIS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Function to run individual-level regression
run_individual_regression <- function(index_name, data_col) {
  cat(paste("\n3.", which(c("liberalism_index", "restrictionism_index", "concern_index") == data_col), 
            " Analyzing", index_name, "\n"))
  
  # Filter for non-missing data
  reg_data <- analysis_data %>%
    filter(!is.na(!!sym(data_col)))
  
  cat("Sample size for", index_name, ":", nrow(reg_data), "\n")
  
  results <- data.frame()
  
  for (gen in c("First Generation", "Second Generation", "Third+ Generation")) {
    gen_data <- reg_data %>% filter(generation_label == gen)
    
    if (nrow(gen_data) < 20) {
      cat("  ", gen, ": Insufficient sample size (n =", nrow(gen_data), ")\n")
      next
    }
    
    # Run regression
    model <- lm(as.formula(paste(data_col, "~ year_centered")), data = gen_data)
    summary_model <- summary(model)
    
    if (nrow(summary_model$coefficients) >= 2) {
      slope <- coef(model)[2]
      se <- summary_model$coefficients[2, 2]
      p_value <- summary_model$coefficients[2, 4]
      
      significance <- ifelse(p_value < 0.001, "***", 
                           ifelse(p_value < 0.01, "**",
                                 ifelse(p_value < 0.05, "*", "ns")))
      
      direction <- ifelse(slope > 0, "LIBERAL", "CONSERVATIVE")
      
      cat("  ", gen, ": slope =", round(slope, 6), 
          ", p =", formatC(p_value, format = "e", digits = 3), significance,
          "(", direction, "trend )\n")
      
      results <- rbind(results, data.frame(
        index = index_name,
        generation = gen,
        slope = slope,
        se = se,
        p_value = p_value,
        significance = significance,
        direction = direction,
        n_obs = nrow(gen_data)
      ))
    }
  }
  
  return(results)
}

# Run analysis for all three indices
regression_results <- bind_rows(
  run_individual_regression("Immigration Policy Liberalism", "liberalism_index"),
  run_individual_regression("Immigration Policy Restrictionism", "restrictionism_index"),
  run_individual_regression("Deportation Concern", "concern_index")
)

# =============================================================================
# 4. AGGREGATE TREND ANALYSIS FOR VISUALIZATION
# =============================================================================

cat("\n4. AGGREGATE TREND ANALYSIS FOR VISUALIZATION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Create aggregated trends using all available data points
create_trend_data <- function(index_name, data_col) {
  trend_data <- analysis_data %>%
    filter(!is.na(!!sym(data_col))) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      mean_index = mean(!!sym(data_col), na.rm = TRUE),
      se_index = sd(!!sym(data_col), na.rm = TRUE) / sqrt(n()),
      n = n(),
      .groups = "drop"
    ) %>%
    filter(n >= 10) %>%  # Minimum 10 observations per group
    mutate(index_name = index_name)
  
  return(trend_data)
}

# Create trend data for all three indices
trend_data_all <- bind_rows(
  create_trend_data("Immigration Policy Liberalism", "liberalism_index"),
  create_trend_data("Immigration Policy Restrictionism", "restrictionism_index"),
  create_trend_data("Deportation Concern", "concern_index")
)

cat("Trend data points created:\n")
trend_summary <- trend_data_all %>%
  group_by(index_name, generation_label) %>%
  summarise(
    n_years = n(),
    year_range = paste(min(survey_year), max(survey_year), sep = "-"),
    .groups = "drop"
  )
print(trend_summary)

# =============================================================================
# 5. COMPREHENSIVE VISUALIZATIONS FOR ALL THREE INDICES
# =============================================================================

cat("\n5. CREATING COMPREHENSIVE VISUALIZATIONS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Define publication theme
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

# Color palette for generations
generation_colors <- c("#2166ac", "#762a83", "#5aae61")
names(generation_colors) <- c("First Generation", "Second Generation", "Third+ Generation")

# 5.1 Combined plot for all three indices
cat("5.1 Creating combined three-indices plot\n")

p1 <- ggplot(trend_data_all, aes(x = survey_year, y = mean_index, color = generation_label)) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 3, alpha = 0.9) +
  geom_ribbon(aes(ymin = mean_index - 1.96 * se_index, 
                  ymax = mean_index + 1.96 * se_index,
                  fill = generation_label), 
              alpha = 0.2, color = NA) +
  facet_wrap(~ index_name, scales = "free_y", ncol = 1) +
  scale_color_manual(values = generation_colors) +
  scale_fill_manual(values = generation_colors) +
  scale_x_continuous(breaks = seq(2002, 2023, 3)) +
  labs(
    title = "Immigration Attitudes by Generation: Three Thematic Indices (2002-2023)",
    subtitle = "Longitudinal trends across Immigration Policy Liberalism, Restrictionism, and Deportation Concern",
    x = "Survey Year",
    y = "Index Value (Standardized)\n(Higher values = More liberal/restrictionist/concerned)",
    color = "Generational Status",
    fill = "Generational Status",
    caption = "Source: National Survey of Latinos, 2002-2023\nNote: 95% confidence intervals shown. Minimum 10 observations per data point."
  ) +
  publication_theme

ggsave("outputs/figure_v2_6_three_indices_combined.png", p1, width = 12, height = 14, dpi = 300, bg = "white")

# 5.2 Individual plots for each index
cat("5.2 Creating individual plots for each index\n")

# Liberalism Index
lib_data <- trend_data_all %>% filter(index_name == "Immigration Policy Liberalism")
if (nrow(lib_data) > 0) {
  p2 <- ggplot(lib_data, aes(x = survey_year, y = mean_index, color = generation_label)) +
    geom_line(linewidth = 1.5, alpha = 0.8) +
    geom_point(size = 4, alpha = 0.9) +
    geom_ribbon(aes(ymin = mean_index - 1.96 * se_index, 
                    ymax = mean_index + 1.96 * se_index,
                    fill = generation_label), 
                alpha = 0.2, color = NA) +
    scale_color_manual(values = generation_colors) +
    scale_fill_manual(values = generation_colors) +
    scale_x_continuous(breaks = seq(2002, 2023, 3)) +
    labs(
      title = "Immigration Policy Liberalism by Generation (2002-2023)",
      subtitle = "First Generation becoming more liberal, Second/Third+ becoming more conservative",
      x = "Survey Year",
      y = "Immigration Policy Liberalism Index\n(Higher values = More liberal)",
      color = "Generational Status",
      fill = "Generational Status",
      caption = "Source: National Survey of Latinos, 2002-2023\nNote: 95% confidence intervals shown."
    ) +
    publication_theme
  
  ggsave("outputs/figure_v2_6_liberalism_detailed.png", p2, width = 12, height = 8, dpi = 300, bg = "white")
}

# Restrictionism Index  
rest_data <- trend_data_all %>% filter(index_name == "Immigration Policy Restrictionism")
if (nrow(rest_data) > 0) {
  p3 <- ggplot(rest_data, aes(x = survey_year, y = mean_index, color = generation_label)) +
    geom_line(linewidth = 1.5, alpha = 0.8) +
    geom_point(size = 4, alpha = 0.9) +
    geom_ribbon(aes(ymin = mean_index - 1.96 * se_index, 
                    ymax = mean_index + 1.96 * se_index,
                    fill = generation_label), 
                alpha = 0.2, color = NA) +
    scale_color_manual(values = generation_colors) +
    scale_fill_manual(values = generation_colors) +
    scale_x_continuous(breaks = seq(2002, 2023, 3)) +
    labs(
      title = "Immigration Policy Restrictionism by Generation (2002-2023)",
      subtitle = "Convergent trends: First Generation increasing, Second Generation decreasing restrictionism",
      x = "Survey Year",
      y = "Immigration Policy Restrictionism Index\n(Higher values = More restrictionist)",
      color = "Generational Status", 
      fill = "Generational Status",
      caption = "Source: National Survey of Latinos, 2002-2023\nNote: 95% confidence intervals shown."
    ) +
    publication_theme
  
  ggsave("outputs/figure_v2_6_restrictionism_detailed.png", p3, width = 12, height = 8, dpi = 300, bg = "white")
}

# Deportation Concern Index
conc_data <- trend_data_all %>% filter(index_name == "Deportation Concern")
if (nrow(conc_data) > 0) {
  p4 <- ggplot(conc_data, aes(x = survey_year, y = mean_index, color = generation_label)) +
    geom_line(linewidth = 1.5, alpha = 0.8) +
    geom_point(size = 4, alpha = 0.9) +
    geom_ribbon(aes(ymin = mean_index - 1.96 * se_index, 
                    ymax = mean_index + 1.96 * se_index,
                    fill = generation_label), 
                alpha = 0.2, color = NA) +
    scale_color_manual(values = generation_colors) +
    scale_fill_manual(values = generation_colors) +
    scale_x_continuous(breaks = seq(2002, 2023, 3)) +
    labs(
      title = "Deportation Concern by Generation (2002-2023)",
      subtitle = "First Generation increasing concern, Second/Third+ decreasing concern over time",
      x = "Survey Year",
      y = "Deportation Concern Index\n(Higher values = More concerned)",
      color = "Generational Status",
      fill = "Generational Status",
      caption = "Source: National Survey of Latinos, 2002-2023\nNote: 95% confidence intervals shown."
    ) +
    publication_theme
  
  ggsave("outputs/figure_v2_6_concern_detailed.png", p4, width = 12, height = 8, dpi = 300, bg = "white")
}

# 5.3 Coefficient plot for all three indices
cat("5.3 Creating comprehensive coefficient plot\n")

if (nrow(regression_results) > 0) {
  p5 <- regression_results %>%
    mutate(
      Index = case_when(
        index == "Immigration Policy Liberalism" ~ "Liberalism",
        index == "Immigration Policy Restrictionism" ~ "Restrictionism",
        index == "Deportation Concern" ~ "Deportation\nConcern"
      ),
      Generation = factor(generation, levels = c("First Generation", "Second Generation", "Third+ Generation")),
      Significant = ifelse(p_value < 0.05, "Significant", "Not Significant")
    ) %>%
    ggplot(aes(x = Generation, y = slope, color = Significant)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", linewidth = 1) +
    geom_errorbar(aes(ymin = slope - 1.96 * se, ymax = slope + 1.96 * se), 
                  width = 0.2, linewidth = 1.2, position = position_dodge(width = 0.3)) +
    geom_point(size = 5, position = position_dodge(width = 0.3)) +
    facet_wrap(~ Index, scales = "free_y") +
    scale_color_manual(values = c("Significant" = "#d73027", "Not Significant" = "#4575b4")) +
    labs(
      title = "Annual Change in Immigration Attitudes: Three Indices by Generation",
      subtitle = "Regression coefficients with 95% confidence intervals",
      x = "Generational Status",
      y = "Annual Change in Index Value\n(Positive = Increasing over time)",
      color = "Statistical Significance",
      caption = "Source: Individual-level regression models using National Survey of Latinos, 2002-2023"
    ) +
    publication_theme +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      strip.text = element_text(size = 10)
    )
  
  ggsave("outputs/figure_v2_6_coefficients_three_indices.png", p5, width = 14, height = 8, dpi = 300, bg = "white")
}

# =============================================================================
# 6. SAVE RESULTS AND SUMMARY
# =============================================================================

cat("\n6. SAVING RESULTS AND SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Save detailed results
write_csv(regression_results, "outputs/regression_results_three_indices_v2_6.csv")
write_csv(trend_data_all, "outputs/trend_data_three_indices_v2_6.csv")

# Create summary
cat("\n6.1 FINAL SUMMARY - THREE INDICES APPROACH\n")
cat("Sample size:", nrow(analysis_data), "observations\n")
cat("Years covered:", min(analysis_data$survey_year), "-", max(analysis_data$survey_year), "\n")

if (nrow(regression_results) > 0) {
  cat("\nRegression Results Summary:\n")
  results_summary <- regression_results %>%
    group_by(index) %>%
    summarise(
      n_generations = n(),
      n_significant = sum(p_value < 0.05),
      .groups = "drop"
    )
  print(results_summary)
  
  cat("\nKey Findings by Index:\n")
  for (idx in unique(regression_results$index)) {
    cat("\n", idx, ":\n")
    idx_results <- regression_results %>% filter(index == idx)
    for (i in 1:nrow(idx_results)) {
      row <- idx_results[i, ]
      cat("  ", row$generation, ": ", row$direction, " trend (slope = ", 
          round(row$slope, 4), ", p = ", formatC(row$p_value, format = "e", digits = 2), 
          ") ", row$significance, "\n")
    }
  }
}

# Save workspace
save.image("outputs/analysis_v2_6_corrected_workspace.RData")

cat("\n=================================================================\n")
cat("ANALYSIS v2.6 CORRECTED COMPLETE - THREE INDICES FOCUS\n")
cat("Key outputs:\n")
cat("- Combined plot: figure_v2_6_three_indices_combined.png\n")
cat("- Individual plots: figure_v2_6_*_detailed.png\n")
cat("- Coefficient plot: figure_v2_6_coefficients_three_indices.png\n")
cat("- Regression results: regression_results_three_indices_v2_6.csv\n")
cat("- Trend data: trend_data_three_indices_v2_6.csv\n")
cat("=================================================================\n")