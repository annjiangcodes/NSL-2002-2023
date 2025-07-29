# ==============================================================================
# Step 5: Fixed Combine Cleaned Survey Waves into Longitudinal Dataset
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
  for (var in required_cols[-1]) {  # Skip survey_year
    if (var %in% names(data)) {
      values <- data[[var]][!is.na(data[[var]])]
      n_unique <- length(unique(values))
      missing_pct <- sum(is.na(data[[var]]))/nrow(data) * 100
      
      # Flag potential issues
      if (n_unique == 1) {
        warnings <- c(warnings, paste(var, "has only 1 unique value:", unique(values)[1]))
      } else if (n_unique > 20 && var %in% c("citizenship_status", "place_birth", "immigrant_generation")) {
        warnings <- c(warnings, paste(var, "has", n_unique, "unique values (seems high)"))
      }
      
      if (missing_pct > 90) {
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

# Function to create variable summary
create_variable_summary <- function(data) {
  # Create summary for each variable manually to avoid data type issues
  variables <- names(data)[names(data) != "survey_year"]
  
  summary_list <- list()
  
  for (var in variables) {
    values <- data[[var]][!is.na(data[[var]])]
    n_unique <- length(unique(values))
    pct_missing <- round(sum(is.na(data[[var]]))/nrow(data) * 100, 1)
    sample_values <- paste(head(unique(values), 5), collapse = ", ")
    
    notes <- case_when(
      n_unique == 1 ~ "WARNING: Only 1 unique value - possible bad merge",
      n_unique > 20 & var %in% c("citizenship_status", "place_birth", "immigrant_generation") ~ "WARNING: Too many unique values",
      pct_missing > 80 ~ "WARNING: High missingness",
      TRUE ~ "OK"
    )
    
    summary_list[[var]] <- data.frame(
      variable = var,
      n_unique = n_unique,
      pct_missing = pct_missing,
      sample_values = sample_values,
      notes = notes,
      stringsAsFactors = FALSE
    )
  }
  
  summary_data <- do.call(rbind, summary_list) %>%
    arrange(variable)
  
  rownames(summary_data) <- NULL
  
  return(summary_data)
}

# Function to combine cleaned wave files
combine_waves_fixed <- function(cleaned_data_dir = "cleaned_data") {
  
  # Get list of cleaned CSV files
  cleaned_files <- list.files(cleaned_data_dir, pattern = "cleaned_\\d{4}\\.csv$", full.names = TRUE)
  
  if (length(cleaned_files) == 0) {
    stop("No cleaned data files found in ", cleaned_data_dir)
  }
  
  cat("Found", length(cleaned_files), "cleaned data files:\\n")
  cat(paste(basename(cleaned_files), collapse = ", "), "\\n\\n")
  
  # Read and validate each file
  wave_data_list <- list()
  valid_files <- c()
  
  for (file in cleaned_files) {
    year <- str_extract(basename(file), "\\d{4}")
    cat("Reading:", basename(file), "\\n")
    
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
      cat("✓ ", year, "data validated successfully\\n\\n")
    } else {
      cat("✗ ", year, "data has critical issues - excluding from merge\\n\\n")
    }
  }
  
  if (length(wave_data_list) == 0) {
    stop("No valid wave files found after validation")
  }
  
  # Combine all valid waves
  cat("Combining", length(wave_data_list), "valid wave files...\\n")
  combined_data <- bind_rows(wave_data_list)
  
  # Ensure consistent column ordering - UPDATED to include all demographic variables
  col_order <- c("survey_year", "age", "gender", "race", "ethnicity", "language_home",
                 "citizenship_status", "place_birth", "immigrant_generation", 
                 "immigration_attitude", "border_security_attitude", "political_party", 
                 "vote_intention", "approval_rating")
  
  # Keep only columns that exist
  available_cols <- col_order[col_order %in% names(combined_data)]
  combined_data <- combined_data %>% select(all_of(available_cols))
  
  cat("Combined dataset dimensions:", dim(combined_data), "\\n")
  
  # Final validation of combined data
  cat("\\n=== Final Combined Dataset Validation ===\\n")
  
  year_counts <- table(combined_data$survey_year)
  cat("Observations per year:\\n")
  print(year_counts)
  
  # Create and display variable summary
  cat("\\n=== Variable Summary ===\\n")
  var_summary <- create_variable_summary(combined_data)
  print(var_summary)
  
  # Check for any remaining issues
  cat("\\n=== Data Quality Check ===\\n")
  
  quality_issues <- c()
  
  # Check citizenship_status
  cs_values <- unique(combined_data$citizenship_status[!is.na(combined_data$citizenship_status)])
  if (length(cs_values) < 2) {
    quality_issues <- c(quality_issues, "citizenship_status has insufficient variation")
  }
  
  # Check place_birth
  pb_values <- unique(combined_data$place_birth[!is.na(combined_data$place_birth)])
  if (length(pb_values) < 2) {
    quality_issues <- c(quality_issues, "place_birth has insufficient variation")
  }
  
  # Check immigrant_generation
  ig_values <- unique(combined_data$immigrant_generation[!is.na(combined_data$immigrant_generation)])
  if (length(ig_values) < 2) {
    quality_issues <- c(quality_issues, "immigrant_generation has insufficient variation")
  }
  
  if (length(quality_issues) > 0) {
    cat("QUALITY ISSUES DETECTED:\\n")
    for (issue in quality_issues) {
      cat("- ", issue, "\\n")
    }
  } else {
    cat("No major quality issues detected in combined dataset.\\n")
  }
  
  return(list(
    data = combined_data,
    summary = var_summary,
    files_used = valid_files
  ))
}

# Main execution function
main_combine_waves <- function() {
  cat("=== Fixed Wave Combination Process ===\\n\\n")
  
  # Combine the waves
  result <- combine_waves_fixed()
  
  # Save the combined dataset
  output_file <- "longitudinal_survey_data_fixed.csv"
  write_csv(result$data, output_file)
  cat("\\nSaved combined dataset:", output_file, "\\n")
  
  # Save the variable summary
  summary_file <- "variable_summary.csv"
  write_csv(result$summary, summary_file)
  cat("Saved variable summary:", summary_file, "\\n")
  
  # Save processing log
  log_data <- data.frame(
    files_processed = basename(result$files_used),
    processing_date = Sys.Date(),
    total_observations = nrow(result$data),
    years_included = paste(sort(unique(result$data$survey_year)), collapse = ", ")
  )
  
  write_csv(log_data, "processing_log.csv")
  cat("Saved processing log: processing_log.csv\\n")
  
  cat("\\n=== Process Complete ===\\n")
  cat("Files created:\\n")
  cat("- ", output_file, "\\n")
  cat("- ", summary_file, "\\n") 
  cat("- processing_log.csv\\n")
  
  return(result)
}

# Run if script is executed directly
if (!interactive()) {
  main_combine_waves()
}