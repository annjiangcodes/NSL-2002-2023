# =============================================================================
# EXTENDED DATA HARMONIZATION FOR 2014-2023 SURVEY EXTENSION
# =============================================================================
# Purpose: Harmonize 2014-2023 survey data and combine with 2002-2012
# Implements: Portes' immigrant generation framework with proper derivation
# Handles: NSL format (2014-2018) and ATP format (2021-2023) differences
# Author: Survey Harmonization Extension Project
# =============================================================================

library(haven)
library(dplyr)
library(stringr)
library(readr)
library(purrr)

source("scripts/02_harmonization/04_data_harmonization_fixed.R") # Load existing functions

cat("=== EXTENDED DATA HARMONIZATION 2014-2023 ===\n")
cat("Starting at:", as.character(Sys.time()), "\n\n")

# =============================================================================
# ENHANCED VARIABLE MAPPING DICTIONARIES FOR 2014-2023
# =============================================================================

# Extended age variable mappings
age_var_map_extended <- list(
  "2002" = c("AGE", "age", "RAGES", "qn_age"),
  "2004" = c("AGE1", "AGE2", "age", "RAGES"), 
  "2006" = c("qn74year", "age", "RAGES"),
  "2007" = "qn50",
  "2008" = "qn62", 
  "2009" = c("ageuse", "qn48", "age"),
  "2010" = "qn58",
  "2011" = "qn64", 
  "2012" = "qn67",
  # NEW 2014-2023 MAPPINGS
  "2014" = c("age", "age2"),
  "2015" = c("age", "age2"),
  "2016" = c("age", "age2"),
  "2018" = c("age", "age2"),
  "2021" = c("F_AGECAT", "F_AGE"),  # ATP format
  "2023" = c("F_AGECAT", "F_AGE")   # ATP format
)

# Extended gender variable mappings
gender_var_map_extended <- list(
  "2002" = c("GENDER", "gender", "RSEX"),
  "2004" = "QND18",
  "2006" = c("GENDER", "gender", "qnd18"),
  "2007" = "qnd18",
  "2008" = "qnd18",
  "2009" = c("gender", "qnd18"),
  "2010" = "qnd18",
  "2011" = "qnd18",
  "2012" = "qnd18",
  # NEW 2014-2023 MAPPINGS
  "2014" = "gender",
  "2015" = "sex",
  "2016" = "sex", 
  "2018" = "sex",
  "2021" = "F_GENDER",  # ATP format
  "2023" = "F_GENDER"   # ATP format
)

# Extended ethnicity mappings (Hispanic heritage/subgroups)
ethnicity_var_map_extended <- list(
  "2002" = "QN1",
  "2004" = "QN1",
  "2006" = "qn1",
  "2007" = "qn4",
  "2008" = "qn4", 
  "2009" = c("qn4", "heritage"),
  "2010" = c("qn1", "qn4"),
  "2011" = "qn4",
  "2012" = "qn4",
  # NEW 2014-2023 MAPPINGS
  "2014" = c("q2", "q3"),
  "2015" = c("q2", "q3"),
  "2016" = c("q2", "q3"),
  "2018" = c("q2", "q3"),
  "2021" = c("F_HISP", "F_HISP_ORIGIN"),  # ATP format
  "2023" = c("F_HISP", "F_HISP_ORIGIN")   # ATP format
)

# Extended language variable mappings
language_var_map_extended <- list(
  "2002" = "QN2",
  "2004" = "LANGUAGE",
  "2006" = "language",
  "2007" = "qn70",
  "2008" = "qn70",
  "2009" = c("Primary_language", "lang1", "interview_language"),
  "2010" = "qn70",
  "2011" = "qn70", 
  "2012" = "qn70",
  # NEW 2014-2023 MAPPINGS
  "2014" = c("primary_language", "endlang"),
  "2015" = c("primary_language", "endlang"),
  "2016" = c("primary_language", "endlang"),
  "2018" = c("primary_language", "endlang"),
  "2021" = "PRIMARY_LANGUAGE_W86",  # ATP format
  "2023" = "PRIMARY_LANGUAGE_W138" # ATP format (check actual name)
)

