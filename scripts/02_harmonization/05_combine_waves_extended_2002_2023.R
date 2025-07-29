# =============================================================================
# EXTENDED WAVE COMBINATION FOR 2002-2023 LONGITUDINAL DATASET
# =============================================================================
# Purpose: Combine 2002-2012 data with 2014-2023 data for comprehensive dataset
# Creates: 17-year longitudinal dataset with ~30,000+ observations
# Author: Survey Harmonization Extension Project
# =============================================================================

library(dplyr)
library(readr)
library(stringr)
library(purrr)

cat("=== EXTENDED WAVE COMBINATION 2002-2023 ===\n")
cat("Starting at:", as.character(Sys.time()), "\n\n")

# =============================================================================
# LOAD AND VALIDATE ALL AVAILABLE YEARS
# =============================================================================

# Define all possible years
all_years <- c("2002", "2004", "2006", "2007", "2008", "2009", "2010", 
               "2011", "2012", "2014", "2015", "2016", "2018", "2021", "2022", "2023")

# Find available cleaned data files
cleaned_data_dir <- "data/processed/cleaned_data/"
available_files <- list.files(cleaned_data_dir, pattern = "cleaned_\\d{4}\\.csv", full.names = TRUE)

cat("=== AVAILABLE CLEANED DATA FILES ===\n")
for (file in available_files) {
  year <- str_extract(basename(file), "\\d{4}")
  file_size <- file.size(file)
  cat("✅", year, ":", basename(file), "(", round(file_size/1024, 1), "KB )\n")
}

# =============================================================================
# LOAD AND VALIDATE INDIVIDUAL WAVE DATA
# =============================================================================

cat("\n=== LOADING AND VALIDATING WAVE DATA ===\n")

wave_data_list <- list()
total_observations <- 0

for (file in available_files) {
  year <- str_extract(basename(file), "\\d{4}")
  
  tryCatch({
    wave_data <- read_csv(file, show_col_types = FALSE)
    
    cat("Loading", year, "data:\n")
    cat("  Observations:", nrow(wave_data), "\n")
    cat("  Variables:", ncol(wave_data), "\n")
    
    # Validate essential columns
    required_cols <- c("survey_year", "age", "gender", "place_birth", "immigrant_generation")
    missing_cols <- required_cols[!required_cols %in% names(wave_data)]
    
    if (length(missing_cols) > 0) {
      cat("  WARNING: Missing columns:", paste(missing_cols, collapse = ", "), "\n")
    }
    
    # Check data quality
    age_coverage <- round(100 * sum(!is.na(wave_data$age)) / nrow(wave_data), 1)
    gender_coverage <- round(100 * sum(!is.na(wave_data$gender)) / nrow(wave_data), 1)
    place_birth_coverage <- round(100 * sum(!is.na(wave_data$place_birth)) / nrow(wave_data), 1)
    
    cat("  Coverage - Age:", age_coverage, "%, Gender:", gender_coverage, 
        "%, Place birth:", place_birth_coverage, "%\n")
    
    # Store validated data
    wave_data_list[[year]] <- wave_data
    total_observations <- total_observations + nrow(wave_data)
    
    cat("  ✅ Validation passed\n\n")
    
  }, error = function(e) {
    cat("  ❌ ERROR loading", year, ":", e$message, "\n\n")
  })
}

cat("Total waves loaded:", length(wave_data_list), "\n")
cat("Total observations:", total_observations, "\n\n")

# =============================================================================
# COMBINE ALL WAVES INTO COMPREHENSIVE DATASET
# =============================================================================

cat("=== COMBINING ALL WAVES ===\n")

if (length(wave_data_list) == 0) {
  stop("No valid wave data found to combine!")
}

# Combine all waves
combined_data <- bind_rows(wave_data_list)

cat("Combined dataset dimensions:", nrow(combined_data), "x", ncol(combined_data), "\n")

# Ensure consistent column ordering
col_order <- c("survey_year", "age", "gender", "race", "ethnicity", "language_home",
               "citizenship_status", "place_birth", "immigrant_generation", 
               "immigration_attitude", "border_security_attitude", "political_party", 
               "vote_intention", "approval_rating")

# Keep only columns that exist
available_cols <- col_order[col_order %in% names(combined_data)]
combined_data <- combined_data %>% select(all_of(available_cols))

cat("Final column order:", paste(names(combined_data), collapse = ", "), "\n\n")

# =============================================================================
# COMPREHENSIVE DATA VALIDATION
# =============================================================================

cat("=== FINAL DATASET VALIDATION ===\n")

# Check observations per year
obs_per_year <- combined_data %>% 
  count(survey_year, sort = TRUE) %>%
  arrange(survey_year)

cat("Observations per year:\n")
print(obs_per_year)

# Calculate coverage statistics for each variable
cat("\n=== VARIABLE COVERAGE ANALYSIS ===\n")

