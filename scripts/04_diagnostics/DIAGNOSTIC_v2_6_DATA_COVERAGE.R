# =============================================================================
# DIAGNOSTIC: v2.6 DATA COVERAGE INVESTIGATION
# =============================================================================
# Purpose: Investigate why we're missing so many data points in visualizations
# Expected: Based on comprehensive_map, should have data for:
# - Legalization: 2002, 2004, 2006, 2010, 2014, 2021, 2022 (7 years)
# - DACA: 2011, 2012, 2018, 2021 (4 years) 
# - Immigration Level: 2002, 2007, 2018 (3 years)
# - Border Wall: 2010, 2018 (2 years)
# - Deportation Policy: 2010, 2021, 2022 (3 years)
# - Border Security: 2010, 2021, 2022 (3 years)
# - Immigration Importance: 2010, 2011, 2012, 2016 (4 years)
# - Deportation Worry: 2007, 2010, 2018, 2021 (4 years)
# =============================================================================

library(readr)
library(dplyr)

cat("=================================================================\n")
cat("DIAGNOSTIC: v2.6 DATA COVERAGE INVESTIGATION\n")
cat("=================================================================\n")

# Load v2.4 dataset
cat("Loading v2.4 dataset...\n")
data <- read_csv("data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv", show_col_types = FALSE)

cat("Dataset dimensions:", dim(data), "\n")
cat("Years available:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n")

# Check all columns
cat("\nAll columns in dataset:\n")
print(names(data))

# Focus on immigration variables
immigration_vars <- c(
  "legalization_support", "daca_support", "immigrants_strengthen",
  "immigration_level_opinion", "border_wall_support", "deportation_policy_support", 
  "border_security_support", "immigration_importance", "deportation_worry",
  "liberalism_index", "restrictionism_index", "concern_index"
)

cat("\nChecking availability of key immigration variables:\n")
for (var in immigration_vars) {
  if (var %in% names(data)) {
    total_non_missing <- sum(!is.na(data[[var]]))
    cat(sprintf("✓ %s: %d non-missing values\n", var, total_non_missing))
  } else {
    cat(sprintf("✗ %s: NOT FOUND\n", var))
  }
}

# Year-by-year breakdown
cat("\n=================================================================\n")
cat("YEAR-BY-YEAR BREAKDOWN\n")
cat("=================================================================\n")

expected_coverage <- list(
  legalization_support = c(2002, 2004, 2006, 2010, 2014, 2021, 2022),
  daca_support = c(2011, 2012, 2018, 2021),
  immigrants_strengthen = c(2006),
  immigration_level_opinion = c(2002, 2007, 2018),
  border_wall_support = c(2010, 2018),
  deportation_policy_support = c(2010, 2021, 2022),
  border_security_support = c(2010, 2021, 2022),
  immigration_importance = c(2010, 2011, 2012, 2016),
  deportation_worry = c(2007, 2010, 2018, 2021)
)

for (year in sort(unique(data$survey_year))) {
  cat(sprintf("\n--- YEAR %d ---\n", year))
  year_data <- data[data$survey_year == year, ]
  cat(sprintf("Total observations: %d\n", nrow(year_data)))
  cat(sprintf("With generation data: %d\n", sum(!is.na(year_data$immigrant_generation))))
  
  for (var in names(expected_coverage)) {
    if (var %in% names(data)) {
      non_missing <- sum(!is.na(year_data[[var]]))
      expected <- year %in% expected_coverage[[var]]
      status <- if (expected && non_missing > 0) "✓ GOOD" else 
                if (expected && non_missing == 0) "✗ MISSING" else 
                if (!expected && non_missing > 0) "? UNEXPECTED" else "- N/A"
      cat(sprintf("  %s: %d observations %s\n", var, non_missing, status))
    }
  }
}

# Check indices construction
cat("\n=================================================================\n")
cat("INDICES CONSTRUCTION CHECK\n")
cat("=================================================================\n")

if (all(c("liberalism_index", "restrictionism_index", "concern_index") %in% names(data))) {
  
  # Check how many observations have each index by year
  indices_summary <- data %>%
    group_by(survey_year) %>%
    summarise(
      total_obs = n(),
      with_generation = sum(!is.na(immigrant_generation)),
      liberalism_obs = sum(!is.na(liberalism_index)),
      restrictionism_obs = sum(!is.na(restrictionism_index)),
      concern_obs = sum(!is.na(concern_index)),
      .groups = "drop"
    )
  
  cat("Indices availability by year:\n")
  print(indices_summary)
  
  # Check component availability
  cat("\nChecking component variables for indices:\n")
  
  # Liberalism components
  lib_components <- c("legalization_support", "daca_support", "immigrants_strengthen")
  lib_available <- lib_components[lib_components %in% names(data)]
  cat(sprintf("Liberalism components available: %s\n", paste(lib_available, collapse = ", ")))
  
  # Restrictionism components  
  rest_components <- c("immigration_level_opinion", "border_wall_support", 
                      "deportation_policy_support", "border_security_support", "immigration_importance")
  rest_available <- rest_components[rest_components %in% names(data)]
  cat(sprintf("Restrictionism components available: %s\n", paste(rest_available, collapse = ", ")))
  
  # Concern components
  conc_components <- c("deportation_worry")
  conc_available <- conc_components[conc_components %in% names(data)]
  cat(sprintf("Concern components available: %s\n", paste(conc_available, collapse = ", ")))
  
} else {
  cat("Some indices are missing from the dataset!\n")
}

# Check for minimum viable years for visualization
cat("\n=================================================================\n")
cat("MINIMUM VIABLE VISUALIZATION REQUIREMENTS\n")
cat("=================================================================\n")

# For meaningful trend analysis, need at least 3 data points per generation per index
min_years_needed <- 3

viable_analysis <- data %>%
  filter(!is.na(immigrant_generation)) %>%
  group_by(immigrant_generation) %>%
  summarise(
    years_with_lib = sum(tapply(!is.na(liberalism_index), survey_year, any)),
    years_with_rest = sum(tapply(!is.na(restrictionism_index), survey_year, any)),
    years_with_conc = sum(tapply(!is.na(concern_index), survey_year, any)),
    .groups = "drop"
  )

cat("Years with data per generation per index:\n")
print(viable_analysis)

cat(sprintf("\nMinimum years needed for trend analysis: %d\n", min_years_needed))
for (i in 1:nrow(viable_analysis)) {
  gen <- viable_analysis$immigrant_generation[i]
  cat(sprintf("Generation %d:\n", gen))
  cat(sprintf("  Liberalism: %d years %s\n", 
              viable_analysis$years_with_lib[i],
              ifelse(viable_analysis$years_with_lib[i] >= min_years_needed, "✓", "✗")))
  cat(sprintf("  Restrictionism: %d years %s\n", 
              viable_analysis$years_with_rest[i],
              ifelse(viable_analysis$years_with_rest[i] >= min_years_needed, "✓", "✗")))
  cat(sprintf("  Concern: %d years %s\n", 
              viable_analysis$years_with_conc[i],
              ifelse(viable_analysis$years_with_conc[i] >= min_years_needed, "✓", "✗")))
}

cat("\n=================================================================\n")
cat("DIAGNOSTIC COMPLETE\n")
cat("=================================================================\n")

# Save diagnostic results
write_csv(indices_summary, "outputs/diagnostic_indices_coverage.csv")
cat("Diagnostic results saved to outputs/diagnostic_indices_coverage.csv\n")