# NEW: Place of birth mappings (CRITICAL for generation derivation)
place_birth_var_map <- list(
  "2002" = c("QN10", "born_us", "place_birth"),
  "2004" = c("QN10", "born_us", "place_birth"),
  "2006" = c("qn10", "born_us", "place_birth"),
  "2007" = c("qn10", "born_us"),
  "2008" = c("combo5a", "born_us"),
  "2009" = c("qn10", "born_us"),
  "2010" = c("qn54", "born_us"),
  "2011" = c("qn70", "born_us"),
  "2012" = c("qn78", "born_us"),
  # NEW 2014-2023 MAPPINGS
  "2014" = c("q4", "nativity1"),
  "2015" = c("q4", "nativity1", "born"),
  "2016" = c("q4", "nativity1", "born"),
  "2018" = c("q4", "nativity1", "born"),
  "2021" = c("F_BIRTHPLACE_EXPANDED", "NATIVITY1_W86", "NATIVITY2_W86"),  # ATP format
  "2023" = c("F_BIRTHPLACE_EXPANDED", "NATIVITY1_W138", "NATIVITY2_W138")  # ATP format
)

# NEW: Citizenship variable mappings
citizenship_var_map <- list(
  "2007" = "qn9",
  "2008" = "combo14", 
  "2009" = "qn9",
  "2010" = "qn53",
  "2011" = "qn84",
  "2012" = "qn76",
  # NEW 2014-2023 MAPPINGS  
  "2014" = c("citizen", "citizenship"),
  "2015" = c("citizen", "citizenship"),
  "2016" = c("citizen", "citizenship"),
  "2018" = c("citizen", "citizenship"),
  "2021" = c("F_CITIZEN", "F_CITIZEN2"),  # ATP format
  "2023" = c("F_CITIZEN", "F_CITIZEN2")   # ATP format
)

# =============================================================================
# ENHANCED HARMONIZATION FUNCTIONS FOR 2014-2023
# =============================================================================

