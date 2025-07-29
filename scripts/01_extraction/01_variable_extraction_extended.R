# ==============================================================================
# Extended Variable Extraction for 2002-2007 Survey Data Files
# ==============================================================================

# Load required libraries
library(haven)     # For reading .sav and .dta files
library(dplyr)     # For data manipulation
library(stringr)   # For string operations
library(readr)     # For writing CSV files
library(purrr)     # For map functions

# Function to extract variable information from a single file (robust version)
extract_variables_robust <- function(file_path, year) {
  cat("Processing:", file_path, "\n")
  
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
    cat("Error reading file:", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(data)) {
    return(data.frame())
  }
  
  # Extract variable names
  var_names <- names(data)
  
  # Extract variable labels with error handling
  var_labels <- map_chr(var_names, function(var) {
    tryCatch({
      label <- attr(data[[var]], "label")
      if (is.null(label) || is.na(label)) {
        return("")
      }
      # Clean the label - remove newlines and excessive whitespace
      label <- str_replace_all(as.character(label), "\\s+", " ")
      label <- str_trim(label)
      # Truncate very long labels
      if (nchar(label) > 500) {
        label <- paste0(substr(label, 1, 497), "...")
      }
      return(label)
    }, error = function(e) {
      return("")
    })
  })
  
  # Create dataframe
  result <- data.frame(
    year = year,
    raw_variable_name = var_names,
    label = var_labels,
    stringsAsFactors = FALSE
  )
  
  cat("Extracted", nrow(result), "variables\n")
  return(result)
}

# Function to extract year from filename
extract_year_from_filename <- function(filename) {
  # Look for 4-digit year pattern
  year_match <- str_extract(filename, "\\b(19|20)\\d{2}\\b")
  
  if (!is.na(year_match)) {
    return(as.numeric(year_match))
  }
  
  # Handle special cases
  if (str_detect(filename, "f1171.*050207")) {
    return(2006)  # Based on the "050207" suggesting 2006-2007
  }
  
  if (str_detect(filename, "NSL07")) {
    return(2007)
  }
  
  return(NA)
}

# Main extraction function for 2002-2007
main_extraction_extended <- function() {
  
  cat("=== Extended Variable Extraction for 2002-2007 ===\n\n")
  
  # Define file mappings for 2002-2007
  target_files <- c(
    "2002 RAE008b FINAL DATA FOR RELEASE.sav",
    "2004 Political Survey Rev 1-6-05.sav", 
    "f1171_050207 uploaded dataset.sav",  # 2006
    "publicreleaseNSL07_UPDATED_3.7.22.sav"  # 2007
  )
  
  # Also check complete datasets folder
  complete_datasets_files <- file.path("complete datasets", target_files)
  
  # Combine all possible file paths
  all_candidate_files <- c(target_files, complete_datasets_files)
  
  # Find files that actually exist
  existing_files <- all_candidate_files[file.exists(all_candidate_files)]
  
  cat("Found", length(existing_files), "survey data files:\n")
  for (file in existing_files) {
    cat("- ", file, "\n")
  }
  cat("\n")
  
  # Extract variables from each file
  all_variables <- data.frame()
  
  for (file_path in existing_files) {
    filename <- basename(file_path)
    year <- extract_year_from_filename(filename)
    
    if (is.na(year)) {
      cat("Warning: Could not extract year from", filename, "\n")
      next
    }
    
    cat("Processing", year, "data:", filename, "\n")
    
    # Extract variables
    file_variables <- extract_variables_robust(file_path, year)
    
    if (nrow(file_variables) > 0) {
      all_variables <- rbind(all_variables, file_variables)
      cat("Success: Added", nrow(file_variables), "variables for", year, "\n\n")
    } else {
      cat("Warning: No variables extracted from", filename, "\n\n")
    }
  }
  
  # Remove duplicate entries (in case files exist in both locations)
  all_variables <- all_variables %>%
    distinct(year, raw_variable_name, .keep_all = TRUE) %>%
    arrange(year, raw_variable_name)
  
  cat("Total variables extracted:", nrow(all_variables), "\n")
  cat("Years covered:", paste(sort(unique(all_variables$year)), collapse = ", "), "\n")
  
  # Save results
  output_file <- "all_variables_extracted_2002_2007.csv"
  write_csv(all_variables, output_file)
  cat("Saved:", output_file, "\n")
  
  # Print summary by year
  cat("\nSummary by year:\n")
  year_summary <- all_variables %>%
    group_by(year) %>%
    summarise(
      n_variables = n(),
      .groups = "drop"
    )
  print(year_summary)
  
  return(all_variables)
}

# Run the extraction
if (!interactive()) {
  all_variables <- main_extraction_extended()
}