# ============================================================================
# PRELIMINARY GENERATIONAL ANALYSIS: Immigration Attitudes 2002-2023
# ============================================================================
# 
# This is a rough, exploratory analysis to preview directionality in 
# immigration attitude changes among different generations of Latinos
# across the full 2002-2023 period
#
# ============================================================================

# Load required libraries
library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)

cat("=== PRELIMINARY GENERATIONAL ANALYSIS ===\n")
cat("Immigration Attitudes Among Latino Generations: 2002-2023\n\n")

# Read the comprehensive longitudinal dataset
cat("Loading comprehensive longitudinal survey data 2002-2023...\n")
data <- read_csv("data/final/longitudinal_survey_data_2002_2023_COMPREHENSIVE.csv", show_col_types = FALSE)

cat("Dataset dimensions:", dim(data)[1], "observations,", dim(data)[2], "variables\n")
cat("Survey years covered:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n\n")

# ============================================================================
# DATA PREPARATION
# ============================================================================

cat("=== DATA PREPARATION ===\n")

# Check available immigration attitude variables
cat("Available immigration attitude variables:\n")
attitude_vars <- c("immigration_attitude", "border_security_attitude", "immigration_level_concern", 
                   "immigration_restrictionism_composite", "border_wall_support", "trump_support")
for (var in attitude_vars) {
  if (var %in% names(data)) {
    non_missing <- sum(!is.na(data[[var]]))
    years_available <- length(unique(data$survey_year[!is.na(data[[var]])]))
    cat("  ", var, ":", non_missing, "non-missing observations across", years_available, "years\n")
  } else {
    cat("  ", var, ": Variable not found\n")
  }
}

# Check generation variable
cat("\nGeneration variable:\n")
if ("immigrant_generation" %in% names(data)) {
  gen_table <- table(data$immigrant_generation, useNA = "ifany")
  cat("  immigrant_generation distribution:\n")
  print(gen_table)
} else {
  cat("  immigrant_generation: Variable not found\n")
}

# Clean and label generation variable
data <- data %>%
  mutate(
    generation = case_when(
      immigrant_generation == 1 ~ "First Generation (Foreign-born)",
      immigrant_generation == 2 ~ "Second Generation (US-born, foreign parents)", 
      immigrant_generation == 3 ~ "Third+ Generation (US-born, US-born parents)",
      TRUE ~ NA_character_
    ),
    generation = factor(generation, levels = c(
      "First Generation (Foreign-born)",
      "Second Generation (US-born, foreign parents)",
      "Third+ Generation (US-born, US-born parents)"
    ))
  )

cat("\nGeneration labels:\n")
print(table(data$generation, useNA = "ifany"))

# Check which years have data by generation
cat("\nData availability by year and generation:\n")
year_gen_summary <- data %>%
  filter(!is.na(generation)) %>%
  group_by(survey_year, generation) %>%
  summarise(n = n(), .groups = "drop") %>%
  pivot_wider(names_from = generation, values_from = n, values_fill = 0)

print(year_gen_summary)

# ============================================================================
# ANALYSIS 1: GENERAL IMMIGRATION ATTITUDE BY GENERATION
# ============================================================================

cat("\n\n=== ANALYSIS 1: GENERAL IMMIGRATION ATTITUDE ===\n")

