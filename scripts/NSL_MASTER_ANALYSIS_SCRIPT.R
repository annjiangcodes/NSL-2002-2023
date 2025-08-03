# =============================================================================
# NATIONAL SURVEY OF LATINOS (NSL) MASTER ANALYSIS SCRIPT
# =============================================================================
# Purpose: Consolidated analysis pipeline for NSL 2002-2023 immigration attitudes
# Created: January 2025
# Project: NSL Harmonization and Analysis (July 2025)
# Version: 1.0
# =============================================================================

# This script consolidates the best practices from v3.0 analysis scripts
# and provides a streamlined pipeline for analyzing NSL data

# =============================================================================
# SETUP AND CONFIGURATION
# =============================================================================

# Load required libraries
library(haven)
library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)
library(viridis)
library(scales)
library(survey)      # For survey-weighted analysis
library(lme4)        # For multilevel modeling
library(broom)       # For tidy model outputs
library(purrr)       # For functional programming

# Set working directory (adjust as needed)
# setwd("/path/to/NSL-2002-2023")

# Configure output settings
options(scipen = 999)  # Avoid scientific notation
theme_set(theme_minimal())  # Set default ggplot theme

# =============================================================================
# 1. DATA LOADING AND VALIDATION
# =============================================================================

load_nsl_data <- function(version = "v2_7") {
  cat("Loading NSL dataset version:", version, "\n")
  
  # Define file path based on version
  file_paths <- list(
    v2_7 = "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv",
    comprehensive = "data/final/longitudinal_survey_data_2002_2023_COMPREHENSIVE.csv"
  )
  
  # Load data
  data <- read_csv(file_paths[[version]], show_col_types = FALSE)
  
  # Basic validation
  cat("Dataset loaded successfully:\n")
  cat("- Observations:", nrow(data), "\n")
  cat("- Variables:", ncol(data), "\n")
  cat("- Years covered:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n")
  
  return(data)
}

# =============================================================================
# 2. DATA PREPARATION FUNCTIONS
# =============================================================================

prepare_analysis_data <- function(data) {
  cat("\nPreparing data for analysis...\n")
  
  # Create core indices
  data <- data %>%
    mutate(
      # Immigration liberalism index (higher = more liberal)
      liberalism_index = rowMeans(
        select(., starts_with("liberalism_")), 
        na.rm = TRUE
      ),
      
      # Immigration restrictionism index (higher = more restrictive)
      restrictionism_index = rowMeans(
        select(., starts_with("restrictionism_")), 
        na.rm = TRUE
      ),
      
      # Immigration concern index (higher = more concerned)
      concern_index = rowMeans(
        select(., starts_with("concern_")), 
        na.rm = TRUE
      ),
      
      # Generation categories (simplified)
      generation_cat = case_when(
        immigrant_generation == 1 ~ "1st Gen",
        immigrant_generation == 2 ~ "2nd Gen", 
        immigrant_generation >= 3 ~ "3rd+ Gen",
        TRUE ~ NA_character_
      ),
      
      # Period indicators for analysis
      period = case_when(
        survey_year <= 2008 ~ "Bush Era (2002-2008)",
        survey_year <= 2016 ~ "Obama Era (2009-2016)",
        survey_year <= 2020 ~ "Trump Era (2017-2020)",
        TRUE ~ "Biden Era (2021-2023)"
      )
    )
  
  # Report coverage
  cat("- Liberalism index coverage:", 
      round(100 * sum(!is.na(data$liberalism_index)) / nrow(data), 1), "%\n")
  cat("- Restrictionism index coverage:", 
      round(100 * sum(!is.na(data$restrictionism_index)) / nrow(data), 1), "%\n")
  cat("- Concern index coverage:", 
      round(100 * sum(!is.na(data$concern_index)) / nrow(data), 1), "%\n")
  cat("- Generation variable coverage:", 
      round(100 * sum(!is.na(data$generation_cat)) / nrow(data), 1), "%\n")
  
  return(data)
}

# =============================================================================
# 3. SURVEY DESIGN SETUP
# =============================================================================

