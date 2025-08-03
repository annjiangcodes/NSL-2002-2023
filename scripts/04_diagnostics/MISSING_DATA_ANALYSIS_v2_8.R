# =============================================================================
# MISSING DATA ANALYSIS v2.8 - COMPREHENSIVE ASSESSMENT
# =============================================================================
# Purpose: Comprehensive missing data analysis and imputation strategy development
#          for the immigration attitudes longitudinal dataset
# Version: 2.8 (January 2025)
# Previous: v2.8 achieved survey-weighted representative estimates
# Key Focus: MISSING DATA PATTERNS, MECHANISMS, AND IMPUTATION STRATEGIES
# Data Coverage: 37,496+ observations across 14 survey years (2002-2023)
# =============================================================================

library(haven)
library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)
library(VIM)      # For missing data visualization
library(mice)     # For multiple imputation
library(naniar)   # For missing data exploration

cat("=================================================================\n")
cat("MISSING DATA ANALYSIS v2.8 - COMPREHENSIVE ASSESSMENT\n") 
cat("=================================================================\n")

# =============================================================================
# 1. LOAD COMPREHENSIVE DATASET AND EXAMINE MISSING PATTERNS
# =============================================================================

cat("\n1. LOADING DATASET AND INITIAL MISSING DATA ASSESSMENT\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Load the v2.7 dataset (most comprehensive)
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

# Define key variable groups
key_variables <- list(
  "immigration_attitudes" = c("liberalism_index", "restrictionism_index", "concern_index",
                              "legalization_support", "immigration_level_opinion", 
                              "border_wall_support", "deportation_worry"),
  
  "generation_nativity" = c("immigrant_generation", "place_birth", "parent_nativity"),
  
  "demographics" = c("age", "gender", "education", "income", "race", "ethnicity"),
  
  "geographic" = c("state", "region", "metro_area"),
  
  "political" = c("political_party", "ideology", "political_engagement"),
  
  "survey_methodology" = c("survey_weight", "interview_language", "survey_mode")
)

# Assess missing data for key variable groups
key_var_missing <- list()

for (group_name in names(key_variables)) {
  group_vars <- key_variables[[group_name]]
  available_vars <- intersect(group_vars, names(data))
  
  if (length(available_vars) > 0) {
    group_missing <- data %>%
      select(all_of(available_vars)) %>%
      summarise_all(~sum(is.na(.))) %>%
      pivot_longer(everything(), names_to = "variable", values_to = "missing_count") %>%
      mutate(
        variable_group = group_name,
        missing_percentage = round(100 * missing_count / nrow(data), 2)
      )
    
    key_var_missing[[group_name]] <- group_missing
    
    cat("\n", toupper(group_name), "VARIABLES:\n")
    print(group_missing %>% select(variable, missing_count, missing_percentage))
  }
}

# Combine key variable missing data
combined_key_missing <- bind_rows(key_var_missing)
write_csv(combined_key_missing, "outputs/key_variables_missing_v2_8.csv")

# =============================================================================
# 4. TEMPORAL MISSING DATA PATTERNS
# =============================================================================

cat("\n4. TEMPORAL MISSING DATA PATTERNS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Missing data by survey year
yearly_missing <- data %>%
  group_by(survey_year) %>%
  summarise(
    n_observations = n(),
    
    # Immigration attitudes
    liberalism_missing = sum(is.na(liberalism_index)),
    restrictionism_missing = sum(is.na(restrictionism_index)),
    concern_missing = sum(is.na(concern_index)),
    
    # Generation variables
    generation_missing = sum(is.na(immigrant_generation)),
    
    # Calculate percentages
    liberalism_missing_pct = round(100 * liberalism_missing / n_observations, 1),
    restrictionism_missing_pct = round(100 * restrictionism_missing / n_observations, 1),
    concern_missing_pct = round(100 * concern_missing / n_observations, 1),
    generation_missing_pct = round(100 * generation_missing / n_observations, 1),
    
    .groups = 'drop'
  ) %>%
  arrange(survey_year)

cat("Missing data patterns by year:\n")
print(yearly_missing %>% 
        select(survey_year, n_observations, liberalism_missing_pct, 
               restrictionism_missing_pct, concern_missing_pct, generation_missing_pct))

# Export yearly missing patterns
write_csv(yearly_missing, "outputs/yearly_missing_patterns_v2_8.csv")

# =============================================================================
# 5. MISSING DATA MECHANISM ANALYSIS
# =============================================================================

cat("\n5. MISSING DATA MECHANISM ANALYSIS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Test for systematic missingness patterns
# Focus on key immigration attitude variables

# Create missingness indicators for key variables
data_with_missing_flags <- data %>%
  mutate(
    liberalism_missing = is.na(liberalism_index),
    restrictionism_missing = is.na(restrictionism_index), 
    concern_missing = is.na(concern_index),
    generation_missing = is.na(immigrant_generation)
  )

# Test correlation between missingness patterns
missing_pattern_cors <- data_with_missing_flags %>%
  select(liberalism_missing, restrictionism_missing, concern_missing, generation_missing) %>%
  cor(use = "complete.obs")

cat("Correlation between missingness patterns:\n")
print(round(missing_pattern_cors, 3))

# Test if missingness is related to survey year (MAR test)
cat("\n=== MISSING AT RANDOM (MAR) TESTS ===\n")

# Test: Is liberalism missingness related to survey year?
if (sum(!is.na(data$liberalism_index)) > 0) {
  liberalism_year_test <- glm(is.na(liberalism_index) ~ factor(survey_year), 
                              data = data, family = "binomial")
  liberalism_year_p <- anova(liberalism_year_test, test = "Chisq")$`Pr(>Chi)`[2]
  cat("Liberalism missingness by year p-value:", round(liberalism_year_p, 4), "\n")
}

# Test: Is restrictionism missingness related to survey year?
if (sum(!is.na(data$restrictionism_index)) > 0) {
  restrictionism_year_test <- glm(is.na(restrictionism_index) ~ factor(survey_year), 
                                  data = data, family = "binomial")
  restrictionism_year_p <- anova(restrictionism_year_test, test = "Chisq")$`Pr(>Chi)`[2]
  cat("Restrictionism missingness by year p-value:", round(restrictionism_year_p, 4), "\n")
}

# Test: Is generation missingness related to survey year?
if (sum(!is.na(data$immigrant_generation)) > 0) {
  generation_year_test <- glm(is.na(immigrant_generation) ~ factor(survey_year), 
                              data = data, family = "binomial")
  generation_year_p <- anova(generation_year_test, test = "Chisq")$`Pr(>Chi)`[2]
  cat("Generation missingness by year p-value:", round(generation_year_p, 4), "\n")
}

# =============================================================================
# 6. MISSING DATA VISUALIZATION
# =============================================================================

cat("\n6. MISSING DATA VISUALIZATION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Select key variables for visualization
viz_vars <- c("survey_year", "liberalism_index", "restrictionism_index", "concern_index",
              "immigrant_generation", "place_birth", "parent_nativity")

# Check which variables exist
available_viz_vars <- intersect(viz_vars, names(data))
viz_data <- data %>% select(all_of(available_viz_vars))

# Missing data pattern plot
if (require(VIM, quietly = TRUE)) {
  
  # Create missingness pattern plot
  cat("Creating missing data pattern visualization...\n")
  
  png("outputs/missing_data_patterns_v2_8.png", width = 1200, height = 800, res = 150)
  VIM::aggr(viz_data, col = c('navyblue', 'red'), numbers = TRUE, sortVars = TRUE)
  dev.off()
  
  cat("Exported: outputs/missing_data_patterns_v2_8.png\n")
  
  # Missing data heatmap by year
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
    geom_tile() +
    scale_fill_gradient(low = "white", high = "red", name = "Missing %") +
    labs(
      title = "Missing Data Patterns by Survey Year",
      subtitle = "Immigration Attitudes Longitudinal Dataset",
      x = "Survey Year",
      y = "Variable",
      caption = "Red = High missingness, White = Complete data"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      plot.title = element_text(size = 14, face = "bold")
    )
  
  ggsave("outputs/missing_data_heatmap_v2_8.png", p_heatmap, 
         width = 12, height = 6, dpi = 300)
  
  cat("Exported: outputs/missing_data_heatmap_v2_8.png\n")
}

# =============================================================================
# 7. IMPUTATION STRATEGY RECOMMENDATIONS
# =============================================================================

cat("\n7. IMPUTATION STRATEGY RECOMMENDATIONS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Analyze imputation feasibility for key variables
imputation_assessment <- missing_by_variable %>%
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
  )

# Focus on key immigration attitude variables
key_imputation_vars <- c("liberalism_index", "restrictionism_index", "concern_index",
                         "immigrant_generation", "place_birth", "parent_nativity")

key_imputation_summary <- imputation_assessment %>%
  filter(variable %in% key_imputation_vars) %>%
  select(variable, missing_percentage, imputation_strategy, analysis_inclusion)

cat("Imputation recommendations for key variables:\n")
print(key_imputation_summary)

# Create comprehensive imputation plan
imputation_plan <- data.frame(
  variable_group = c("Immigration Attitudes", "Generation Variables", "Demographics"),
  strategy = c(
    "Multiple imputation using survey year, generation, and available attitudes as predictors",
    "Listwise deletion for generation; use auxiliary demographic variables for imputation", 
    "Multiple imputation with chained equations (MICE) using temporal and geographic predictors"
  ),
  priority = c("High", "High", "Medium"),
  rationale = c(
    "Core outcome variables - essential for analysis",
    "Key stratification variable - must be accurate", 
    "Important controls - can use imputation with appropriate uncertainty"
  )
)

cat("\n=== COMPREHENSIVE IMPUTATION PLAN ===\n")
print(imputation_plan)

# Export imputation assessment and plan
write_csv(imputation_assessment, "outputs/imputation_assessment_v2_8.csv")
write_csv(imputation_plan, "outputs/imputation_plan_v2_8.csv")

# =============================================================================
# 8. COMPLETE CASE ANALYSIS FEASIBILITY
# =============================================================================

cat("\n8. COMPLETE CASE ANALYSIS FEASIBILITY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Assess complete cases for different analysis scenarios
scenarios <- list(
  "Core Immigration Analysis" = c("survey_year", "liberalism_index", "restrictionism_index", "immigrant_generation"),
  "Full Three-Index Analysis" = c("survey_year", "liberalism_index", "restrictionism_index", "concern_index", "immigrant_generation"),
  "Comprehensive Analysis" = c("survey_year", "liberalism_index", "restrictionism_index", "concern_index", 
                               "immigrant_generation", "place_birth", "parent_nativity")
)

complete_case_summary <- list()

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
  
  complete_case_summary[[scenario_name]] <- list(
    total_complete = nrow(complete_cases),
    completion_rate = round(100 * nrow(complete_cases) / nrow(data), 1),
    years_covered = length(unique(complete_cases$survey_year)),
    yearly_detail = yearly_complete
  )
  
  cat("\n", toupper(scenario_name), ":\n")
  cat("Complete cases:", nrow(complete_cases), "of", nrow(data), 
      "(", round(100 * nrow(complete_cases) / nrow(data), 1), "%)\n")
  cat("Years with data:", length(unique(complete_cases$survey_year)), "\n")
}

# Summary statistics
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
lib_missing <- missing_by_variable$missing_percentage[missing_by_variable$variable == "liberalism_index"]
rest_missing <- missing_by_variable$missing_percentage[missing_by_variable$variable == "restrictionism_index"]
conc_missing <- missing_by_variable$missing_percentage[missing_by_variable$variable == "concern_index"]

if (length(lib_missing) > 0) cat("- Liberalism Index:", 100 - lib_missing, "% coverage\n")
if (length(rest_missing) > 0) cat("- Restrictionism Index:", 100 - rest_missing, "% coverage\n")
if (length(conc_missing) > 0) cat("- Concern Index:", 100 - conc_missing, "% coverage\n")

save.image("outputs/missing_data_analysis_v2_8_workspace.RData")

cat("\n=================================================================\n")
cat("MISSING DATA ANALYSIS v2.8 COMPLETE\n")
cat("SUCCESS: Comprehensive missing data assessment completed\n")
cat("OUTPUTS: Visualizations, assessments, and imputation strategies ready\n")
cat("NEXT: Implement imputation strategy and finalize analysis\n")
cat("=================================================================\n") 