# ==============================================================================
# Step 5: Combine Cleaned Survey Waves into Longitudinal Dataset
# ==============================================================================

# Load required libraries
library(dplyr)
library(readr)

# Function to combine cleaned wave files
combine_waves <- function(cleaned_data_dir = "cleaned_data") {
  
  # Get list of cleaned CSV files
  cleaned_files <- list.files(cleaned_data_dir, pattern = "cleaned_\\d{4}\\.csv$", full.names = TRUE)
  
  if (length(cleaned_files) == 0) {
    stop("No cleaned data files found in ", cleaned_data_dir)
  }
  
  cat("Found", length(cleaned_files), "cleaned data files:\\n")
  cat(paste(basename(cleaned_files), collapse = ", "), "\\n\\n")
  
  # Read and combine all files
  combined_data <- data.frame()
  
  for (file in cleaned_files) {
    cat("Reading:", basename(file), "\\n")
    wave_data <- read_csv(file, show_col_types = FALSE)
    
    # Add to combined dataset
    if (nrow(combined_data) == 0) {
      combined_data <- wave_data
    } else {
      # Use bind_rows to handle different column orders
      combined_data <- bind_rows(combined_data, wave_data)
    }
    
    cat("  Added", nrow(wave_data), "observations\\n")
  }
  
  # Sort by survey year
  combined_data <- combined_data %>%
    arrange(survey_year)
  
  # Save combined dataset
  write_csv(combined_data, "longitudinal_survey_data.csv")
  
  cat("\\n=== FINAL LONGITUDINAL DATASET ===\\n")
  cat("Total observations:", nrow(combined_data), "\\n")
  cat("Survey years:", paste(sort(unique(combined_data$survey_year)), collapse = ", "), "\\n")
  cat("Variables:", paste(names(combined_data), collapse = ", "), "\\n")
  cat("Saved to: longitudinal_survey_data.csv\\n\\n")
  
  # Summary statistics
  summary_stats <- combined_data %>%
    group_by(survey_year) %>%
    summarise(
      n_observations = n(),
      n_border_security = sum(!is.na(border_security_attitude)),
      n_immigration_attitude = sum(!is.na(immigration_attitude)),
      n_citizenship = sum(!is.na(citizenship_status)),
      n_generation = sum(!is.na(immigrant_generation)),
      n_place_birth = sum(!is.na(place_birth)),
      n_political_party = sum(!is.na(political_party)),
      n_vote_intention = sum(!is.na(vote_intention)),
      .groups = 'drop'
    )
  
  cat("Summary by year:\\n")
  print(summary_stats)
  
  return(combined_data)
}

# Run the function
if (!interactive()) {
  combine_waves()
}