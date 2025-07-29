# ==============================================================================
# Step 4: Data Harmonization and Cleaning Script
# ==============================================================================

# Load required libraries
library(haven)
library(dplyr)
library(stringr)
library(readr)
library(labelled)
library(purrr)

# Function to read survey data file
read_survey_data <- function(file_path) {
  if (str_detect(file_path, "\\.sav$")) {
    return(read_sav(file_path))
  } else if (str_detect(file_path, "\\.dta$")) {
    return(read_dta(file_path))
  } else {
    stop("Unsupported file format. Please use .sav or .dta files.")
  }
}

# Function to apply harmonization to a single variable
harmonize_variable <- function(data, raw_name, harmonized_name, values_recode, notes) {
  
  if (!raw_name %in% names(data)) {
    cat("Warning: Variable", raw_name, "not found in data\n")
    return(data)
  }
  
  # Get the original variable
  original_var <- data[[raw_name]]
  
  # Apply recoding based on values_recode specification
  harmonized_var <- original_var
  
  # Parse common recode patterns
  if (str_detect(values_recode, "1=Yes, 0=No")) {
    # Handle Yes/No binary variables
    harmonized_var <- case_when(
      str_detect(str_to_lower(as.character(original_var)), "yes|1") ~ 1,
      str_detect(str_to_lower(as.character(original_var)), "no|0") ~ 0,
      TRUE ~ NA_real_
    )
  } else if (str_detect(values_recode, "1=US Born, 2=Foreign Born")) {
    # Handle nativity variables
    harmonized_var <- case_when(
      str_detect(str_to_lower(as.character(original_var)), "us|united states|america") ~ 1,
      !is.na(original_var) ~ 2,
      TRUE ~ NA_real_
    )
  } else if (str_detect(values_recode, "Democrat.*Republican")) {
    # Handle party affiliation - this is a template, actual recoding needs inspection
    harmonized_var <- case_when(
      str_detect(str_to_lower(as.character(original_var)), "democrat") ~ 1,
      str_detect(str_to_lower(as.character(original_var)), "republican") ~ 2,
      str_detect(str_to_lower(as.character(original_var)), "independent") ~ 3,
      !is.na(original_var) ~ 4,
      TRUE ~ NA_real_
    )
  } else {
    # For variables that need manual review, keep original values
    harmonized_var <- as.numeric(original_var)
  }
  
  # Add the harmonized variable to the dataset
  data[[harmonized_name]] <- harmonized_var
  
  # Add labels
  attr(data[[harmonized_name]], "label") <- paste("Harmonized:", notes)
  
  cat("Harmonized", raw_name, "->", harmonized_name, "\n")
  
  return(data)
}

# Function to apply full harmonization plan to a dataset
apply_harmonization_plan <- function(data, year, harmonization_plan) {
  
  cat("Applying harmonization plan for year", year, "\n")
  
  # Filter plan for this year
  year_plan <- harmonization_plan %>%
    filter(year == !!year)
  
  if (nrow(year_plan) == 0) {
    cat("No harmonization plan found for year", year, "\n")
    return(data)
  }
  
  # Apply each harmonization rule
  for (i in 1:nrow(year_plan)) {
    rule <- year_plan[i, ]
    
    data <- harmonize_variable(
      data = data,
      raw_name = rule$raw_name,
      harmonized_name = rule$harmonized_name,
      values_recode = rule$values_recode,
      notes = rule$notes
    )
  }
  
  # Add year identifier
  data$survey_year <- year
  
  # Create a summary of harmonized variables
  harmonized_vars <- year_plan$harmonized_name
  summary_stats <- data %>%
    select(all_of(c("survey_year", harmonized_vars))) %>%
    summarise(
      across(everything(), ~ sum(!is.na(.x))),
      .groups = "drop"
    )
  
  cat("Summary of non-missing values for harmonized variables:\n")
  print(summary_stats)
  
  return(data)
}

