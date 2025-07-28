# ==============================================================================
# Step 1: Extract Variable Names and Labels from Survey Data Files
# ==============================================================================

# Load required libraries
library(haven)     # For reading .sav and .dta files
library(dplyr)     # For data manipulation
library(stringr)   # For string operations
library(readr)     # For writing CSV files
library(purrr)     # For map functions

# Function to extract variable information from a single file
extract_variables <- function(file_path, year) {
  cat("Processing:", file_path, "\n")
  
  # Read the file based on extension
  if (str_detect(file_path, "\\.sav$")) {
    data <- read_sav(file_path, n_max = 1)  # Only read first row for efficiency
  } else if (str_detect(file_path, "\\.dta$")) {
    data <- read_dta(file_path, n_max = 1)  # Only read first row for efficiency
  } else {
    return(NULL)
  }
  
  # Extract variable names and labels
  var_names <- names(data)
  var_labels <- map_chr(data, ~ attr(.x, "label") %||% "")
  
  # Create data frame
  result <- tibble(
    year = year,
    raw_variable_name = var_names,
    label = var_labels
  )
  
  return(result)
}

# Function to extract year from filename
extract_year_from_filename <- function(filename) {
  # Look for 4-digit year pattern
  year_match <- str_extract(filename, "\\b(19|20)\\d{2}\\b")
  if (!is.na(year_match)) {
    return(as.numeric(year_match))
  }
  
  # Manual mapping for specific files if pattern doesn't work
  year_mappings <- c(
    "publicreleaseNSL07_UPDATED_3.7.22.sav" = 2007,
    "f1171_050207 uploaded dataset.sav" = 2006,
    "PHCNSL2012PublicRelease_UPDATED 3.7.22.sav" = 2012,
    "PHCNSL2010PublicRelease_UPDATED 3.7.22.sav" = 2010,
    "PHCNSL2011PubRelease_UPDATED 3.7.22.sav" = 2011,
    "PHCNSL2008aPublicRelease_UPDATED 3.7.22.sav" = 2008,
    "PHCNSL2009PublicRelease.sav" = 2009,
    "NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav" = 2018,
    "NSL2014_FOR RELEASE.sav" = 2014,
    "NSL2015_FOR RELEASE.sav" = 2015,
    "NSL 2016_FOR RELEASE.sav" = 2016,
    "2023ATP W138.sav" = 2023,
    "2021 ATP W86.sav" = 2021
  )
  
  if (filename %in% names(year_mappings)) {
    return(year_mappings[[filename]])
  }
  
  return(NA)
}

# Main execution
main <- function() {
  # Find all .sav and .dta files in current directory and subdirectories
  sav_files <- list.files(path = ".", pattern = "\\.sav$", recursive = TRUE, full.names = TRUE)
  dta_files <- list.files(path = ".", pattern = "\\.dta$", recursive = TRUE, full.names = TRUE)
  
  all_files <- c(sav_files, dta_files)
  
  cat("Found", length(all_files), "data files\n")
  cat("Files:\n")
  cat(paste(all_files, collapse = "\n"), "\n\n")
  
  # Extract variables from all files
  all_variables <- tibble()
  
  for (file_path in all_files) {
    filename <- basename(file_path)
    year <- extract_year_from_filename(filename)
    
    if (is.na(year)) {
      cat("Warning: Could not extract year from", filename, "\n")
      next
    }
    
    tryCatch({
      file_vars <- extract_variables(file_path, year)
      if (!is.null(file_vars)) {
        all_variables <- bind_rows(all_variables, file_vars)
      }
    }, error = function(e) {
      cat("Error processing", file_path, ":", e$message, "\n")
    })
  }
  
  # Sort by year and variable name
  all_variables <- all_variables %>%
    arrange(year, raw_variable_name)
  
  # Write to CSV
  write_csv(all_variables, "all_variables_extracted.csv")
  
  cat("Extracted", nrow(all_variables), "variables from", length(unique(all_variables$year)), "years\n")
  cat("Results saved to: all_variables_extracted.csv\n")
  
  # Print summary by year
  summary_by_year <- all_variables %>%
    group_by(year) %>%
    summarise(
      num_variables = n(),
      num_with_labels = sum(label != "", na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(year)
  
  cat("\nSummary by year:\n")
  print(summary_by_year)
  
  return(all_variables)
}

# Run the extraction
if (!interactive()) {
  all_variables <- main()
}