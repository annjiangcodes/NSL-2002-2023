# ============================================================================
# TRAJECTORY DIAGNOSTIC v2.5: INVESTIGATING INCONSISTENT ANNUAL CHANGES
# ============================================================================
# Purpose: Systematically investigate why different versions of our analysis
#          are producing different annual change trajectories. This is a 
#          critical methodological issue that needs to be resolved.
# Version: 2.5
# Date: Current analysis session
# Issue: Different versions showing different trajectories/slopes
# ============================================================================

library(haven)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(stringr)
library(ggplot2)
library(viridis)
library(broom)
library(survey)

cat("=== TRAJECTORY DIAGNOSTIC v2.5 ===\n")
cat("Investigating inconsistent annual change trajectories across versions\n\n")

# ============================================================================
# LOAD AND EXAMINE OUR CURRENT DATASET
# ============================================================================

data_v2_4 <- read_csv("data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv")

cat("=== CURRENT DATASET (v2.4) EXAMINATION ===\n")
cat(sprintf("Total observations: %d\n", nrow(data_v2_4)))
cat(sprintf("Years covered: %s\n", paste(sort(unique(data_v2_4$survey_year)), collapse = ", ")))

# ============================================================================
# DIAGNOSTIC 1: DATA QUALITY ISSUES
# ============================================================================

cat("\n=== DIAGNOSTIC 1: DATA QUALITY BY YEAR ===\n")

data_quality_by_year <- data_v2_4 %>%
  group_by(survey_year) %>%
  summarize(
    total_obs = n(),
    valid_generation = sum(!is.na(immigrant_generation)),
    gen_1_2_3 = sum(immigrant_generation %in% c(1, 2, 3), na.rm = TRUE),
    
    # Index availability
    liberalism_available = sum(!is.na(liberalism_index)),
    restrictionism_available = sum(!is.na(restrictionism_index)),
    concern_available = sum(!is.na(concern_index)),
    
    # Index means (for stability check)
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    restrictionism_mean = mean(restrictionism_index, na.rm = TRUE),
    concern_mean = mean(concern_index, na.rm = TRUE),
    
    # Check for extreme values
    liberalism_range = ifelse(liberalism_available > 0, 
                             max(liberalism_index, na.rm = TRUE) - min(liberalism_index, na.rm = TRUE), 
                             NA),
    
    .groups = "drop"
  )

print(data_quality_by_year)

# ============================================================================
# DIAGNOSTIC 2: GENERATION CODING CONSISTENCY
# ============================================================================

cat("\n=== DIAGNOSTIC 2: GENERATION CODING CONSISTENCY ===\n")

generation_consistency <- data_v2_4 %>%
  group_by(survey_year) %>%
  summarize(
    # Distribution of generations
    gen_1_pct = mean(immigrant_generation == 1, na.rm = TRUE) * 100,
    gen_2_pct = mean(immigrant_generation == 2, na.rm = TRUE) * 100,
    gen_3_pct = mean(immigrant_generation == 3, na.rm = TRUE) * 100,
    
    # Underlying variables availability
    place_birth_available = sum(!is.na(place_birth)),
    parent_nativity_available = sum(!is.na(parent_nativity)),
    
    # Check for suspicious patterns
    all_gen_2 = all(immigrant_generation == 2, na.rm = TRUE),
    mostly_missing_gen = mean(is.na(immigrant_generation)) > 0.9,
    
    .groups = "drop"
  )

print(generation_consistency)

# Flag problematic years
problematic_years <- generation_consistency %>%
  filter(all_gen_2 | mostly_missing_gen | gen_1_pct > 95 | gen_1_pct < 5) %>%
  pull(survey_year)

if (length(problematic_years) > 0) {
  cat("\n⚠️  PROBLEMATIC YEARS DETECTED:\n")
  cat(paste(problematic_years, collapse = ", "), "\n")
} else {
  cat("\n✅ No obvious generation coding issues detected\n")
}

# ============================================================================
# DIAGNOSTIC 3: INDEX CONSTRUCTION CONSISTENCY
# ============================================================================

cat("\n=== DIAGNOSTIC 3: INDEX CONSTRUCTION CONSISTENCY ===\n")

# Check component variable availability by year
component_availability <- data_v2_4 %>%
  group_by(survey_year) %>%
  summarize(
    # Liberalism components
    legalization_support_n = sum(!is.na(legalization_support)),
    daca_support_n = sum(!is.na(daca_support)),
    immigrants_strengthen_n = sum(!is.na(immigrants_strengthen)),
    
    # Restrictionism components  
    immigration_level_opinion_n = sum(!is.na(immigration_level_opinion)),
    border_wall_support_n = sum(!is.na(border_wall_support)),
    deportation_policy_support_n = sum(!is.na(deportation_policy_support)),
    border_security_support_n = sum(!is.na(border_security_support)),
    immigration_importance_n = sum(!is.na(immigration_importance)),
    
    # Concern components
    deportation_worry_n = sum(!is.na(deportation_worry)),
    
    # Index validity
    liberalism_components_avg = mean(liberalism_components, na.rm = TRUE),
    restrictionism_components_avg = mean(restrictionism_components, na.rm = TRUE),
    
    .groups = "drop"
  )

