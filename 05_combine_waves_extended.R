# ==============================================================================
# Extended Wave Combination for 2002-2007 Survey Data
# ==============================================================================

# Load required libraries
library(dplyr)
library(readr)
library(stringr)
library(tidyr)

# Function to validate individual wave data
validate_wave_data <- function(data, year) {
  cat("Validating", year, "wave data:\n")
  
  issues <- c()
  warnings <- c()
  
  # Check required columns
  required_cols <- c("survey_year", "citizenship_status", "place_birth", "immigrant_generation")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if (length(missing_cols) > 0) {
    issues <- c(issues, paste("Missing required columns:", paste(missing_cols, collapse = ", ")))
  }
  
  # Check variable distributions
  for (var in names(data)[-1]) {  # Skip survey_year
    if (var %in% names(data)) {
      values <- data[[var]][!is.na(data[[var]])]
      n_unique <- length(unique(values))
      missing_pct <- sum(is.na(data[[var]]))/nrow(data) * 100
      
      # Flag potential issues
      if (n_unique == 0) {
        warnings <- c(warnings, paste(var, "has no valid values (100% missing)"))
      } else if (n_unique == 1) {
        warnings <- c(warnings, paste(var, "has only 1 unique value:", unique(values)[1]))
      } else if (n_unique > 50 && var %in% c("citizenship_status", "place_birth", "immigrant_generation", "gender", "political_party")) {
        warnings <- c(warnings, paste(var, "has", n_unique, "unique values (seems high)"))
      }
      
      if (missing_pct > 95) {
        warnings <- c(warnings, paste(var, "is", round(missing_pct, 1), "% missing"))
      }
    }
  }
  
  if (length(issues) > 0) {
    cat("CRITICAL ISSUES:\n")
    for (issue in issues) {
      cat("- ", issue, "\n")
    }
  }
  
  if (length(warnings) > 0) {
    cat("WARNINGS:\n")
    for (warning in warnings) {
      cat("- ", warning, "\n")
    }
  }
  
  if (length(issues) == 0 && length(warnings) == 0) {
    cat("No issues detected.\n")
  }
  
  cat("\n")
  
  return(length(issues) == 0)  # Return TRUE if no critical issues
}

