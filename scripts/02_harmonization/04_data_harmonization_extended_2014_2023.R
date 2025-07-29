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
  "2022" = c("F_AGECAT", "F_AGE"),  # ATP format
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
  "2022" = "F_GENDER",  # ATP format
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
  "2022" = c("F_HISP", "F_HISP_ORIGIN"),  # ATP format
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
  "2022" = "PRIMARY_LANGUAGE_W113",  # ATP format
  "2023" = "PRIMARY_LANGUAGE_W138" # ATP format
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
  "2022" = c("F_BIRTHPLACE_EXPANDED", "NATIVITY1_W113", "NATIVITY2_W113"),  # ATP format
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
  "2022" = c("F_CITIZEN", "F_CITIZEN2"),  # ATP format
  "2023" = c("F_CITIZEN", "F_CITIZEN2")   # ATP format
)

# NEW: Parent nativity variable mappings (CRITICAL for proper generation)
parent_nativity_var_map <- list(
  # NSL years - composite parent variable
  "2014" = list(mother = NULL, father = NULL, composite = "parent"),
  "2015" = list(mother = NULL, father = NULL, composite = "parent"),
  "2016" = list(mother = NULL, father = NULL, composite = "parent"),
  "2018" = list(mother = NULL, father = NULL, composite = "parent"),
  
  # ATP years - individual parent variables
  "2021" = list(mother = "MOTHERNAT_W86", father = "FATHERNAT_W86", composite = NULL),
  "2022" = list(mother = "MOTHERNAT_W113", father = "FATHERNAT_W113", composite = NULL),
  "2023" = list(mother = "MOTHERNAT_W138", father = "FATHERNAT_W138", composite = NULL)
)

# NEW: Pre-calculated generation variable mappings
precalc_generation_var_map <- list(
  "2021" = "IMMGEN_W86",      # Use Puerto Rico as US version
  "2022" = "IMMGEN1_W113",    # Use Puerto Rico as US version  
  "2023" = "IMMGEN_W138"      # Check if this exists
)

# =============================================================================
# COMPREHENSIVE IMMIGRATION POLICY & POLITICAL ATTITUDE MAPPINGS
# =============================================================================
# Based on mini-project analysis and systematic variable discovery

# EXPANDED IMMIGRATION POLICY VARIABLE MAPPINGS (Including Implicit Measures)
immigration_policy_var_map <- list(
  # Trump Support/Approval  
  "trump_support" = list(
    "2018" = "qn14a",  # Trump approval
    "2022" = "TRUMPFUT_W113"  # Trump future support
  ),
  
  # Border Wall/Security
  "border_wall" = list(
    "2016" = c("qn29a", "qn29b", "qn29c", "qn29d"),  # Multiple border security questions
    "2018" = "qn29"  # Border wall favorability
  ),
  
  # Immigration Level/Population Opinion
  "immigration_level" = list(
    "2018" = "qn31"  # Too many immigrants opinion
  ),
  
  # NEW: Border/Asylum Performance (Implicit Immigration Measure)
  "border_asylum_performance" = list(
    "2021" = "BRDERJOB_MOD_W86"  # Government performance on border asylum seekers
  ),
  
  # NEW: Presidential Performance (Implicit through Immigration Lens)
  "presidential_performance" = list(
    "2018" = "qn14a",  # Trump approval
    "2022" = c("BIDENDESC_MDL_W113", "BIDENDESC_ORD_W113", "BIDENDESC_MENT_W113", "BIDENDESC_HON_W113")  # Biden evaluations
  ),
  
  # NEW: Issue Priorities (Immigration-Related Concerns)
  "issue_priorities" = list(
    "2022" = c("ISSUECONG_CRIM_W113", "ISSUECONG_ECON_W113", "ISSUECONG_EDUC_W113", "ISSUECONG_RCE_W113")
  ),
  
  # DACA/Dreamer Support (to be expanded)
  "daca_support" = list(),
  
  # Deportation Policy (to be expanded)  
  "deportation_policy" = list(),
  
  # Legalization/Path to Citizenship (to be expanded)
  "legalization_support" = list()
)

