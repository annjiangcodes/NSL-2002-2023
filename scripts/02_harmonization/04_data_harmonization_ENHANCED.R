# Enhanced Data Harmonization Script for 2002-2012
# Fixes missing demographic variables issue

library(haven)
library(dplyr)
library(stringr)
library(readr)
library(labelled)
library(purrr)

# Improved function to harmonize demographic variables
harmonize_demographics_enhanced <- function(data, year) {
  # Age harmonization - comprehensive approach
  age <- rep(NA_real_, nrow(data))
  
  # Year-specific age variables
  age_var_map <- list(
    "2007" = "qn50",
    "2008" = "qn62", 
    "2009" = c("ageuse", "qn48", "age"),
    "2010" = "qn58",
    "2011" = "qn64", 
    "2012" = "qn67"
  )
  
  year_str <- as.character(year)
  if (year_str %in% names(age_var_map)) {
    age_vars <- age_var_map[[year_str]]
    for (var in age_vars) {
      if (var %in% names(data)) {
        age <- clean_values(data[[var]])
        break
      }
    }
  }
  
  # Fallback: search for any age-related variable
  if (all(is.na(age))) {
    age_vars <- names(data)[grepl("age|qn.*[0-9]+.*age", names(data), ignore.case = TRUE)]
    if (length(age_vars) > 0) {
      age <- clean_values(data[[age_vars[1]]])
    }
  }
  
  # Gender harmonization - comprehensive approach
  gender <- rep(NA_real_, nrow(data))
  
  # Year-specific gender variables
  gender_var_map <- list(
    "2007" = "qnd18",
    "2008" = "qnd18",
    "2009" = c("gender", "qnd18"),
    "2010" = "qnd18",
    "2011" = "qnd18",
    "2012" = "qnd18"
  )
  
  if (year_str %in% names(gender_var_map)) {
    gender_vars <- gender_var_map[[year_str]]
    for (var in gender_vars) {
      if (var %in% names(data)) {
        gender <- clean_values(data[[var]])
        # Standardize coding (1=Male, 2=Female)
        gender <- case_when(
          gender == 1 ~ 1,  # Male
          gender == 2 ~ 2,  # Female
          TRUE ~ NA_real_
        )
        break
      }
    }
  }
  
  return(list(age = age, gender = gender))
}

# Enhanced function to harmonize race and ethnicity
harmonize_race_ethnicity_enhanced <- function(data, year) {
  race <- rep(NA_real_, nrow(data))
  ethnicity <- rep(NA_real_, nrow(data))
  
  # Ethnicity harmonization (Hispanic/Latino heritage)
  ethnicity_var_map <- list(
    "2007" = "qn4",
    "2008" = "qn4", 
    "2009" = c("qn4", "heritage"),
    "2010" = c("qn1", "qn4"),
    "2011" = "qn4",
    "2012" = "qn4"
  )
  
  year_str <- as.character(year)
  if (year_str %in% names(ethnicity_var_map)) {
    eth_vars <- ethnicity_var_map[[year_str]]
    for (var in eth_vars) {
      if (var %in% names(data)) {
        ethnicity <- clean_values(data[[var]])
        break
      }
    }
  }
  
  # Race harmonization (where available)
  race_var_map <- list(
    "2009" = c("qn11", "qn118", "race"),
    "2010" = "qn11",
    "2011" = "qn11"
  )
  
  if (year_str %in% names(race_var_map)) {
    race_vars <- race_var_map[[year_str]]
    for (var in race_vars) {
      if (var %in% names(data)) {
        race <- clean_values(data[[var]])
        break
      }
    }
  }
  
  return(list(race = race, ethnicity = ethnicity))
}

# Enhanced language harmonization
harmonize_language_enhanced <- function(data, year) {
  language <- rep(NA_real_, nrow(data))
  
  # Language variable mapping
  lang_var_map <- list(
    "2007" = "qn70",  # Interview language
    "2008" = "qn70",
    "2009" = c("Primary_language", "lang1", "interview_language"),
    "2010" = "qn70",
    "2011" = "qn70", 
    "2012" = "qn70"
  )
  
  year_str <- as.character(year)
  if (year_str %in% names(lang_var_map)) {
    lang_vars <- lang_var_map[[year_str]]
    for (var in lang_vars) {
      if (var %in% names(data)) {
        language <- clean_values(data[[var]])
        # Standardize to 1=English, 2=Spanish/Other
        language <- case_when(
          language == 1 ~ 1,  # English
          language == 2 ~ 2,  # Spanish/Other
          language > 2 ~ 2,   # Other languages → Spanish/Other
          TRUE ~ NA_real_
        )
        break
      }
    }
  }
  
  return(language)
}

