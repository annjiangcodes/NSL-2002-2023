# ==============================================================================
# Step 1: Robust Variable Extraction from Survey Data Files
# ==============================================================================

# Load required libraries
library(haven)     # For reading .sav and .dta files
library(dplyr)     # For data manipulation
library(stringr)   # For string operations
library(readr)     # For writing CSV files
library(purrr)     # For map functions

# Function to extract variable information from a single file (robust version)
extract_variables_robust <- function(file_path, year) {
  cat("Processing:", file_path, "\\n")
  
  # Read the file based on extension with error handling
  data <- tryCatch({
    if (str_detect(file_path, "\\.sav$")) {
      read_sav(file_path, n_max = 1)  # Only read first row for efficiency
    } else if (str_detect(file_path, "\\.dta$")) {
      read_dta(file_path, n_max = 1)
    } else {
      stop("Unsupported file format")
    }
  }, error = function(e) {
    cat("Error reading file:", e$message, "\\n")
    return(NULL)
  })
  
  if (is.null(data)) {
    return(NULL)
  }
  
  # Extract variable names
  var_names <- names(data)
  
  # Extract labels one by one to handle errors gracefully
  var_labels <- character(length(var_names))
  
  for (i in seq_along(var_names)) {
    var_labels[i] <- tryCatch({
      label <- attr(data[[var_names[i]]], "label")
      if (is.null(label)) {
        ""
      } else {
        # Clean the label by removing newlines and excessive whitespace
        label <- as.character(label)
        label <- str_replace_all(label, "\\s+", " ")  # Replace multiple spaces/newlines with single space
        label <- str_trim(label)  # Trim leading/trailing whitespace
        label
      }
    }, error = function(e) {
      paste("Error extracting label for", var_names[i])
    })
  }
  
  # Create data frame
  result <- data.frame(
    year = year,
    raw_variable_name = var_names,
    label = var_labels,
    stringsAsFactors = FALSE
  )
  
  cat("Successfully extracted", nrow(result), "variables\\n")
  return(result)
}

# Function to extract year from filename  
extract_year_from_filename <- function(filename) {
  # Remove path if present
  filename <- basename(filename)
  
  # Look for 4-digit year pattern
  year_match <- str_extract(filename, "\\b(19|20)\\d{2}\\b")
  if (!is.na(year_match)) {
    return(as.numeric(year_match))
  }
  
  # Manual mapping for specific files
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
  
  # If no year found, prompt user or return NA
  cat("Warning: Could not extract year from filename:", filename, "\\n")
  return(NA)
}

# Main execution function
main_robust <- function() {
  # Find all .sav and .dta files
  data_files <- c(
    list.files(".", pattern = "\\.(sav|dta)$", full.names = TRUE, recursive = FALSE),
    list.files("complete datasets", pattern = "\\.(sav|dta)$", full.names = TRUE, recursive = FALSE, include.dirs = FALSE)
  )
  
  cat("Found", length(data_files), "data files\\n")
  cat("Files:\\n")
  cat(paste(data_files, collapse = "\\n"), "\\n\\n")
  
  # Extract variables from each file
  all_variables <- data.frame()
  
  for (file in data_files) {
    year <- extract_year_from_filename(file)
    
    if (is.na(year)) {
      cat("Skipping file with unknown year:", file, "\\n")
      next
    }
    
    vars <- extract_variables_robust(file, year)
    
    if (!is.null(vars) && nrow(vars) > 0) {
      all_variables <- rbind(all_variables, vars)
    }
  }
  
  if (nrow(all_variables) == 0) {
    cat("No variables extracted!\\n")
    return()
  }
  
  # Sort and save results
  all_variables <- all_variables %>%
    arrange(year, raw_variable_name)
  
  write_csv(all_variables, "all_variables_extracted_robust.csv")
  
  cat("Extracted", nrow(all_variables), "variables from", length(unique(all_variables$year)), "years\\n")
  cat("Results saved to: all_variables_extracted_robust.csv\\n\\n")
  
  # Print summary
  summary_stats <- all_variables %>%
    group_by(year) %>%
    summarise(
      num_variables = n(),
      num_with_labels = sum(label != "" & !str_detect(label, "^Error")),
      .groups = 'drop'
    ) %>%
    arrange(year)
  
  cat("Summary by year:\\n")
  print(summary_stats)
  
  return(all_variables)
}

# Run the main function
if (!interactive()) {
  main_robust()
}