print(component_availability)

# ============================================================================
# DIAGNOSTIC 4: METHODOLOGICAL INCONSISTENCIES
# ============================================================================

cat("\n=== DIAGNOSTIC 4: POTENTIAL METHODOLOGICAL ISSUES ===\n")

# Check for years with very different sample compositions
methodological_checks <- data_v2_4 %>%
  filter(!is.na(immigrant_generation) & immigrant_generation %in% c(1, 2, 3)) %>%
  group_by(survey_year, immigrant_generation) %>%
  summarize(
    n = n(),
    liberalism_mean = mean(liberalism_index, na.rm = TRUE),
    liberalism_sd = sd(liberalism_index, na.rm = TRUE),
    
    # Check for standardization issues
    liberalism_min = min(liberalism_index, na.rm = TRUE),
    liberalism_max = max(liberalism_index, na.rm = TRUE),
    
    .groups = "drop"
  ) %>%
  group_by(immigrant_generation) %>%
  mutate(
    # Flag years with extreme values compared to other years for same generation
    extreme_mean = abs(liberalism_mean - median(liberalism_mean, na.rm = TRUE)) > 2 * mad(liberalism_mean, na.rm = TRUE),
    extreme_range = (liberalism_max - liberalism_min) > 2 * median(liberalism_max - liberalism_min, na.rm = TRUE)
  ) %>%
  ungroup()

extreme_cases <- methodological_checks %>%
  filter(extreme_mean | extreme_range)

if (nrow(extreme_cases) > 0) {
  cat("\n⚠️  EXTREME VALUES DETECTED:\n")
  print(extreme_cases)
} else {
  cat("\n✅ No extreme value issues detected\n")
}

# ============================================================================
# DIAGNOSTIC 5: REGRESSION STABILITY TEST
# ============================================================================

cat("\n=== DIAGNOSTIC 5: REGRESSION STABILITY BY DATA SUBSET ===\n")

# Function to run regression with different data subsets
test_regression_stability <- function(data, index_name, generation_val) {
  
  subset_data <- data %>%
    filter(!is.na(.data[[index_name]]) & immigrant_generation == generation_val)
  
  if (nrow(subset_data) < 10 || length(unique(subset_data$survey_year)) < 3) {
    return(tibble(
      test = "insufficient_data",
      slope = NA,
      p_value = NA,
      n_years = length(unique(subset_data$survey_year)),
      n_obs = nrow(subset_data)
    ))
  }
  
  # Test different subsets
  results <- list()
  
  # Full data
  design_full <- svydesign(ids = ~1, weights = ~rep(1, nrow(subset_data)), data = subset_data)
  model_full <- svyglm(as.formula(paste(index_name, "~ survey_year")), design = design_full)
  coef_full <- summary(model_full)$coefficients
  
  results$full <- tibble(
    test = "full_data",
    slope = coef_full[2, 1],
    p_value = coef_full[2, 4],
    n_years = length(unique(subset_data$survey_year)),
    n_obs = nrow(subset_data)
  )
  
  # Exclude extreme years (if any)
  year_means <- subset_data %>%
    group_by(survey_year) %>%
    summarize(mean_val = mean(.data[[index_name]], na.rm = TRUE), .groups = "drop")
  
  median_mean <- median(year_means$mean_val, na.rm = TRUE)
  mad_mean <- mad(year_means$mean_val, na.rm = TRUE)
  
  extreme_years <- year_means %>%
    filter(abs(mean_val - median_mean) > 2 * mad_mean) %>%
    pull(survey_year)
  
  if (length(extreme_years) > 0 && length(unique(subset_data$survey_year)) - length(extreme_years) >= 3) {
    subset_no_extreme <- subset_data %>% filter(!survey_year %in% extreme_years)
    
    design_no_extreme <- svydesign(ids = ~1, weights = ~rep(1, nrow(subset_no_extreme)), data = subset_no_extreme)
    model_no_extreme <- svyglm(as.formula(paste(index_name, "~ survey_year")), design = design_no_extreme)
    coef_no_extreme <- summary(model_no_extreme)$coefficients
    
    results$no_extreme <- tibble(
      test = "exclude_extreme_years",
      slope = coef_no_extreme[2, 1],
      p_value = coef_no_extreme[2, 4],
      n_years = length(unique(subset_no_extreme$survey_year)),
      n_obs = nrow(subset_no_extreme),
      excluded_years = paste(extreme_years, collapse = ", ")
    )
  }
  
  return(bind_rows(results))
}