# Function to clean values (from original script)
clean_values <- function(x) {
  case_when(
    x %in% c(-999, -99, -9, -1, 8, 9, 98, 99, 999) ~ NA_real_,
    TRUE ~ as.numeric(x)
  )
}

# Enhanced main harmonization function
harmonize_year_enhanced <- function(year) {
  cat("Processing", year, "data with enhanced harmonization...\n")
  
  # File mapping (same as original)
  file_map <- list(
    "2002" = "2002 RAE008b FINAL DATA FOR RELEASE.sav",
    "2004" = "2004 Political Survey Rev 1-6-05.sav", 
    "2006" = "f1171_050207 uploaded dataset.sav",
    "2007" = "publicreleaseNSL07_UPDATED_3.7.22.sav",
    "2008" = "PHCNSL2008aPublicRelease_UPDATED 3.7.22.sav",
    "2009" = "PHCNSL2009PublicRelease.sav",
    "2010" = "PHCNSL2010PublicRelease_UPDATED 3.7.22.sav",
    "2011" = "PHCNSL2011PubRelease_UPDATED 3.7.22.sav",
    "2012" = "PHCNSL2012PublicRelease_UPDATED 3.7.22.sav"
  )
  
  year_str <- as.character(year)
  if (!year_str %in% names(file_map)) {
    stop("Year ", year, " not supported")
  }
  
  filename <- file_map[[year_str]]
  if (!file.exists(filename)) {
    stop("File not found: ", filename)
  }
  
  # Read data
  data <- read_sav(filename)
  cat("Original data dimensions:", nrow(data), ncol(data), "\n")
  
  # Apply enhanced harmonization
  demographics <- harmonize_demographics_enhanced(data, year)
  race_eth <- harmonize_race_ethnicity_enhanced(data, year)
  language <- harmonize_language_enhanced(data, year)
  
  # Use existing functions for other variables (assuming they work)
  citizenship_status <- if(exists("harmonize_citizenship")) {
    harmonize_citizenship(data, year)
  } else {
    rep(NA_real_, nrow(data))
  }
  
  place_birth <- if(exists("harmonize_place_birth")) {
    harmonize_place_birth(data, year)
  } else {
    rep(NA_real_, nrow(data))
  }
  
  immigrant_generation <- if(exists("derive_immigrant_generation")) {
    derive_immigrant_generation(data, year)
  } else {
    rep(NA_real_, nrow(data))
  }
  
  # Create enhanced harmonized dataset
  harmonized_data <- data.frame(
    survey_year = year,
    age = demographics$age,
    gender = demographics$gender,
    race = race_eth$race,
    ethnicity = race_eth$ethnicity,
    language_home = language,
    citizenship_status = citizenship_status,
    place_birth = place_birth,
    immigrant_generation = immigrant_generation,
    stringsAsFactors = FALSE
  )
  
  # Print summary
  cat("Enhanced harmonized data dimensions:", nrow(harmonized_data), ncol(harmonized_data), "\n")
  cat("Variable completeness:\n")
  for (var in names(harmonized_data)[-1]) {  # Skip survey_year
    n_missing <- sum(is.na(harmonized_data[[var]]))
    pct_missing <- round(100 * n_missing / nrow(harmonized_data), 1)
    n_unique <- length(unique(harmonized_data[[var]][!is.na(harmonized_data[[var]])]))
    cat(sprintf("  %s: %d unique values, %s%% missing\n", var, n_unique, pct_missing))
  }
  
  return(harmonized_data)
}

# Test the enhanced harmonization on 2007 data
if (interactive() || !exists("test_run_complete")) {
  cat("=== Testing Enhanced Harmonization on 2007 ===\n")
  
  # Source the original functions we need
  if (file.exists("04_data_harmonization_fixed.R")) {
    source("04_data_harmonization_fixed.R")
  }
  
  test_2007 <- harmonize_year_enhanced(2007)
  cat("2007 test completed successfully!\n")
  test_run_complete <- TRUE
}