# Enhanced demographics function with 2014-2023 support
harmonize_demographics_extended <- function(data, year) {
  cat("  Harmonizing demographics for", year, "\n")
  
  # Age harmonization with extended mappings
  age <- rep(NA_real_, nrow(data))
  year_str <- as.character(year)
  
  if (year_str %in% names(age_var_map_extended)) {
    age_vars <- age_var_map_extended[[year_str]]
    
    for (var in age_vars) {
      if (var %in% names(data)) {
        age <- clean_values(data[[var]])
        
        # Handle different age formats including ATP
        if (var %in% c("AGE1", "AGE2")) {
          # Convert age ranges to midpoints (2004)
          age <- case_when(
            age == 1 ~ 24,   # 18-29
            age == 2 ~ 35,   # 30-39  
            age == 3 ~ 47,   # 40-54
            age == 4 ~ 62,   # 55+
            age == 5 ~ 70,   # 65+
            TRUE ~ NA_real_
          )
        } else if (var == "qn74year") {
          # 2006 age ranges
          age <- case_when(
            age >= 1 & age <= 20 ~ age + 20,
            TRUE ~ NA_real_
          )
        } else if (var == "F_AGECAT") {
          # ATP age categories - convert to midpoints
          age <- case_when(
            age == 1 ~ 21,   # 18-24
            age == 2 ~ 27,   # 25-29
            age == 3 ~ 32,   # 30-34
            age == 4 ~ 37,   # 35-39
            age == 5 ~ 42,   # 40-44
            age == 6 ~ 47,   # 45-49
            age == 7 ~ 52,   # 50-54
            age == 8 ~ 57,   # 55-59
            age == 9 ~ 62,   # 60-64
            age == 10 ~ 67,  # 65-69
            age == 11 ~ 72,  # 70-74
            age == 12 ~ 77,  # 75-79
            age == 13 ~ 82,  # 80+
            TRUE ~ NA_real_
          )
        } else if (var == "age2") {
          # NSL age categories 
          age <- case_when(
            age == 1 ~ 21,   # 18-24
            age == 2 ~ 27,   # 25-29
            age == 3 ~ 32,   # 30-34
            age == 4 ~ 37,   # 35-39
            age == 5 ~ 42,   # 40-44
            age == 6 ~ 47,   # 45-49
            age == 7 ~ 57,   # 50-64
            age == 8 ~ 72,   # 65+
            TRUE ~ NA_real_
          )
        }
        
        # Validate reasonable age range
        age <- ifelse(age >= 18 & age <= 100, age, NA_real_)
        break
      }
    }
  }
  
  # Gender harmonization with extended mappings
  gender <- rep(NA_real_, nrow(data))
  
  if (year_str %in% names(gender_var_map_extended)) {
    gender_vars <- gender_var_map_extended[[year_str]]
    
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

# Enhanced place of birth harmonization (CRITICAL for generation)
harmonize_place_birth_extended <- function(data, year) {
  place_birth <- rep(NA_real_, nrow(data))
  year_str <- as.character(year)
  
  if (year_str %in% names(place_birth_var_map)) {
    birth_vars <- place_birth_var_map[[year_str]]
    
    for (var in birth_vars) {
      if (var %in% names(data)) {
        birth_raw <- clean_values(data[[var]])
        
        # Harmonize to standard coding: 1=US born, 2=Foreign born
        if (var %in% c("F_BIRTHPLACE_EXPANDED")) {
          # ATP birthplace: 1=US, others are foreign countries
          place_birth <- case_when(
            birth_raw == 1 ~ 1,  # US born
            birth_raw >= 2 & birth_raw <= 98 ~ 2,  # Foreign born
            TRUE ~ NA_real_
          )
        } else if (var %in% c("NATIVITY1_W86", "NATIVITY2_W86", "NATIVITY1_W138", "NATIVITY2_W138")) {
          # ATP nativity: 1=US born, 2=Foreign born
          place_birth <- case_when(
            birth_raw == 1 ~ 1,  # US born
            birth_raw == 2 ~ 2,  # Foreign born
            TRUE ~ NA_real_
          )
        } else if (var == "q4") {
          # NSL q4: "Were you born on the island of Puerto Rico, in the United States, or in another country?"
          place_birth <- case_when(
            birth_raw %in% c(1, 2) ~ 1,  # Puerto Rico or US
            birth_raw == 3 ~ 2,           # Another country
            TRUE ~ NA_real_
          )
        } else if (var == "nativity1") {
          # Pre-coded nativity variable
          place_birth <- case_when(
            birth_raw == 1 ~ 1,  # US born
            birth_raw == 2 ~ 2,  # Foreign born
            TRUE ~ NA_real_
          )
        } else {
          # General pattern: 1=US, 2=Foreign, or binary coding
          place_birth <- case_when(
            birth_raw == 1 ~ 1,
            birth_raw == 2 ~ 2,
            TRUE ~ NA_real_
          )
        }
        
        # If we found valid data, break
        if (sum(!is.na(place_birth)) > 0) break
      }
    }
  }
  
  return(place_birth)
}

# NEW: Immigrant Generation Derivation (Portes Framework)
derive_immigrant_generation <- function(respondent_birth, parent1_birth = NULL, parent2_birth = NULL) {
  # Portes' three-generation framework:
  # 1st generation: Foreign-born respondent
  # 2nd generation: US-born respondent with ≥1 foreign-born parent
  # 3rd+ generation: US-born respondent with both parents US-born
  
  generation <- rep(NA_real_, length(respondent_birth))
  
  # First generation: Respondent foreign-born
  generation <- case_when(
    respondent_birth == 2 ~ 1,  # Foreign-born respondent
    respondent_birth == 1 ~ {
      # US-born respondent - check parents if available
      if (!is.null(parent1_birth) || !is.null(parent2_birth)) {
        # If we have parent data
        parent1_foreign <- if (!is.null(parent1_birth)) parent1_birth == 2 else FALSE
        parent2_foreign <- if (!is.null(parent2_birth)) parent2_birth == 2 else FALSE
        
        case_when(
          parent1_foreign | parent2_foreign ~ 2,  # 2nd gen: ≥1 parent foreign
          !parent1_foreign & !parent2_foreign ~ 3,  # 3rd+ gen: both parents US
          TRUE ~ NA_real_  # Missing parent data
        )
      } else {
        # No parent data available - cannot distinguish 2nd from 3rd+ gen
        NA_real_
      }
    },
    TRUE ~ NA_real_
  )
  
  return(generation)
}

# Enhanced citizenship harmonization
harmonize_citizenship_extended <- function(data, year) {
  citizenship <- rep(NA_real_, nrow(data))
  year_str <- as.character(year)
  
  if (year_str %in% names(citizenship_var_map)) {
    citizen_vars <- citizenship_var_map[[year_str]]
    
    for (var in citizen_vars) {
      if (var %in% names(data)) {
        citizen_raw <- clean_values(data[[var]])
        
        # Standardize to: 1=US Citizen, 2=Non-citizen
        if (var %in% c("F_CITIZEN", "F_CITIZEN2")) {
          # ATP citizenship
          citizenship <- case_when(
            citizen_raw == 1 ~ 1,  # US citizen
            citizen_raw %in% c(2, 3, 4) ~ 2,  # Various non-citizen categories
            TRUE ~ NA_real_
          )
        } else {
          # NSL/other formats
          citizenship <- case_when(
            citizen_raw == 1 ~ 1,  # Citizen
            citizen_raw == 2 ~ 2,  # Non-citizen
            TRUE ~ NA_real_
          )
        }
        
        if (sum(!is.na(citizenship)) > 0) break
      }
    }
  }
  
  return(citizenship)
}

# =============================================================================
# EXTENDED HARMONIZATION PIPELINE FOR 2014-2023
# =============================================================================

harmonize_survey_extended <- function(file_path, year, survey_type = "NSL") {
  cat("Processing", year, "survey (", survey_type, "):\n")
  cat("  File:", basename(file_path), "\n")
  
  # Load data with encoding handling
  data <- NULL
  try(data <- read_sav(file_path), silent = TRUE)
  if (is.null(data)) {
    try(data <- read_sav(file_path, encoding = "latin1"), silent = TRUE)
  }
  
  if (is.null(data)) {
    cat("  ERROR: Could not load data\n")
    return(NULL)
  }
  
  cat("  Loaded:", nrow(data), "observations,", ncol(data), "variables\n")
  
  # Apply harmonization functions
  demographics <- harmonize_demographics_extended(data, year)
  place_birth <- harmonize_place_birth_extended(data, year)
  citizenship_status <- harmonize_citizenship_extended(data, year)
  
  # Derive immigrant generation using place of birth
  immigrant_generation <- derive_immigrant_generation(place_birth)
  
  # Apply existing harmonization functions for other variables
  ethnicity <- harmonize_race_ethnicity(data, year)$ethnicity  # From existing script
  language_home <- harmonize_language(data, year)             # From existing script
  
  # Create harmonized dataset
  harmonized <- tibble(
    survey_year = year,
    age = demographics$age,
    gender = demographics$gender,
    race = rep(NA_real_, nrow(data)),  # Limited availability in 2014-2023
    ethnicity = ethnicity,
    language_home = language_home,
    citizenship_status = citizenship_status,
    place_birth = place_birth,
    immigrant_generation = immigrant_generation,
    immigration_attitude = rep(NA_real_, nrow(data)),      # To be implemented
    border_security_attitude = rep(NA_real_, nrow(data)),  # To be implemented
    political_party = rep(NA_real_, nrow(data)),           # To be implemented
    vote_intention = rep(NA_real_, nrow(data)),            # To be implemented
    approval_rating = rep(NA_real_, nrow(data))            # To be implemented
  )
  
  # Quality check
  cat("  Variable coverage:\n")
  for (var in c("age", "gender", "ethnicity", "place_birth", "immigrant_generation")) {
    pct_available <- round(100 * sum(!is.na(harmonized[[var]])) / nrow(harmonized), 1)
    cat("    ", var, ":", pct_available, "%\n")
  }
  
  return(harmonized)
}

# =============================================================================
# PROCESS ALL 2014-2023 SURVEYS
# =============================================================================

survey_files_extended <- list(
  "2014" = list(file = "data/raw/NSL2014_FOR RELEASE.sav", type = "NSL"),
  "2015" = list(file = "data/raw/NSL2015_FOR RELEASE.sav", type = "NSL"),
  "2016" = list(file = "data/raw/NSL 2016_FOR RELEASE.sav", type = "NSL"),
  "2018" = list(file = "data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav", type = "NSL"),
  "2021" = list(file = "data/raw/2021 ATP W86.sav", type = "ATP"),
  "2023" = list(file = "data/raw/2023ATP W138.sav", type = "ATP")
)

cat("=== PROCESSING 2014-2023 SURVEYS ===\n\n")

# Process each survey year
for (year_name in names(survey_files_extended)) {
  survey_info <- survey_files_extended[[year_name]]
  
  if (file.exists(survey_info$file)) {
    harmonized_data <- harmonize_survey_extended(
      survey_info$file, 
      year_name, 
      survey_info$type
    )
    
    if (!is.null(harmonized_data)) {
      # Save individual year file
      output_file <- paste0("data/processed/cleaned_data/cleaned_", year_name, ".csv")
      write_csv(harmonized_data, output_file)
      cat("  Saved:", output_file, "\n")
    }
  } else {
    cat("  WARNING: File not found:", survey_info$file, "\n")
  }
  
  cat("\n")
}

cat("=== 2014-2023 HARMONIZATION COMPLETE ===\n")
cat("Completed at:", as.character(Sys.time()), "\n")