# Test stability for each generation and index
stability_tests <- expand_grid(
  generation = c(1, 2, 3),
  index = c("liberalism_index", "restrictionism_index", "concern_index")
) %>%
  rowwise() %>%
  mutate(
    results = list(test_regression_stability(data_v2_4, index, generation))
  ) %>%
  ungroup() %>%
  unnest(results)

print("=== REGRESSION STABILITY TESTS ===")
print(stability_tests)

# ============================================================================
# DIAGNOSTIC 6: COMPARE KEY FINDINGS TO IDENTIFY PATTERN
# ============================================================================

cat("\n=== DIAGNOSTIC 6: SUMMARY OF POTENTIAL ISSUES ===\n")

# Identify the most likely culprits
issues_found <- list()

# Check 1: Years with insufficient data
insufficient_data_years <- data_quality_by_year %>%
  filter(gen_1_2_3 < 50) %>%  # Less than 50 respondents with valid generation
  pull(survey_year)

if (length(insufficient_data_years) > 0) {
  issues_found$insufficient_data <- insufficient_data_years
  cat(sprintf("⚠️  Years with insufficient data: %s\n", paste(insufficient_data_years, collapse = ", ")))
}

# Check 2: Years with missing indices
missing_index_years <- data_quality_by_year %>%
  filter(liberalism_available < 10 & restrictionism_available < 10 & concern_available < 10) %>%
  pull(survey_year)

if (length(missing_index_years) > 0) {
  issues_found$missing_indices <- missing_index_years
  cat(sprintf("⚠️  Years with missing indices: %s\n", paste(missing_index_years, collapse = ", ")))
}

# Check 3: Years with extreme index composition
extreme_composition_years <- component_availability %>%
  filter(
    (liberalism_components_avg < 0.5 & liberalism_components_avg > 0) |  # Very few components
    (restrictionism_components_avg < 0.5 & restrictionism_components_avg > 0)
  ) %>%
  pull(survey_year)

if (length(extreme_composition_years) > 0) {
  issues_found$extreme_composition <- extreme_composition_years
  cat(sprintf("⚠️  Years with extreme index composition: %s\n", paste(extreme_composition_years, collapse = ", ")))
}

# Check 4: Large slope differences between stability tests
unstable_slopes <- stability_tests %>%
  group_by(generation, index) %>%
  filter(n() > 1) %>%  # Only where we have multiple tests
  summarize(
    slope_range = max(slope, na.rm = TRUE) - min(slope, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(slope_range > 0.01)  # Slopes differ by more than 0.01

if (nrow(unstable_slopes) > 0) {
  issues_found$unstable_slopes <- unstable_slopes
  cat("⚠️  Unstable regression slopes detected:\n")
  print(unstable_slopes)
}

# ============================================================================
# SAVE DIAGNOSTIC RESULTS
# ============================================================================

# Save all diagnostic results
write_csv(data_quality_by_year, "outputs/summaries/diagnostic_data_quality_v2_5.csv")
write_csv(generation_consistency, "outputs/summaries/diagnostic_generation_consistency_v2_5.csv")
write_csv(component_availability, "outputs/summaries/diagnostic_component_availability_v2_5.csv")
write_csv(methodological_checks, "outputs/summaries/diagnostic_methodological_checks_v2_5.csv")
write_csv(stability_tests, "outputs/summaries/diagnostic_stability_tests_v2_5.csv")

# Create summary report
summary_report <- tibble(
  diagnostic_category = names(issues_found),
  issues_detected = map_chr(issues_found, ~paste(.x, collapse = ", "))
)

write_csv(summary_report, "outputs/summaries/diagnostic_summary_report_v2_5.csv")

cat("\n=== TRAJECTORY DIAGNOSTIC v2.5 COMPLETE ===\n")
cat("Diagnostic files saved:\n")
cat("  - outputs/summaries/diagnostic_data_quality_v2_5.csv\n")
cat("  - outputs/summaries/diagnostic_generation_consistency_v2_5.csv\n")
cat("  - outputs/summaries/diagnostic_component_availability_v2_5.csv\n")
cat("  - outputs/summaries/diagnostic_methodological_checks_v2_5.csv\n")
cat("  - outputs/summaries/diagnostic_stability_tests_v2_5.csv\n")
cat("  - outputs/summaries/diagnostic_summary_report_v2_5.csv\n")

if (length(issues_found) == 0) {
  cat("\n✅ No major methodological issues detected.\n")
  cat("   Different trajectories may be due to:\n")
  cat("   - Different variable selections across versions\n")
  cat("   - Different year ranges included\n")
  cat("   - Different generation coding implementations\n")
} else {
  cat(sprintf("\n⚠️  %d categories of issues detected. Review diagnostic files for details.\n", length(issues_found)))
}