# POLITICAL ATTITUDE & AFFILIATION MAPPINGS (Expanded)
political_attitude_var_map <- list(
  # Party Identification
  "party_id" = list(
    "2014" = c("party", "partyln", "party_combo"),
    "2015" = c("party", "partyln", "party_combo"),
    "2016" = c("party", "partyln", "party_combo"),
    "2018" = c("party", "partyln", "party_combo"),
    "2021" = c("F_PARTY_FINAL", "F_PARTYLN_FINAL", "F_PARTYSUM_FINAL"),
    "2022" = c("F_PARTY_FINAL", "F_PARTYLN_FINAL", "F_PARTYSUM_FINAL")
  ),
  
  # Presidential Approval (to be expanded)
  "presidential_approval" = list(
    "2018" = "qn14a"  # Trump approval in 2018
  ),
  
  # Congressional Approval (to be identified)
  "congressional_approval" = list(),
  
  # Vote Intention/Choice (to be identified)
  "vote_intention" = list()
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
        } else if (var %in% c("NATIVITY1_W86", "NATIVITY2_W86", "NATIVITY1_W113", "NATIVITY2_W113", "NATIVITY1_W138", "NATIVITY2_W138")) {
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

# ENHANCED: Immigrant Generation Derivation with Pre-calculated Variables
derive_immigrant_generation_enhanced <- function(data, year) {
  year_str <- as.character(year)
  
  # First try pre-calculated generation variables (most reliable)
  if (year_str %in% names(precalc_generation_var_map)) {
    precalc_var <- precalc_generation_var_map[[year_str]]
    
    if (!is.null(precalc_var) && precalc_var %in% names(data)) {
      cat("    Using pre-calculated generation variable:", precalc_var, "\n")
      generation <- clean_values(data[[precalc_var]])
      
      # Keep only valid generation values (1, 2, 3)
      generation <- case_when(
        generation %in% c(1, 2, 3) ~ generation,
        TRUE ~ NA_real_
      )
      
      return(generation)
    }
  }
  
  # Fallback to manual derivation using parent nativity
  cat("    Deriving generation from parent nativity data\n")
  
  # Get respondent nativity
  respondent_birth <- harmonize_place_birth_extended(data, year)
  
  # Get parent nativity information
  if (year_str %in% names(parent_nativity_var_map)) {
    parent_info <- parent_nativity_var_map[[year_str]]
    
    if (!is.null(parent_info$composite) && parent_info$composite %in% names(data)) {
      # NSL format: composite parent variable
      parent_composite <- clean_values(data[[parent_info$composite]])
      
      generation <- case_when(
        respondent_birth == 2 ~ 1,  # Foreign-born = 1st generation
        respondent_birth == 1 & parent_composite == 2 ~ 2,  # US-born + foreign parent(s) = 2nd gen
        respondent_birth == 1 & parent_composite == 1 ~ 3,  # US-born + US parent(s) = 3rd+ gen
        TRUE ~ NA_real_
      )
      
    } else if (!is.null(parent_info$mother) && !is.null(parent_info$father)) {
      # ATP format: individual parent variables
      mother_var <- parent_info$mother
      father_var <- parent_info$father
      
      if (mother_var %in% names(data) && father_var %in% names(data)) {
        mother_birth <- clean_values(data[[mother_var]])
        father_birth <- clean_values(data[[father_var]])
        
        generation <- case_when(
          respondent_birth == 2 ~ 1,  # Foreign-born = 1st generation
          respondent_birth == 1 & (mother_birth == 2 | father_birth == 2) ~ 2,  # US-born + foreign parent = 2nd gen
          respondent_birth == 1 & mother_birth == 1 & father_birth == 1 ~ 3,  # US-born + US parents = 3rd+ gen
          TRUE ~ NA_real_
        )
      } else {
        # No parent data available
        generation <- case_when(
          respondent_birth == 2 ~ 1,  # Can only identify 1st generation
          TRUE ~ NA_real_
        )
      }
    } else {
      # No parent data available
      generation <- case_when(
        respondent_birth == 2 ~ 1,  # Can only identify 1st generation
        TRUE ~ NA_real_
      )
    }
  } else {
    # No parent nativity mapping for this year
    generation <- case_when(
      respondent_birth == 2 ~ 1,  # Can only identify 1st generation
      TRUE ~ NA_real_
    )
  }
  
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
# ENHANCED HARMONIZATION FUNCTIONS FOR COMPLEX POLICY VARIABLES
# =============================================================================

# UPDATED: Comprehensive Immigration Policy Harmonization with Implicit Measures
harmonize_immigration_policies <- function(data, year) {
  cat("  Harmonizing immigration policies for", year, "\n")
  year_str <- as.character(year)
  
  # Initialize all immigration policy variables
  trump_support <- rep(NA_real_, nrow(data))
  border_wall_support <- rep(NA_real_, nrow(data))
  immigration_level_concern <- rep(NA_real_, nrow(data))
  
  # NEW: Implicit measures
  border_asylum_performance <- rep(NA_real_, nrow(data))
  presidential_performance <- rep(NA_real_, nrow(data))
  crime_priority <- rep(NA_real_, nrow(data))
  
  # Trump Support/Approval
  if (year_str %in% names(immigration_policy_var_map$trump_support)) {
    trump_vars <- immigration_policy_var_map$trump_support[[year_str]]
    for (var in trump_vars) {
      if (var %in% names(data)) {
        trump_raw <- clean_values(data[[var]])
        
        if (var == "qn14a") {
          # 2018: 1=Approve, 2=Disapprove
          trump_support <- case_when(
            trump_raw == 1 ~ 1,  # Approve
            trump_raw == 2 ~ 0,  # Disapprove
            TRUE ~ NA_real_
          )
        } else if (var == "TRUMPFUT_W113") {
          # 2022: 1=Support, 2=Not support  
          trump_support <- case_when(
            trump_raw == 1 ~ 1,  # Support
            trump_raw == 2 ~ 0,  # Not support
            TRUE ~ NA_real_
          )
        }
        break
      }
    }
  }
  
  # Border Wall/Security Support
  if (year_str %in% names(immigration_policy_var_map$border_wall)) {
    wall_vars <- immigration_policy_var_map$border_wall[[year_str]]
    
    if (year == "2018" && "qn29" %in% names(data)) {
      # 2018: Simple wall support
      wall_raw <- clean_values(data$qn29)
      border_wall_support <- case_when(
        wall_raw == 1 ~ 1,  # Favor
        wall_raw == 2 ~ 0,  # Oppose
        TRUE ~ NA_real_
      )
    } else if (year == "2016") {
      # 2016: Multiple border security questions - create composite
      border_scores <- matrix(NA, nrow = nrow(data), ncol = 4)
      
      for (i in 1:4) {
        var_name <- paste0("qn29", letters[i])
        if (var_name %in% names(data)) {
          raw_vals <- clean_values(data[[var_name]])
          # Assuming 1=Strongly favor, 2=Favor, 3=Oppose, 4=Strongly oppose
          border_scores[, i] <- case_when(
            raw_vals %in% c(1, 2) ~ 1,  # Favor/Strongly favor
            raw_vals %in% c(3, 4) ~ 0,  # Oppose/Strongly oppose
            TRUE ~ NA_real_
          )
        }
      }
      
      # Average across the four border security questions
      border_wall_support <- rowMeans(border_scores, na.rm = TRUE)
      border_wall_support[is.nan(border_wall_support)] <- NA
    }
  }
  
  # Immigration Level Concern
  if (year_str %in% names(immigration_policy_var_map$immigration_level)) {
    level_vars <- immigration_policy_var_map$immigration_level[[year_str]]
    for (var in level_vars) {
      if (var %in% names(data)) {
        level_raw <- clean_values(data[[var]])
        
        if (var == "qn31") {
          # 2018: 1=Too many, 2=Too few, 3=Right amount
          immigration_level_concern <- case_when(
            level_raw == 1 ~ 1,  # Too many (restrictionist view)
            level_raw %in% c(2, 3) ~ 0,  # Too few or right amount
            TRUE ~ NA_real_
          )
        }
        break
      }
    }
  }
  
  # NEW: Border/Asylum Performance (2021 - Implicit measure)
  if (year_str %in% names(immigration_policy_var_map$border_asylum_performance)) {
    asylum_vars <- immigration_policy_var_map$border_asylum_performance[[year_str]]
    for (var in asylum_vars) {
      if (var %in% names(data)) {
        asylum_raw <- clean_values(data[[var]])
        
        if (var == "BRDERJOB_MOD_W86") {
          # 2021: Rating government performance on border asylum
          # 1=Excellent, 2=Good, 3=Only fair, 4=Poor
          # Reverse code: poor performance = restrictionist sentiment
          border_asylum_performance <- case_when(
            asylum_raw %in% c(3, 4) ~ 1,  # Only fair/Poor = restrictionist
            asylum_raw %in% c(1, 2) ~ 0,  # Excellent/Good = not restrictionist
            TRUE ~ NA_real_
          )
        }
        break
      }
    }
  }
  
  # NEW: Presidential Performance (2022 Biden evaluations)
  if (year_str %in% names(immigration_policy_var_map$presidential_performance)) {
    pres_vars <- immigration_policy_var_map$presidential_performance[[year_str]]
    
    if (year == "2022") {
      # Multiple Biden evaluation dimensions - create composite
      biden_scores <- matrix(NA, nrow = nrow(data), ncol = 4)
      biden_vars <- c("BIDENDESC_MDL_W113", "BIDENDESC_ORD_W113", "BIDENDESC_MENT_W113", "BIDENDESC_HON_W113")
      
      for (i in 1:4) {
        var_name <- biden_vars[i]
        if (var_name %in% names(data)) {
          raw_vals <- clean_values(data[[var_name]])
          # 1=Very well, 2=Somewhat well, 3=Not too well, 4=Not at all well
          # Reverse: negative evaluation = restrictionist sentiment
          biden_scores[, i] <- case_when(
            raw_vals %in% c(3, 4) ~ 1,  # Negative evaluation
            raw_vals %in% c(1, 2) ~ 0,  # Positive evaluation
            TRUE ~ NA_real_
          )
        }
      }
      
      # Average Biden negativity as proxy for restrictionism
      presidential_performance <- rowMeans(biden_scores, na.rm = TRUE)
      presidential_performance[is.nan(presidential_performance)] <- NA
    } else if (year == "2018") {
      # Use Trump approval directly
      presidential_performance <- trump_support
    }
  }
  
  # NEW: Issue Priorities (2022 - Crime priority as immigration proxy)
  if (year_str %in% names(immigration_policy_var_map$issue_priorities)) {
    issue_vars <- immigration_policy_var_map$issue_priorities[[year_str]]
    
    if ("ISSUECONG_CRIM_W113" %in% names(data)) {
      crime_raw <- clean_values(data$ISSUECONG_CRIM_W113)
      # 1=Very important, 2=Somewhat important, 3=Not too important, 4=Not at all important
      # High crime priority = potential restrictionist sentiment
      crime_priority <- case_when(
        crime_raw == 1 ~ 1,  # Very important
        crime_raw %in% c(2, 3, 4) ~ 0,  # Less important
        TRUE ~ NA_real_
      )
    }
  }
  
  # Create EXPANDED composite immigration restrictionism score
  # Now includes: Trump support, border wall, immigration level, asylum performance, presidential negativity, crime priority
  valid_indicators <- cbind(trump_support, border_wall_support, immigration_level_concern, 
                           border_asylum_performance, presidential_performance, crime_priority)
  
  # Only create composite if at least one indicator is available
  has_any_data <- rowSums(!is.na(valid_indicators)) > 0
  
  # Calculate composite as average of available indicators (0-1 scale)
  immigration_restrictionism_composite <- ifelse(has_any_data, 
                                                rowMeans(valid_indicators, na.rm = TRUE), 
                                                NA_real_)
  
  return(list(
    trump_support = trump_support,
    border_wall_support = border_wall_support, 
    immigration_level_concern = immigration_level_concern,
    border_asylum_performance = border_asylum_performance,
    presidential_performance = presidential_performance,
    crime_priority = crime_priority,
    immigration_restrictionism_composite = immigration_restrictionism_composite
  ))
}

# NEW: Comprehensive Political Attitude Harmonization  
harmonize_political_attitudes <- function(data, year) {
  cat("  Harmonizing political attitudes for", year, "\n")
  year_str <- as.character(year)
  
  # Initialize political variables
  party_identification <- rep(NA_real_, nrow(data))
  
  # Party Identification
  if (year_str %in% names(political_attitude_var_map$party_id)) {
    party_vars <- political_attitude_var_map$party_id[[year_str]]
    
    for (var in party_vars) {
      if (var %in% names(data)) {
        party_raw <- clean_values(data[[var]])
        
        if (var %in% c("party", "F_PARTY_FINAL")) {
          # Standard party coding: 1=Republican, 2=Democrat, 3=Independent, etc.
          party_identification <- case_when(
            party_raw == 1 ~ 1,  # Republican
            party_raw == 2 ~ 2,  # Democrat  
            party_raw == 3 ~ 3,  # Independent
            party_raw == 4 ~ 4,  # Other
            TRUE ~ NA_real_
          )
        } else if (var %in% c("partyln", "F_PARTYLN_FINAL")) {
          # Leaning party identification (includes leaners)
          party_identification <- case_when(
            party_raw == 1 ~ 1,  # Republican/Lean Republican
            party_raw == 2 ~ 2,  # Democrat/Lean Democrat
            party_raw == 3 ~ 3,  # Independent
            TRUE ~ NA_real_
          )
        }
        
        # Use first available variable
        if (sum(!is.na(party_identification)) > 0) break
      }
    }
  }
  
  return(list(
    party_identification = party_identification
  ))
}

# =============================================================================
# UPDATED HARMONIZATION PIPELINE FOR 2014-2023
# =============================================================================

harmonize_survey_extended <- function(file_path, year, survey_type = "NSL") {
  cat("Processing", year, "survey (", survey_type, "):\n")
  cat("  File:", basename(file_path), "\n")
  
  # Load data with encoding handling and format detection
  data <- NULL
  
  # Handle different file formats
  if (str_detect(file_path, "\\.dta$")) {
    # Stata format
    try(data <- read_dta(file_path), silent = TRUE)
  } else {
    # SPSS format
    try(data <- read_sav(file_path), silent = TRUE)
    if (is.null(data)) {
      try(data <- read_sav(file_path, encoding = "latin1"), silent = TRUE)
    }
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
  immigrant_generation <- derive_immigrant_generation_enhanced(data, year)
  
  # NEW: Apply comprehensive policy harmonization
  immigration_policies <- harmonize_immigration_policies(data, year)
  political_attitudes <- harmonize_political_attitudes(data, year)
  
  # Apply existing harmonization functions for other variables
  ethnicity <- harmonize_race_ethnicity(data, year)$ethnicity  # From existing script
  language_home <- harmonize_language(data, year)             # From existing script
  
  # Create EXPANDED harmonized dataset with new policy variables
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
    
    # EXPANDED: Direct immigration policy variables
    trump_support = immigration_policies$trump_support,
    border_wall_support = immigration_policies$border_wall_support,
    immigration_level_concern = immigration_policies$immigration_level_concern,
    
    # NEW: Implicit immigration attitude measures
    border_asylum_performance = immigration_policies$border_asylum_performance,
    presidential_performance = immigration_policies$presidential_performance,
    crime_priority = immigration_policies$crime_priority,
    
    # ENHANCED: Comprehensive restrictionism composite
    immigration_restrictionism_composite = immigration_policies$immigration_restrictionism_composite,
    
    # Political attitude variables
    party_identification = political_attitudes$party_identification,
    
    # Legacy variables (mapped to new framework)
    immigration_attitude = immigration_policies$immigration_restrictionism_composite,  # Map to composite
    border_security_attitude = immigration_policies$border_wall_support,              # Map to wall support
    political_party = political_attitudes$party_identification,                       # Map to party ID
    vote_intention = rep(NA_real_, nrow(data)),                                      # To be implemented
    approval_rating = immigration_policies$trump_support                             # Map to Trump support
  )
  
  # Quality check with expanded variables
  cat("  Variable coverage:\n")
  key_vars <- c("age", "gender", "ethnicity", "place_birth", "immigrant_generation", 
                "trump_support", "border_wall_support", "border_asylum_performance", 
                "presidential_performance", "crime_priority", "party_identification")
  
  for (var in key_vars) {
    if (var %in% names(harmonized)) {
      pct_available <- round(100 * sum(!is.na(harmonized[[var]])) / nrow(harmonized), 1)
      cat("    ", var, ":", pct_available, "%\n")
    }
  }
  
  return(harmonized)
}

# =============================================================================
# PROCESS ALL 2014-2023 SURVEYS (INCLUDING 2022)
# =============================================================================

survey_files_extended <- list(
  "2014" = list(file = "data/raw/NSL2014_FOR RELEASE.sav", type = "NSL"),
  "2015" = list(file = "data/raw/NSL2015_FOR RELEASE.sav", type = "NSL"),
  "2016" = list(file = "data/raw/NSL 2016_FOR RELEASE.sav", type = "NSL"),
  "2018" = list(file = "data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav", type = "NSL"),
  "2021" = list(file = "data/raw/2021 ATP W86.sav", type = "ATP"),
  "2022" = list(file = "data/raw/NSL 2022 complete dataset national survey of latinos 2022.dta", type = "ATP"),
  "2023" = list(file = "data/raw/2023ATP W138.sav", type = "ATP")
)

cat("=== PROCESSING 2014-2023 SURVEYS (INCLUDING 2022) ===\n\n")

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