create_survey_design <- function(data) {
  cat("\nSetting up survey design for weighted analysis...\n")
  
  # Identify weight variable
  weight_var <- names(data)[grepl("weight", names(data), ignore.case = TRUE)][1]
  
  if (!is.na(weight_var)) {
    # Create survey design object
    design <- svydesign(
      ids = ~1,  # No clustering
      weights = as.formula(paste0("~", weight_var)),
      data = data
    )
    cat("Survey design created with weight variable:", weight_var, "\n")
  } else {
    cat("No weight variable found - proceeding with unweighted analysis\n")
    design <- NULL
  }
  
  return(design)
}

# =============================================================================
# 4. DESCRIPTIVE ANALYSIS
# =============================================================================

run_descriptive_analysis <- function(data, design = NULL) {
  cat("\n=== DESCRIPTIVE ANALYSIS ===\n")
  
  # Overall means by year
  if (!is.null(design)) {
    # Weighted means
    yearly_means <- data %>%
      group_by(survey_year) %>%
      summarise(
        n = n(),
        liberalism_weighted = weighted.mean(liberalism_index, 
                                          get(names(data)[grepl("weight", names(data), ignore.case = TRUE)][1]), 
                                          na.rm = TRUE),
        restrictionism_weighted = weighted.mean(restrictionism_index, 
                                              get(names(data)[grepl("weight", names(data), ignore.case = TRUE)][1]), 
                                              na.rm = TRUE),
        .groups = "drop"
      )
  } else {
    # Unweighted means
    yearly_means <- data %>%
      group_by(survey_year) %>%
      summarise(
        n = n(),
        liberalism = mean(liberalism_index, na.rm = TRUE),
        restrictionism = mean(restrictionism_index, na.rm = TRUE),
        concern = mean(concern_index, na.rm = TRUE),
        .groups = "drop"
      )
  }
  
  print(yearly_means)
  
  # Generation patterns
  gen_means <- data %>%
    filter(!is.na(generation_cat)) %>%
    group_by(generation_cat, survey_year) %>%
    summarise(
      n = n(),
      liberalism = mean(liberalism_index, na.rm = TRUE),
      restrictionism = mean(restrictionism_index, na.rm = TRUE),
      .groups = "drop"
    )
  
  return(list(yearly = yearly_means, generation = gen_means))
}

# =============================================================================
# 5. TREND ANALYSIS
# =============================================================================

analyze_trends <- function(data) {
  cat("\n=== TREND ANALYSIS ===\n")
  
  # Overall population trends
  overall_trend <- lm(liberalism_index ~ survey_year, data = data)
  cat("\nOverall liberalism trend:\n")
  print(summary(overall_trend))
  
  # Generation-specific trends
  gen_trends <- data %>%
    filter(!is.na(generation_cat)) %>%
    group_by(generation_cat) %>%
    do(model = lm(liberalism_index ~ survey_year, data = .)) %>%
    mutate(tidied = map(model, tidy)) %>%
    unnest(tidied) %>%
    filter(term == "survey_year")
  
  cat("\nGeneration-specific trends:\n")
  print(gen_trends)
  
  return(list(overall = overall_trend, generation = gen_trends))
}

# =============================================================================
# 6. MULTILEVEL MODELING
# =============================================================================

run_multilevel_analysis <- function(data) {
  cat("\n=== MULTILEVEL ANALYSIS ===\n")
  
  # Prepare data
  model_data <- data %>%
    filter(!is.na(liberalism_index) & !is.na(generation_cat)) %>%
    mutate(year_c = survey_year - 2002)  # Center year at 2002
  
  # Basic multilevel model
  ml_model <- lmer(
    liberalism_index ~ year_c * generation_cat + (1 | survey_year),
    data = model_data
  )
  
  cat("\nMultilevel model results:\n")
  print(summary(ml_model))
  
  return(ml_model)
}

# =============================================================================
# 7. VISUALIZATION FUNCTIONS
# =============================================================================