if ("immigration_attitude" %in% names(data)) {
  
  immigration_data <- data %>%
    filter(!is.na(immigration_attitude), !is.na(generation))
  
  cat("Sample size for immigration attitude analysis:", nrow(immigration_data), "\n")
  cat("Years with data:", paste(sort(unique(immigration_data$survey_year)), collapse = ", "), "\n")
  cat("Variable coding - higher values typically = more restrictive\n\n")
  
  # Calculate mean attitudes by generation and year
  cat("MEAN IMMIGRATION ATTITUDES BY GENERATION AND YEAR:\n")
  immigration_means <- immigration_data %>%
    group_by(survey_year, generation) %>%
    summarise(
      n = n(),
      mean_attitude = round(mean(immigration_attitude, na.rm = TRUE), 3),
      .groups = "drop"
    ) %>%
    arrange(generation, survey_year)
  
  print(immigration_means)
  
  # Calculate overall trends by generation
  cat("\n\nOVERALL TREND BY GENERATION (First vs Last Available Year):\n")
  trend_analysis <- immigration_means %>%
    group_by(generation) %>%
    summarise(
      first_year = min(survey_year),
      last_year = max(survey_year),
      first_mean = mean_attitude[survey_year == min(survey_year)],
      last_mean = mean_attitude[survey_year == max(survey_year)],
      total_change = last_mean - first_mean,
      trend_direction = case_when(
        total_change > 0.1 ~ "More Restrictive",
        total_change < -0.1 ~ "Less Restrictive",
        TRUE ~ "Stable"
      ),
      .groups = "drop"
    )
  
  print(trend_analysis)
  
} else {
  cat("Immigration attitude variable not available.\n")
}

# ============================================================================
# ANALYSIS 2: BORDER SECURITY ATTITUDE BY GENERATION
# ============================================================================

cat("\n\n=== ANALYSIS 2: BORDER SECURITY ATTITUDE ===\n")

if ("border_security_attitude" %in% names(data)) {
  
  border_data <- data %>%
    filter(!is.na(border_security_attitude), !is.na(generation))
  
  cat("Sample size for border security analysis:", nrow(border_data), "\n")
  cat("Years with data:", paste(sort(unique(border_data$survey_year)), collapse = ", "), "\n")
  cat("Variable coding - higher values typically = more pro-border security\n\n")
  
  # Calculate mean attitudes by generation and year
  cat("MEAN BORDER SECURITY ATTITUDES BY GENERATION AND YEAR:\n")
  border_means <- border_data %>%
    group_by(survey_year, generation) %>%
    summarise(
      n = n(),
      mean_attitude = round(mean(border_security_attitude, na.rm = TRUE), 3),
      .groups = "drop"
    ) %>%
    arrange(generation, survey_year)
  
  print(border_means)
  
  # Calculate trends
  cat("\n\nBORDER SECURITY TREND BY GENERATION:\n")
  border_trends <- border_means %>%
    group_by(generation) %>%
    summarise(
      years_span = paste(min(survey_year), "to", max(survey_year)),
      first_mean = mean_attitude[survey_year == min(survey_year)],
      last_mean = mean_attitude[survey_year == max(survey_year)],
      total_change = last_mean - first_mean,
      trend_direction = case_when(
        total_change > 0.1 ~ "More Pro-Border Security",
        total_change < -0.1 ~ "Less Pro-Border Security",
        TRUE ~ "Stable"
      ),
      .groups = "drop"
    )
  
  print(border_trends)
  
} else {
  cat("Border security attitude variable not available.\n")
}

# ============================================================================
# ANALYSIS 3: TRUMP SUPPORT BY GENERATION (if available)
# ============================================================================

cat("\n\n=== ANALYSIS 3: TRUMP SUPPORT BY GENERATION ===\n")

if ("trump_support" %in% names(data)) {
  
  trump_data <- data %>%
    filter(!is.na(trump_support), !is.na(generation))
  
  if (nrow(trump_data) > 0) {
    cat("Sample size for Trump support analysis:", nrow(trump_data), "\n")
    cat("Years with data:", paste(sort(unique(trump_data$survey_year)), collapse = ", "), "\n\n")
    
    # Calculate support by generation and year
    cat("TRUMP SUPPORT BY GENERATION AND YEAR:\n")
    trump_summary <- trump_data %>%
      group_by(survey_year, generation) %>%
      summarise(
        n = n(),
        mean_support = round(mean(trump_support, na.rm = TRUE), 3),
        .groups = "drop"
      ) %>%
      arrange(generation, survey_year)
    
    print(trump_summary)
  } else {
    cat("No valid Trump support data available.\n")
  }
  
} else {
  cat("Trump support variable not available.\n")
}