# Function to create comprehensive variable summary
create_variable_summary_extended <- function(data) {
  # Create summary for each variable manually
  variables <- names(data)[names(data) != "survey_year"]
  
  summary_list <- list()
  
  for (var in variables) {
    values <- data[[var]][!is.na(data[[var]])]
    n_unique <- length(unique(values))
    pct_missing <- round(sum(is.na(data[[var]]))/nrow(data) * 100, 1)
    
    if (n_unique > 0) {
      sample_values <- paste(head(sort(unique(values)), 5), collapse = ", ")
      value_range <- paste(min(values, na.rm = TRUE), "to", max(values, na.rm = TRUE))
    } else {
      sample_values <- "No valid values"
      value_range <- "No valid values"
    }
    
    # More detailed quality assessment
    notes <- case_when(
      n_unique == 0 ~ "CRITICAL: No valid values - variable not working",
      n_unique == 1 ~ "WARNING: Only 1 unique value - may be constant",
      n_unique > 50 & var %in% c("citizenship_status", "place_birth", "immigrant_generation", "gender", "political_party") ~ "WARNING: Too many unique values for categorical variable",
      pct_missing > 95 ~ "WARNING: Extremely high missingness",
      pct_missing > 80 ~ "WARNING: High missingness", 
      pct_missing < 10 & n_unique >= 2 ~ "GOOD: Low missingness, adequate variation",
      n_unique >= 2 ~ "OK: Adequate variation",
      TRUE ~ "OK"
    )
    
    # Add concept mapping info
    concept_mapping <- case_when(
      var == "gender" ~ "Demographics",
      var == "age" ~ "Demographics", 
      var %in% c("citizenship_status", "place_birth", "parent_nativity", "immigrant_generation") ~ "Immigration/Nativity",
      var %in% c("hispanic_origin", "language_home") ~ "Ethnicity/Culture",
      var %in% c("political_party", "political_trust", "vote_intention") ~ "Political",
      var %in% c("education", "income", "employment", "marital_status") ~ "Socioeconomic",
      var %in% c("immigration_attitude") ~ "Attitudes",
      var %in% c("geography", "religion") ~ "Other",
      TRUE ~ "Unclassified"
    )
    
    summary_list[[var]] <- data.frame(
      variable = var,
      concept = concept_mapping,
      n_unique = n_unique,
      pct_missing = pct_missing,
      sample_values = sample_values,
      value_range = value_range,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  
  summary_data <- do.call(rbind, summary_list) %>%
    arrange(concept, variable)
  
  rownames(summary_data) <- NULL
  
  return(summary_data)
}

# Function to combine cleaned wave files
combine_waves_extended <- function(cleaned_data_dir = "cleaned_data") {
  
  # Get list of cleaned CSV files
  cleaned_files <- list.files(cleaned_data_dir, pattern = "cleaned_\\d{4}\\.csv$", full.names = TRUE)
  
  if (length(cleaned_files) == 0) {
    stop("No cleaned data files found in ", cleaned_data_dir)
  }
  
  cat("Found", length(cleaned_files), "cleaned data files:\n")
  cat(paste(basename(cleaned_files), collapse = ", "), "\n\n")
  
  # Read and validate each file
  wave_data_list <- list()
  valid_files <- c()
  
  for (file in cleaned_files) {
    year <- str_extract(basename(file), "\\d{4}")
    cat("Reading:", basename(file), "\n")
    
    # Read the data
    data <- read_csv(file, show_col_types = FALSE)
    
    # Ensure survey_year column exists and is correct
    if (!"survey_year" %in% names(data)) {
      data$survey_year <- as.numeric(year)
    } else {
      data$survey_year <- as.numeric(year)  # Override to ensure consistency
    }
    
    # Validate the data
    is_valid <- validate_wave_data(data, year)
    
    if (is_valid) {
      wave_data_list[[year]] <- data
      valid_files <- c(valid_files, file)
      cat("✓ ", year, "data validated successfully\n\n")
    } else {
      cat("✗ ", year, "data has critical issues - excluding from merge\n\n")
    }
  }
  
  if (length(wave_data_list) == 0) {
    stop("No valid wave files found after validation")
  }
  
  # Combine all valid waves
  cat("Combining", length(wave_data_list), "valid wave files...\n")
  combined_data <- bind_rows(wave_data_list)
  
  # Ensure consistent column ordering
  col_order <- c("survey_year", "gender", "age", "citizenship_status", "place_birth", 
                 "parent_nativity", "immigrant_generation", "hispanic_origin", "language_home",
                 "political_party", "education", "income", "employment", "marital_status", 
                 "religion", "geography", "immigration_attitude", "political_trust", "vote_intention")
  
  # Keep only columns that exist
  available_cols <- col_order[col_order %in% names(combined_data)]
  combined_data <- combined_data %>% select(all_of(available_cols))
  
  cat("Combined dataset dimensions:", dim(combined_data), "\n")
  
  # Final validation of combined data
  cat("\n=== Final Combined Dataset Validation ===\n")
  
  year_counts <- table(combined_data$survey_year)
  cat("Observations per year:\n")
  print(year_counts)
  
  # Create and display variable summary
  cat("\n=== Comprehensive Variable Summary ===\n")
  var_summary <- create_variable_summary_extended(combined_data)
  print(var_summary)
  
  # Summary by concept
  cat("\n=== Summary by Concept ===\n")
  concept_summary <- var_summary %>%
    group_by(concept) %>%
    summarise(
      n_variables = n(),
      avg_missing = round(mean(pct_missing), 1),
      n_good = sum(str_detect(notes, "GOOD")),
      n_warnings = sum(str_detect(notes, "WARNING")),
      n_critical = sum(str_detect(notes, "CRITICAL")),
      .groups = "drop"
    ) %>%
    arrange(desc(n_good), avg_missing)
  
  print(concept_summary)
  
  # Check for data quality issues
  cat("\n=== Data Quality Assessment ===\n")
  
  quality_issues <- c()
  
  # Check core variables
  core_vars <- c("citizenship_status", "place_birth", "immigrant_generation")
  for (var in core_vars) {
    if (var %in% names(combined_data)) {
      values <- unique(combined_data[[var]][!is.na(combined_data[[var]])])
      if (length(values) < 2) {
        quality_issues <- c(quality_issues, paste(var, "has insufficient variation"))
      }
    }
  }
  
  # Check for completely missing variables
  missing_vars <- var_summary %>%
    filter(n_unique == 0) %>%
    pull(variable)
  
  if (length(missing_vars) > 0) {
    quality_issues <- c(quality_issues, paste("Variables with no valid data:", paste(missing_vars, collapse = ", ")))
  }
  
  if (length(quality_issues) > 0) {
    cat("QUALITY ISSUES DETECTED:\n")
    for (issue in quality_issues) {
      cat("- ", issue, "\n")
    }
  } else {
    cat("No major quality issues detected in combined dataset.\n")
  }
  
  return(list(
    data = combined_data,
    summary = var_summary,
    concept_summary = concept_summary,
    files_used = valid_files
  ))
}

# Main execution function
main_combine_waves_extended <- function() {
  cat("=== Extended Wave Combination Process for 2002-2007 ===\n\n")
  
  # Combine the waves
  result <- combine_waves_extended()
  
  # Save the combined dataset
  output_file <- "longitudinal_survey_data_2002_2007.csv"
  write_csv(result$data, output_file)
  cat("\nSaved combined dataset:", output_file, "\n")
  
  # Save the comprehensive variable summary
  summary_file <- "variable_summary_2002_2007.csv"
  write_csv(result$summary, summary_file)
  cat("Saved variable summary:", summary_file, "\n")
  
  # Save concept summary
  concept_file <- "concept_summary_2002_2007.csv"
  write_csv(result$concept_summary, concept_file)
  cat("Saved concept summary:", concept_file, "\n")
  
  # Save processing log
  log_data <- data.frame(
    files_processed = basename(result$files_used),
    processing_date = Sys.Date(),
    total_observations = nrow(result$data),
    years_included = paste(sort(unique(result$data$survey_year)), collapse = ", "),
    n_variables = ncol(result$data) - 1,  # Exclude survey_year
    stringsAsFactors = FALSE
  )
  
  write_csv(log_data, "processing_log_2002_2007.csv")
  cat("Saved processing log: processing_log_2002_2007.csv\n")
  
  cat("\n=== Process Complete ===\n")
  cat("Files created:\n")
  cat("- ", output_file, "\n")
  cat("- ", summary_file, "\n") 
  cat("- ", concept_file, "\n")
  cat("- processing_log_2002_2007.csv\n")
  
  return(result)
}

# Run if script is executed directly
if (!interactive()) {
  main_combine_waves_extended()
}