create_trend_plots <- function(descriptive_results) {
  # Overall trends plot
  p1 <- ggplot(descriptive_results$yearly, aes(x = survey_year)) +
    geom_line(aes(y = liberalism, color = "Liberalism"), size = 1.2) +
    geom_line(aes(y = restrictionism, color = "Restrictionism"), size = 1.2) +
    geom_point(aes(y = liberalism, color = "Liberalism"), size = 3) +
    geom_point(aes(y = restrictionism, color = "Restrictionism"), size = 3) +
    scale_color_manual(values = c("Liberalism" = "#2166ac", "Restrictionism" = "#d6604d")) +
    labs(
      title = "Immigration Attitudes Among U.S. Latinos (2002-2023)",
      x = "Survey Year",
      y = "Mean Score",
      color = "Attitude Index"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  # Generation trends plot
  p2 <- ggplot(descriptive_results$generation, 
               aes(x = survey_year, y = liberalism, color = generation_cat)) +
    geom_line(size = 1.2) +
    geom_point(size = 3) +
    scale_color_viridis_d() +
    labs(
      title = "Immigration Liberalism by Generation",
      x = "Survey Year",
      y = "Mean Liberalism Score",
      color = "Generation"
    ) +
    theme_minimal() +
    theme(legend.position = "bottom")
  
  return(list(overall = p1, generation = p2))
}

# =============================================================================
# 8. EXPORT RESULTS
# =============================================================================

export_results <- function(results, output_dir = "outputs/") {
  cat("\n=== EXPORTING RESULTS ===\n")
  
  # Create timestamp
  timestamp <- format(Sys.Date(), "%Y%m%d")
  
  # Export descriptive statistics
  write_csv(results$descriptive$yearly, 
            file.path(output_dir, paste0("nsl_yearly_trends_", timestamp, ".csv")))
  
  write_csv(results$descriptive$generation, 
            file.path(output_dir, paste0("nsl_generation_trends_", timestamp, ".csv")))
  
  # Save plots
  ggsave(file.path(output_dir, paste0("nsl_overall_trends_", timestamp, ".png")),
         results$plots$overall, width = 10, height = 6, dpi = 300)
  
  ggsave(file.path(output_dir, paste0("nsl_generation_trends_", timestamp, ".png")),
         results$plots$generation, width = 10, height = 6, dpi = 300)
  
  cat("Results exported successfully to:", output_dir, "\n")
}

# =============================================================================
# 9. MAIN ANALYSIS PIPELINE
# =============================================================================

run_nsl_analysis <- function(version = "v2_7", weighted = TRUE) {
  cat("\n")
  cat("=================================================================\n")
  cat("       NATIONAL SURVEY OF LATINOS MASTER ANALYSIS PIPELINE        \n")
  cat("=================================================================\n")
  cat("Started at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
  
  # Load data
  data <- load_nsl_data(version)
  
  # Prepare data
  data <- prepare_analysis_data(data)
  
  # Create survey design if weighted
  design <- if (weighted) create_survey_design(data) else NULL
  
  # Run analyses
  descriptive_results <- run_descriptive_analysis(data, design)
  trend_results <- analyze_trends(data)
  ml_results <- run_multilevel_analysis(data)
  
  # Create visualizations
  plots <- create_trend_plots(descriptive_results)
  
  # Compile results
  results <- list(
    data = data,
    descriptive = descriptive_results,
    trends = trend_results,
    multilevel = ml_results,
    plots = plots
  )
  
  # Export results
  export_results(results)
  
  cat("\n")
  cat("=================================================================\n")
  cat("                    ANALYSIS COMPLETED SUCCESSFULLY               \n")
  cat("=================================================================\n")
  cat("Finished at:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  
  return(results)
}

# =============================================================================
# RUN ANALYSIS
# =============================================================================

# Uncomment to run the full analysis pipeline:
# results <- run_nsl_analysis(version = "v2_7", weighted = TRUE)

# For interactive use, you can run individual components:
# data <- load_nsl_data("v2_7")
# data <- prepare_analysis_data(data)
# descriptive <- run_descriptive_analysis(data)