# ============================================================================
# ANALYSIS 4: IMMIGRATION RESTRICTIONISM COMPOSITE (if available)
# ============================================================================

cat("\n\n=== ANALYSIS 4: IMMIGRATION RESTRICTIONISM COMPOSITE ===\n")

if ("immigration_restrictionism_composite" %in% names(data)) {
  
  restrict_data <- data %>%
    filter(!is.na(immigration_restrictionism_composite), !is.na(generation))
  
  if (nrow(restrict_data) > 0) {
    cat("Sample size for restrictionism composite analysis:", nrow(restrict_data), "\n")
    cat("Years with data:", paste(sort(unique(restrict_data$survey_year)), collapse = ", "), "\n\n")
    
    # Calculate restrictionism by generation and year
    cat("IMMIGRATION RESTRICTIONISM BY GENERATION AND YEAR:\n")
    restrict_summary <- restrict_data %>%
      group_by(survey_year, generation) %>%
      summarise(
        n = n(),
        mean_restrictionism = round(mean(immigration_restrictionism_composite, na.rm = TRUE), 3),
        .groups = "drop"
      ) %>%
      arrange(generation, survey_year)
    
    print(restrict_summary)
    
    # Calculate overall trends
    if (length(unique(restrict_data$survey_year)) > 1) {
      cat("\n\nRESTRICTIONISM TRENDS BY GENERATION:\n")
      restrict_trends <- restrict_summary %>%
        group_by(generation) %>%
        summarise(
          years_span = paste(min(survey_year), "to", max(survey_year)),
          first_mean = mean_restrictionism[survey_year == min(survey_year)],
          last_mean = mean_restrictionism[survey_year == max(survey_year)],
          total_change = last_mean - first_mean,
          trend_direction = case_when(
            total_change > 0.1 ~ "More Restrictionist",
            total_change < -0.1 ~ "Less Restrictionist",
            TRUE ~ "Stable"
          ),
          .groups = "drop"
        )
      
      print(restrict_trends)
    }
  } else {
    cat("No valid restrictionism composite data available.\n")
  }
  
} else {
  cat("Immigration restrictionism composite variable not available.\n")
}

# ============================================================================
# SUMMARY: DIRECTIONAL TRENDS BY GENERATION
# ============================================================================

cat("\n\n=== DIRECTIONAL TRENDS SUMMARY ===\n")
cat("PRELIMINARY FINDINGS (2002-2023):\n\n")

cat("📊 GENERATION DEFINITIONS:\n")
cat("   - First Generation: Foreign-born Latinos\n")
cat("   - Second Generation: US-born with foreign-born parents\n") 
cat("   - Third+ Generation: US-born with US-born parents\n\n")

cat("🔍 KEY PATTERNS TO EXAMINE:\n")
cat("1. Do immigration attitudes become more restrictive over time?\n")
cat("2. Are there generational differences in attitude trajectories?\n")
cat("3. How do attitudes change during different political periods?\n")
cat("4. Do third+ generation Latinos have different patterns than first/second?\n\n")

cat("⚠️ ANALYSIS NOTES:\n")
cat("- This is a PRELIMINARY, ROUGH analysis for directional patterns\n")
cat("- Results should be interpreted cautiously without statistical testing\n")
cat("- Sample sizes vary significantly across years and generations\n")
cat("- Control variables (age, education, etc.) not included in this preview\n\n")

cat("📈 NEXT STEPS FOR RIGOROUS ANALYSIS:\n")
cat("1. Statistical significance testing of trends\n")
cat("2. Control for demographic changes over time\n")
cat("3. Formal trend analysis with confidence intervals\n")
cat("4. Analysis of specific political periods (pre/post-Trump, etc.)\n")
cat("5. Interaction effects between generation and time\n\n")

cat("Analysis completed:", Sys.time(), "\n") 