coverage_stats <- combined_data %>%
  summarise(across(everything(), ~ list(
    total_obs = length(.x),
    non_missing = sum(!is.na(.x)),
    pct_coverage = round(100 * sum(!is.na(.x)) / length(.x), 1),
    unique_values = length(unique(.x[!is.na(.x)])),
    sample_values = paste(head(unique(.x[!is.na(.x)]), 5), collapse = ", ")
  ))) %>%
  pivot_longer(everything(), names_to = "variable") %>%
  unnest_wider(value)

print(coverage_stats)

# =============================================================================
# ENHANCED ANALYSIS: TEMPORAL COVERAGE MATRIX
# =============================================================================

cat("\n=== TEMPORAL COVERAGE MATRIX ===\n")

# Create year-by-variable coverage matrix
key_vars <- c("age", "gender", "race", "ethnicity", "language_home", 
              "citizenship_status", "place_birth", "immigrant_generation")

temporal_matrix <- combined_data %>%
  group_by(survey_year) %>%
  summarise(
    total_obs = n(),
    across(all_of(key_vars[key_vars %in% names(combined_data)]), 
           ~ round(100 * sum(!is.na(.x)) / n(), 1),
           .names = "{.col}_pct"),
    .groups = 'drop'
  ) %>%
  arrange(survey_year)

print(temporal_matrix)

# =============================================================================
# IMMIGRANT GENERATION ANALYSIS (PORTES FRAMEWORK)
# =============================================================================

cat("\n=== IMMIGRANT GENERATION ANALYSIS ===\n")

generation_summary <- combined_data %>%
  filter(!is.na(immigrant_generation)) %>%
  count(survey_year, immigrant_generation) %>%
  pivot_wider(names_from = immigrant_generation, values_from = n, values_fill = 0) %>%
  mutate(
    total = rowSums(select(., -survey_year), na.rm = TRUE),
    pct_1st = round(100 * `1` / total, 1),
    pct_2nd = if("2" %in% names(.)) round(100 * `2` / total, 1) else 0,
    pct_3rd = if("3" %in% names(.)) round(100 * `3` / total, 1) else 0
  ) %>%
  arrange(survey_year)

cat("Generation distribution by year (Portes framework):\n")
print(generation_summary)

# =============================================================================
# SAVE FINAL COMPREHENSIVE DATASET
# =============================================================================

cat("\n=== SAVING COMPREHENSIVE DATASET ===\n")

# Save main dataset
final_dataset_path <- "data/final/longitudinal_survey_data_2002_2023.csv"
write_csv(combined_data, final_dataset_path)

# Save coverage analysis
coverage_path <- "outputs/summaries/variable_coverage_2002_2023.csv"
write_csv(coverage_stats, coverage_path)

# Save temporal matrix
temporal_path <- "outputs/summaries/temporal_coverage_matrix_2002_2023.csv"  
write_csv(temporal_matrix, temporal_path)

# Save generation analysis
generation_path <- "outputs/summaries/generation_analysis_2002_2023.csv"
write_csv(generation_summary, generation_path)

# Update processing log
processing_log <- tibble(
  timestamp = Sys.time(),
  process = "Extended Wave Combination",
  years_processed = paste(sort(unique(combined_data$survey_year)), collapse = ", "),
  total_observations = nrow(combined_data),
  total_years = length(unique(combined_data$survey_year)),
  output_file = final_dataset_path,
  notes = "Combined 2002-2012 with 2014-2023 data using enhanced harmonization"
)

processing_log_path <- "outputs/logs/processing_log_2002_2023.csv"
write_csv(processing_log, processing_log_path)

# =============================================================================
# FINAL SUMMARY REPORT
# =============================================================================

cat("\n=== COMPREHENSIVE DATASET CREATED ===\n")
cat("📊 Dataset: ", basename(final_dataset_path), "\n")
cat("📅 Years: ", min(combined_data$survey_year), "-", max(combined_data$survey_year), 
    " (", length(unique(combined_data$survey_year)), " total years)\n")
cat("👥 Observations: ", format(nrow(combined_data), big.mark = ","), "\n")
cat("📋 Variables: ", ncol(combined_data), "\n")

cat("\n🎯 KEY COVERAGE HIGHLIGHTS:\n")
key_coverage <- coverage_stats %>% 
  filter(variable %in% c("age", "gender", "ethnicity", "place_birth", "immigrant_generation")) %>%
  select(variable, pct_coverage)

for (i in 1:nrow(key_coverage)) {
  cat("   ", key_coverage$variable[i], ": ", key_coverage$pct_coverage[i], "%\n")
}

cat("\n📁 Output Files Created:\n")
cat("   ✅", final_dataset_path, "\n")
cat("   ✅", coverage_path, "\n") 
cat("   ✅", temporal_path, "\n")
cat("   ✅", generation_path, "\n")
cat("   ✅", processing_log_path, "\n")

cat("\n🚀 READY FOR ANALYSIS!\n")
cat("The comprehensive 17-year Latino longitudinal dataset is now available.\n")
cat("Covers Bush, Obama, Trump, and Biden administrations (2002-2023).\n")

cat("\nCompleted at:", as.character(Sys.time()), "\n")