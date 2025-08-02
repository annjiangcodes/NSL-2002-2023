# =============================================================================
# MISSING DATA ANALYSIS v2.8 - BASIC ASSESSMENT  
# =============================================================================
# Purpose: Basic missing data analysis using standard R packages
# Version: 2.8 (January 2025)
# Previous: v2.8 achieved survey-weighted representative estimates
# Key Focus: MISSING DATA PATTERNS AND BASIC IMPUTATION STRATEGIES
# Data Coverage: 37,496+ observations across 14 survey years (2002-2023)
# =============================================================================

library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)

cat("=================================================================\n")
cat("MISSING DATA ANALYSIS v2.8 - BASIC ASSESSMENT\n") 
cat("=================================================================\n")

# =============================================================================
# 1. LOAD DATASET AND BASIC MISSING DATA OVERVIEW
# =============================================================================

cat("\n1. LOADING DATASET AND INITIAL MISSING DATA ASSESSMENT\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Load the v2.7 dataset
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

cat("Dataset loaded:", dim(data), "\n")
cat("Years available:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n")

# Basic missing data summary
cat("\n=== BASIC MISSING DATA OVERVIEW ===\n")
total_cells <- nrow(data) * ncol(data)
missing_cells <- sum(is.na(data))
missing_percentage <- round(100 * missing_cells / total_cells, 2)

cat("Total observations:", nrow(data), "\n")
cat("Total variables:", ncol(data), "\n")
cat("Total cells:", total_cells, "\n")
cat("Missing cells:", missing_cells, "\n")
cat("Overall missing percentage:", missing_percentage, "%\n")

# =============================================================================
# 2. VARIABLE-LEVEL MISSING DATA ANALYSIS
# =============================================================================

cat("\n2. VARIABLE-LEVEL MISSING DATA ANALYSIS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Calculate missing data by variable
missing_by_variable <- data %>%
  summarise_all(~sum(is.na(.))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
  mutate(
    missing_percentage = round(100 * missing_count / nrow(data), 2),
    coverage_percentage = round(100 - missing_percentage, 2)
  ) %>%
  arrange(desc(missing_count))

cat("Variables by missing data (top 15):\n")
print(missing_by_variable %>% head(15))

# Categorize variables by missing data levels
variable_categories <- missing_by_variable %>%
  mutate(
    missing_category = case_when(
      missing_percentage == 0 ~ "Complete (0%)",
      missing_percentage < 10 ~ "Excellent (0-10%)",
      missing_percentage < 25 ~ "Good (10-25%)", 
      missing_percentage < 50 ~ "Fair (25-50%)",
      missing_percentage < 75 ~ "Poor (50-75%)",
      TRUE ~ "Very Poor (75%+)"
    )
  )

category_summary <- variable_categories %>%
  count(missing_category) %>%
  arrange(factor(missing_category, levels = c("Complete (0%)", "Excellent (0-10%)", 
                                              "Good (10-25%)", "Fair (25-50%)", 
                                              "Poor (50-75%)", "Very Poor (75%+)")))

cat("\n=== VARIABLE QUALITY CATEGORIES ===\n")
print(category_summary)

# Export variable-level missing summary
write_csv(missing_by_variable, "outputs/missing_data_by_variable_v2_8.csv")
cat("Exported: outputs/missing_data_by_variable_v2_8.csv\n")

# =============================================================================
# 3. KEY VARIABLES MISSING DATA ASSESSMENT
# =============================================================================

cat("\n3. KEY VARIABLES MISSING DATA ASSESSMENT\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Focus on key immigration attitude and generation variables
key_vars <- c("liberalism_index", "restrictionism_index", "concern_index",
              "immigrant_generation", "place_birth", "parent_nativity",
              "legalization_support", "immigration_level_opinion", "deportation_worry")

available_key_vars <- intersect(key_vars, names(data))

key_missing_summary <- missing_by_variable %>%
  filter(variable %in% available_key_vars) %>%
  arrange(missing_percentage)

cat("Key variables missing data summary:\n")
print(key_missing_summary)

# =============================================================================
# 4. TEMPORAL MISSING DATA PATTERNS
# =============================================================================

cat("\n4. TEMPORAL MISSING DATA PATTERNS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Missing data by survey year for key variables
yearly_missing <- data %>%
  group_by(survey_year) %>%
  summarise(
    n_observations = n(),
    
    # Immigration attitudes
    liberalism_missing_pct = round(100 * sum(is.na(liberalism_index)) / n(), 1),
    restrictionism_missing_pct = round(100 * sum(is.na(restrictionism_index)) / n(), 1),
    concern_missing_pct = round(100 * sum(is.na(concern_index)) / n(), 1),
    
    # Generation variables
    generation_missing_pct = round(100 * sum(is.na(immigrant_generation)) / n(), 1),
    
    .groups = 'drop'
  ) %>%
  arrange(survey_year)

cat("Missing data patterns by year:\n")
print(yearly_missing)

# Export yearly missing patterns
write_csv(yearly_missing, "outputs/yearly_missing_patterns_v2_8.csv")

# =============================================================================
# 5. MISSING DATA VISUALIZATION
# =============================================================================

cat("\n5. MISSING DATA VISUALIZATION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Create missing data heatmap by year
yearly_missing_viz <- data %>%
  select(survey_year, liberalism_index, restrictionism_index, concern_index, immigrant_generation) %>%
  group_by(survey_year) %>%
  summarise(
    liberalism_missing_pct = 100 * sum(is.na(liberalism_index)) / n(),
    restrictionism_missing_pct = 100 * sum(is.na(restrictionism_index)) / n(),
    concern_missing_pct = 100 * sum(is.na(concern_index)) / n(),
    generation_missing_pct = 100 * sum(is.na(immigrant_generation)) / n(),
    .groups = 'drop'
  ) %>%
  pivot_longer(cols = -survey_year, names_to = "variable", values_to = "missing_pct") %>%
  mutate(variable = str_remove(variable, "_missing_pct"))

# Create heatmap
p_heatmap <- yearly_missing_viz %>%
  ggplot(aes(x = survey_year, y = variable, fill = missing_pct)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "lightblue", high = "red", name = "Missing %") +
  labs(
    title = "Missing Data Patterns by Survey Year",
    subtitle = "Immigration Attitudes Longitudinal Dataset",
    x = "Survey Year",
    y = "Variable",
    caption = "Red = High missingness, Blue = Complete data"
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave("outputs/missing_data_heatmap_v2_8.png", p_heatmap, 
       width = 12, height = 6, dpi = 300)

cat("Exported: outputs/missing_data_heatmap_v2_8.png\n")

# Create variable coverage barplot
p_coverage <- missing_by_variable %>%
  filter(variable %in% available_key_vars) %>%
  mutate(variable = reorder(variable, coverage_percentage)) %>%
  ggplot(aes(x = variable, y = coverage_percentage)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = paste0(coverage_percentage, "%")), 
            hjust = -0.1, size = 3) +
  coord_flip() +
  labs(
    title = "Data Coverage for Key Variables",
    subtitle = "Immigration Attitudes Longitudinal Dataset",
    x = "Variable",
    y = "Coverage Percentage (%)",
    caption = "Higher percentage = better data coverage"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold")
  )

ggsave("outputs/key_variables_coverage_v2_8.png", p_coverage, 
       width = 10, height = 6, dpi = 300)

cat("Exported: outputs/key_variables_coverage_v2_8.png\n")

# =============================================================================
# 6. COMPLETE CASE ANALYSIS FEASIBILITY
# =============================================================================

cat("\n6. COMPLETE CASE ANALYSIS FEASIBILITY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Define analysis scenarios
scenarios <- list(
  "Core Immigration Analysis" = c("survey_year", "liberalism_index", "restrictionism_index", "immigrant_generation"),
  "Full Three-Index Analysis" = c("survey_year", "liberalism_index", "restrictionism_index", "concern_index", "immigrant_generation"),
  "Comprehensive Analysis" = c("survey_year", "liberalism_index", "restrictionism_index", "concern_index", 
                               "immigrant_generation", "place_birth", "parent_nativity")
)

complete_case_results <- list()

for (scenario_name in names(scenarios)) {
  scenario_vars <- intersect(scenarios[[scenario_name]], names(data))
  
  complete_cases <- data %>%
    select(all_of(scenario_vars)) %>%
    filter(complete.cases(.))
  
  # Calculate complete case coverage by year
  yearly_complete <- complete_cases %>%
    count(survey_year) %>%
    rename(complete_cases = n) %>%
    left_join(
      data %>% count(survey_year) %>% rename(total_cases = n),
      by = "survey_year"
    ) %>%
    mutate(
      completion_rate = round(100 * complete_cases / total_cases, 1)
    )
  
  complete_case_results[[scenario_name]] <- list(
    total_complete = nrow(complete_cases),
    completion_rate = round(100 * nrow(complete_cases) / nrow(data), 1),
    years_covered = length(unique(complete_cases$survey_year)),
    yearly_detail = yearly_complete
  )
  
  cat("\n", toupper(scenario_name), ":\n")
  cat("Complete cases:", nrow(complete_cases), "of", nrow(data), 
      "(", round(100 * nrow(complete_cases) / nrow(data), 1), "%)\n")
  cat("Years with data:", length(unique(complete_cases$survey_year)), "\n")
  
  # Show years with good coverage (>50%)
  good_years <- yearly_complete %>% filter(completion_rate > 50)
  if (nrow(good_years) > 0) {
    cat("Years with >50% complete cases:", paste(good_years$survey_year, collapse = ", "), "\n")
  }
}

# =============================================================================
# 7. IMPUTATION STRATEGY RECOMMENDATIONS
# =============================================================================

cat("\n7. IMPUTATION STRATEGY RECOMMENDATIONS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Analyze imputation feasibility for key variables
imputation_assessment <- missing_by_variable %>%
  filter(variable %in% available_key_vars) %>%
  mutate(
    imputation_strategy = case_when(
      missing_percentage == 0 ~ "No imputation needed",
      missing_percentage < 5 ~ "Simple imputation (mean/mode)",
      missing_percentage < 15 ~ "Multiple imputation recommended", 
      missing_percentage < 30 ~ "Multiple imputation with auxiliaries",
      missing_percentage < 50 ~ "Consider exclusion or specialized methods",
      TRUE ~ "Likely exclude from analysis"
    ),
    
    analysis_inclusion = case_when(
      missing_percentage < 20 ~ "Include in main analysis",
      missing_percentage < 40 ~ "Include with caution/sensitivity analysis",
      TRUE ~ "Consider exclusion"
    )
  ) %>%
  arrange(missing_percentage)

cat("Imputation recommendations for key variables:\n")
print(imputation_assessment %>% 
        select(variable, missing_percentage, imputation_strategy, analysis_inclusion))

# Create comprehensive recommendations
recommendations <- data.frame(
  scenario = c("Conservative Approach", "Moderate Approach", "Comprehensive Approach"),
  strategy = c(
    "Use complete cases only for core variables (liberalism, restrictionism, generation)",
    "Multiple imputation for variables with <30% missing, complete cases for generation",
    "Multiple imputation for all variables with <50% missing, careful sensitivity analysis"
  ),
  expected_sample = c(
    paste(complete_case_results[["Core Immigration Analysis"]]$total_complete, "observations"),
    paste(round(nrow(data) * 0.7), "observations (estimated)"),
    paste(round(nrow(data) * 0.85), "observations (estimated)")
  ),
  pros = c(
    "Most conservative, no bias from imputation",
    "Good balance of sample size and data quality",
    "Maximum sample size, most power for analysis"
  ),
  cons = c(
    "Reduced sample size, potential selection bias",
    "Some uncertainty from imputation",
    "Higher uncertainty, more complex analysis"
  )
)

cat("\n=== ANALYSIS STRATEGY RECOMMENDATIONS ===\n")
print(recommendations)

# Export all results
write_csv(imputation_assessment, "outputs/imputation_assessment_v2_8.csv")
write_csv(recommendations, "outputs/analysis_strategy_recommendations_v2_8.csv")

# Create complete case summary
complete_case_summary <- data.frame(
  scenario = names(complete_case_results),
  complete_cases = sapply(complete_case_results, function(x) x$total_complete),
  completion_rate = sapply(complete_case_results, function(x) x$completion_rate),
  years_covered = sapply(complete_case_results, function(x) x$years_covered)
)

write_csv(complete_case_summary, "outputs/complete_case_analysis_summary_v2_8.csv")

# =============================================================================
# 8. SUMMARY AND RECOMMENDATIONS
# =============================================================================

cat("\n=================================================================\n")
cat("MISSING DATA ANALYSIS v2.8 SUMMARY\n")
cat("=================================================================\n")

cat("Dataset Overview:\n")
cat("- Total observations:", nrow(data), "\n")
cat("- Total variables:", ncol(data), "\n") 
cat("- Overall missing percentage:", missing_percentage, "%\n")

cat("\nKey Variable Quality:\n")
excellent_vars <- sum(variable_categories$missing_percentage < 10)
good_vars <- sum(variable_categories$missing_percentage >= 10 & variable_categories$missing_percentage < 25)
fair_vars <- sum(variable_categories$missing_percentage >= 25 & variable_categories$missing_percentage < 50)
poor_vars <- sum(variable_categories$missing_percentage >= 50)

cat("- Excellent coverage (0-10%):", excellent_vars, "variables\n")
cat("- Good coverage (10-25%):", good_vars, "variables\n")
cat("- Fair coverage (25-50%):", fair_vars, "variables\n")
cat("- Poor coverage (50%+):", poor_vars, "variables\n")

cat("\nImmigration Attitudes Coverage:\n")
for (var in c("liberalism_index", "restrictionism_index", "concern_index")) {
  if (var %in% missing_by_variable$variable) {
    coverage <- missing_by_variable$coverage_percentage[missing_by_variable$variable == var]
    cat("- ", var, ":", coverage, "% coverage\n")
  }
}

cat("\nComplete Case Analysis Feasibility:\n")
for (scenario in names(complete_case_results)) {
  result <- complete_case_results[[scenario]]
  cat("- ", scenario, ":", result$total_complete, "complete cases (", 
      result$completion_rate, "%) across", result$years_covered, "years\n")
}

cat("\n=== FINAL RECOMMENDATIONS ===\n")
cat("RECOMMENDED APPROACH: Moderate Strategy\n")
cat("- Use complete cases for generation stratification (high quality required)\n")
cat("- Multiple imputation for immigration attitude indices (<30% missing)\n")
cat("- Conduct sensitivity analysis comparing complete case vs imputed results\n")
cat("- Focus on temporal trends rather than absolute levels for robustness\n")

save.image("outputs/missing_data_analysis_v2_8_workspace.RData")

cat("\n=================================================================\n")
cat("MISSING DATA ANALYSIS v2.8 COMPLETE\n")
cat("SUCCESS: Comprehensive missing data assessment completed\n")
cat("OUTPUTS: Assessments, visualizations, and strategic recommendations ready\n")
cat("READY FOR: Final analytical strategy and publication-quality results\n")
cat("=================================================================\n") 