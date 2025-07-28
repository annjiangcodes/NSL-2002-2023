# ==============================================================================
# Master Script: Longitudinal Survey Data Harmonization
# ==============================================================================
# 
# This script orchestrates the complete harmonization workflow for longitudinal
# survey data focused on immigration attitudes, nativity, generation, and 
# political attitudes.
#
# Steps:
# 1. Extract variable names and labels from all survey files
# 2. Search for variables matching target concepts
# 3. Create harmonization plan
# 4. Apply harmonization and clean data files
# 5. Merge cleaned waves into longitudinal dataset
#
# ==============================================================================

# Set working directory and load required libraries
cat("=== Longitudinal Survey Data Harmonization ===\n")
cat("Starting harmonization workflow...\n\n")

# Check if required packages are installed
required_packages <- c("haven", "dplyr", "stringr", "readr", "tidyr", "labelled", "purrr")
missing_packages <- setdiff(required_packages, rownames(installed.packages()))

if (length(missing_packages) > 0) {
  cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
  install.packages(missing_packages)
}

# Load all required libraries
library(haven)
library(dplyr)
library(stringr)
library(readr)
library(tidyr)
library(labelled)
library(purrr)

# Create timestamp for this run
run_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
cat("Run timestamp:", run_timestamp, "\n\n")

# ==============================================================================
# STEP 1: Extract Variable Information
# ==============================================================================

cat("STEP 1: Extracting variable names and labels from survey files...\n")

# Source the variable extraction script
source("01_variable_extraction.R")

# Run the extraction
all_variables <- main()

if (is.null(all_variables) || nrow(all_variables) == 0) {
  stop("Error: Variable extraction failed. Please check your data files.")
}

cat("✓ Step 1 completed successfully\n\n")

# ==============================================================================
# STEP 2: Search for Target Variables
# ==============================================================================

cat("STEP 2: Searching for variables matching target concepts...\n")

# Source the keyword search script
source("02_keyword_search.R")

# Run the keyword search
search_results <- main_keyword_search()

if (is.null(search_results)) {
  stop("Error: Keyword search failed.")
}

cat("✓ Step 2 completed successfully\n\n")

# ==============================================================================
# STEP 3: Create Harmonization Plan
# ==============================================================================

cat("STEP 3: Creating harmonization plan...\n")

# Source the harmonization planning script
source("03_harmonization_plan.R")

# Create harmonization plan (focusing on 2002 and 2004)
harmonization_plan <- create_harmonization_plan(focus_years = c(2002, 2004))

if (is.null(harmonization_plan)) {
  stop("Error: Harmonization plan creation failed.")
}

# Create review template
review_template <- create_review_template(harmonization_plan)

cat("✓ Step 3 completed successfully\n\n")

# ==============================================================================
# STEP 4: Apply Harmonization and Clean Data
# ==============================================================================

cat("STEP 4: Applying harmonization plan to survey data...\n")

# Source the data harmonization script
source("04_data_harmonization.R")

# Process the survey waves
processing_reports <- process_multiple_waves()

if (is.null(processing_reports) || length(processing_reports) == 0) {
  stop("Error: Data harmonization failed.")
}

cat("✓ Step 4 completed successfully\n\n")

# ==============================================================================
# STEP 5: Create Merged Longitudinal Dataset
# ==============================================================================

cat("STEP 5: Creating merged longitudinal dataset...\n")

# Function to merge cleaned datasets
merge_cleaned_data <- function(cleaned_data_dir = "cleaned_data") {
  
  # Find all cleaned CSV files
  cleaned_files <- list.files(cleaned_data_dir, pattern = "cleaned_.*\\.csv$", full.names = TRUE)
  
  if (length(cleaned_files) == 0) {
    cat("No cleaned data files found in", cleaned_data_dir, "\n")
    return(NULL)
  }
  
  cat("Found", length(cleaned_files), "cleaned data files:\n")
  cat(paste(basename(cleaned_files), collapse = ", "), "\n\n")
  
  # Read and combine all cleaned datasets
  all_data <- map_dfr(cleaned_files, ~ {
    cat("Reading", basename(.x), "\n")
    read_csv(.x, show_col_types = FALSE)
  })
  
  # Create final longitudinal dataset
  longitudinal_data <- all_data %>%
    arrange(survey_year) %>%
    # Add a unique row identifier across waves
    mutate(row_id = row_number())
  
  # Save merged dataset
  output_file <- paste0("longitudinal_data_", run_timestamp, ".csv")
  write_csv(longitudinal_data, output_file)
  
  cat("Merged longitudinal dataset saved to:", output_file, "\n")
  cat("Final dataset dimensions:", nrow(longitudinal_data), "x", ncol(longitudinal_data), "\n")
  
  # Create summary statistics
  summary_stats <- longitudinal_data %>%
    group_by(survey_year) %>%
    summarise(
      n_obs = n(),
      across(where(is.numeric), ~ sum(!is.na(.x)), .names = "nonmissing_{.col}"),
      .groups = "drop"
    )
  
  write_csv(summary_stats, paste0("longitudinal_summary_", run_timestamp, ".csv"))
  
  cat("\nSummary by survey year:\n")
  print(summary_stats)
  
  return(longitudinal_data)
}

# Create merged dataset
longitudinal_data <- merge_cleaned_data()

if (is.null(longitudinal_data)) {
  stop("Error: Failed to create merged longitudinal dataset.")
}

cat("✓ Step 5 completed successfully\n\n")

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

cat("=== HARMONIZATION WORKFLOW COMPLETED ===\n\n")

cat("Files created:\n")
cat("• all_variables_extracted.csv - All variables from all survey files\n")
cat("• matched_variables_by_concept.csv - Variables matching target concepts\n")
cat("• concept_summary_by_year.csv - Summary of concepts by year\n")
cat("• harmonization_plan.csv - Harmonization mapping plan\n")
cat("• harmonization_review_template.csv - Template for manual review\n")
cat("• processing_summary.csv - Summary of data processing\n")
cat("• cleaned_data/ directory - Individual cleaned wave files\n")
cat("• longitudinal_data_", run_timestamp, ".csv - Final merged dataset\n")
cat("• longitudinal_summary_", run_timestamp, ".csv - Summary statistics\n\n")

cat("Next steps:\n")
cat("1. Review the harmonization_review_template.csv file\n")
cat("2. Manually refine the harmonization plan if needed\n")
cat("3. Re-run steps 4-5 with updated harmonization plan\n")
cat("4. Add additional survey waves iteratively\n")
cat("5. Conduct analyses using the longitudinal dataset\n\n")

cat("Workflow completed at:", format(Sys.time()), "\n")