# Function to clean and export a single wave
clean_wave <- function(file_path, year, harmonization_plan, output_dir = "cleaned_data") {
  
  cat("\n=== Processing", year, "wave ===\n")
  cat("Input file:", file_path, "\n")
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Read the data
  tryCatch({
    data <- read_survey_data(file_path)
    cat("Successfully read", nrow(data), "observations with", ncol(data), "variables\n")
  }, error = function(e) {
    cat("Error reading file:", e$message, "\n")
    return(NULL)
  })
  
  # Apply harmonization
  harmonized_data <- apply_harmonization_plan(data, year, harmonization_plan)
  
  # Select harmonized variables plus some key demographics/weights if available
  harmonized_vars <- harmonization_plan %>%
    filter(year == !!year) %>%
    pull(harmonized_name) %>%
    unique()
  
  # Common demographic variables to keep (if they exist)
  demo_vars <- c("age", "gender", "education", "income", "race", "ethnicity", 
                 "weight", "strata", "psu", "cluster", "id", "respondent_id")
  
  keep_vars <- c("survey_year", harmonized_vars)
  
  # Add demographic variables that exist in the data
  existing_demo_vars <- intersect(demo_vars, names(harmonized_data))
  keep_vars <- c(keep_vars, existing_demo_vars)
  
  # Create final cleaned dataset
  cleaned_data <- harmonized_data %>%
    select(any_of(keep_vars))
  
  # Export to CSV
  output_file <- file.path(output_dir, paste0("cleaned_", year, ".csv"))
  write_csv(cleaned_data, output_file)
  
  cat("Exported cleaned data to:", output_file, "\n")
  cat("Final dataset dimensions:", nrow(cleaned_data), "x", ncol(cleaned_data), "\n")
  
  # Create a summary report
  summary_report <- list(
    year = year,
    input_file = file_path,
    output_file = output_file,
    original_n_obs = nrow(harmonized_data),
    original_n_vars = ncol(data),
    cleaned_n_obs = nrow(cleaned_data),
    cleaned_n_vars = ncol(cleaned_data),
    harmonized_variables = harmonized_vars,
    demographic_variables = existing_demo_vars
  )
  
  return(summary_report)
}

# Function to process multiple waves
process_multiple_waves <- function(harmonization_plan_file = "harmonization_plan.csv",
                                 focus_years = c(2002, 2004)) {
  
  # Read harmonization plan
  if (!file.exists(harmonization_plan_file)) {
    cat("Error: Harmonization plan file not found. Please run 03_harmonization_plan.R first.\n")
    return(NULL)
  }
  
  harmonization_plan <- read_csv(harmonization_plan_file, show_col_types = FALSE)
  
  # Define file mappings for focus years
  file_mappings <- list(
    `2002` = "2002 RAE008b FINAL DATA FOR RELEASE.sav",
    `2004` = "2004 Political Survey Rev 1-6-05.sav"
  )
  
  # Alternative file locations
  alt_file_mappings <- list(
    `2002` = "complete datasets/2002 RAE008b FINAL DATA FOR RELEASE.sav",
    `2004` = "complete datasets/2004 Political Survey Rev 1-6-05.sav"
  )
  
  # Process each year
  processing_reports <- list()
  
  for (year in focus_years) {
    year_str <- as.character(year)
    
    # Find the file
    file_path <- file_mappings[[year_str]]
    if (!file.exists(file_path)) {
      file_path <- alt_file_mappings[[year_str]]
    }
    
    if (!file.exists(file_path)) {
      cat("Warning: File for year", year, "not found. Skipping.\n")
      next
    }
    
    # Process the wave
    report <- clean_wave(file_path, year, harmonization_plan)
    processing_reports[[year_str]] <- report
  }
  
  # Save processing summary
  summary_df <- map_dfr(processing_reports, ~ tibble(!!!.x))
  write_csv(summary_df, "processing_summary.csv")
  
  cat("\n=== Processing Complete ===\n")
  cat("Summary saved to: processing_summary.csv\n")
  
  return(processing_reports)
}

# Main execution
if (!interactive()) {
  reports <- process_multiple_waves()
}