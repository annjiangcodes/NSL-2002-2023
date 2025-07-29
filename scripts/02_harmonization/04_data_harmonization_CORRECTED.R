#!/usr/bin/env Rscript

# ===================================================================
# CORRECTED Data Harmonization Script for Immigration Attitudes Study
# Implements Portes Protocol for Immigrant Generation Classification
# Fixes age variables and ensures proper values_recode standardization
# ===================================================================

# Load required libraries
library(haven)
library(dplyr)
library(stringr)
library(readr)
library(labelled)

cat("=== CORRECTED Immigration Attitudes Data Harmonization 2002-2007 ===\n")

# Create output directory
dir.create("cleaned_data_CORRECTED", showWarnings = FALSE)

# ===================================================================
# UTILITY FUNCTIONS
# ===================================================================

# Function to clean missing value codes and standardize to NA
clean_values <- function(x) {
  # Convert common missing value codes to NA
  x[x %in% c(8, 9, 98, 99, -1, 999, -999, 888, 8888)] <- NA_real_
  return(x)
}

# Function to standardize binary variables to 0/1
standardize_binary <- function(x, yes_codes = c(1), no_codes = c(2)) {
  x_clean <- clean_values(x)
  result <- case_when(
    x_clean %in% yes_codes ~ 1,
    x_clean %in% no_codes ~ 0,
    TRUE ~ NA_real_
  )
  return(result)
}

# ===================================================================
# CORRECTED HARMONIZATION FUNCTIONS
# ===================================================================

# Function to harmonize gender (corrected to use actual variables)
harmonize_gender <- function(data, year) {
  if (year == 2002) {
    # QN114 is the correct gender variable for 2002
    if ("QN114" %in% names(data)) {
      gender <- standardize_binary(data$QN114, yes_codes = c(1), no_codes = c(2))
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # qnd18 is the correct gender variable for 2007
    if ("qnd18" %in% names(data)) {
      gender <- standardize_binary(data$qnd18, yes_codes = c(1), no_codes = c(2))
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  } else {
    # Search for other gender variables
    gender_vars <- names(data)[grepl("^gender|sex|male|female|qnd18|QN114", names(data), ignore.case = TRUE)]
    if (length(gender_vars) > 0) {
      gender <- standardize_binary(data[[gender_vars[1]]], yes_codes = c(1), no_codes = c(2))
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  }
  return(gender)
}

# Function to harmonize age (CORRECTED - using actual age variables)
harmonize_age <- function(data, year) {
  if (year == 2002) {
    # Use AGE or QN105 - both contain actual age values
    if ("AGE" %in% names(data)) {
      age <- clean_values(data$AGE)
    } else if ("QN105" %in% names(data)) {
      age <- clean_values(data$QN105)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # QN75 contains actual age values
    if ("QN75" %in% names(data)) {
      age <- clean_values(data$QN75)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    # qn63 contains actual age values
    if ("qn63" %in% names(data)) {
      age <- clean_values(data$qn63)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # qn50 contains actual age values
    if ("qn50" %in% names(data)) {
      age <- clean_values(data$qn50)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else {
    # Search for age variables
    age_vars <- names(data)[grepl("^age$|^AGE$|qn\\d+$|QN\\d+$", names(data), ignore.case = TRUE)]
    if (length(age_vars) > 0) {
      age <- clean_values(data[[age_vars[1]]])
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  }
  return(age)
}

# Function to harmonize place_birth (CORRECTED with proper binary coding)
harmonize_place_birth <- function(data, year) {
  if (year == 2002) {
    if ("QN3" %in% names(data)) {
      place_birth <- clean_values(data$QN3)
      # QN3: 1=US, 2=Puerto Rico, 3=Another country
      # Standardize: 1=US/PR born, 2=Foreign born
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US/Puerto Rico = US born
        place_birth == 3 ~ 2,          # Another country = Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN3" %in% names(data)) {
      place_birth <- clean_values(data$QN3)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US/Puerto Rico = US born
        place_birth == 3 ~ 2,          # Another country = Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn3" %in% names(data)) {
      place_birth <- clean_values(data$qn3)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US/Puerto Rico = US born
        place_birth == 3 ~ 2,          # Another country = Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn3" %in% names(data)) {
      place_birth <- clean_values(data$qn3)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US/Puerto Rico = US born
        place_birth == 3 ~ 2,          # Another country = Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else {
    place_birth <- rep(NA_real_, nrow(data))
  }
  
  return(place_birth)
}

# Function to derive parent nativity (CORRECTED with proper value labels)
harmonize_parent_nativity <- function(data, year) {
  if (year == 2002) {
    if ("QN106" %in% names(data)) {
      parent_nat <- clean_values(data$QN106)
      # Value labels: 1=Mother only, 2=Father only, 3=Both parents, 4=No, 5=Born in Puerto Rico
      parent_nat <- case_when(
        parent_nat == 1 ~ 2,  # Mother only -> One foreign born
        parent_nat == 2 ~ 2,  # Father only -> One foreign born
        parent_nat == 3 ~ 3,  # Both parents -> Both foreign born
        parent_nat == 4 ~ 1,  # No -> Both US born
        parent_nat == 5 ~ 1,  # Born in Puerto Rico -> US born (PR is US territory)
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN77" %in% names(data)) {
      parent_nat <- clean_values(data$QN77)
      # Value labels: 1=Yes only mother, 2=Yes only father, 3=Both, 4=No
      parent_nat <- case_when(
        parent_nat == 1 ~ 2,  # Only mother -> One foreign born
        parent_nat == 2 ~ 2,  # Only father -> One foreign born  
        parent_nat == 3 ~ 3,  # Both -> Both foreign born
        parent_nat == 4 ~ 1,  # No -> Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn64" %in% names(data)) {
      parent_nat <- clean_values(data$qn64)
      # Value labels: 1=Yes only Mother, 2=Yes only Father, 3=Both, 4=No, 5=Born in Puerto Rico
      parent_nat <- case_when(
        parent_nat == 1 ~ 2,  # Only mother -> One foreign born
        parent_nat == 2 ~ 2,  # Only father -> One foreign born
        parent_nat == 3 ~ 3,  # Both -> Both foreign born
        parent_nat == 4 ~ 1,  # No -> Both US born
        parent_nat == 5 ~ 1,  # Born in Puerto Rico -> US born (PR is US territory)
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn7" %in% names(data) && "qn8" %in% names(data)) {
      mother <- clean_values(data$qn7)
      father <- clean_values(data$qn8)
      
      # Value labels: 1=Puerto Rico, 2=U.S., 3=Another country
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else {
    parent_nat <- rep(NA_real_, nrow(data))
  }
  
  return(parent_nat)
}

# Function to derive immigrant generation (CORRECTED Portes Protocol)
derive_immigrant_generation <- function(data, year, place_birth, parent_nativity) {
  # PORTES PROTOCOL:
  # 1st Generation: Foreign-born (regardless of parent nativity) 
  # 2nd Generation: US-born with AT LEAST ONE foreign-born parent
  # 3rd+ Generation: US-born with BOTH parents US-born
  
  immigrant_generation <- case_when(
    # 1st Generation: Foreign-born respondent
    place_birth == 2 ~ 1,
    # 2nd Generation: US-born + at least one foreign-born parent
    place_birth == 1 & parent_nativity %in% c(2, 3) ~ 2,
    # 3rd+ Generation: US-born + both parents US-born
    place_birth == 1 & parent_nativity == 1 ~ 3,
    # Missing if can't determine
    TRUE ~ NA_real_
  )
  
  return(immigrant_generation)
}

# Function to harmonize citizenship status
harmonize_citizenship <- function(data, year) {
  if (year == 2002) {
    if ("CITIZEN2" %in% names(data)) {
      citizenship <- standardize_binary(data$CITIZEN2, yes_codes = c(1), no_codes = c(2))
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("F_CITIZEN" %in% names(data)) {
      citizenship <- standardize_binary(data$F_CITIZEN, yes_codes = c(1), no_codes = c(2))
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn9" %in% names(data)) {
      citizenship <- standardize_binary(data$qn9, yes_codes = c(1), no_codes = c(2))
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn9" %in% names(data)) {
      citizenship <- standardize_binary(data$qn9, yes_codes = c(1), no_codes = c(2))
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else {
    citizenship <- rep(NA_real_, nrow(data))
  }
  
  return(citizenship)
}

# Function to harmonize education (with proper recoding)
harmonize_education <- function(data, year) {
  if (year == 2002) {
    if ("EDUC" %in% names(data)) {
      educ <- clean_values(data$EDUC)
      # Recode to 4 standard categories: 1=Less than HS, 2=HS, 3=Some college, 4=College+
      educ <- case_when(
        educ %in% c(1, 2, 3) ~ 1,    # Less than high school
        educ == 4 ~ 2,               # High school
        educ %in% c(5, 6) ~ 3,       # Some college
        educ %in% c(7, 8) ~ 4,       # College+
        TRUE ~ NA_real_
      )
    } else {
      educ <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn59" %in% names(data)) {
      educ <- clean_values(data$qn59)
      educ <- case_when(
        educ %in% c(1, 2, 3) ~ 1,
        educ == 4 ~ 2,
        educ %in% c(5, 6) ~ 3,
        educ %in% c(7, 8) ~ 4,
        TRUE ~ NA_real_
      )
    } else {
      educ <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn51" %in% names(data)) {
      educ <- clean_values(data$qn51)
      educ <- case_when(
        educ %in% c(1, 2, 3) ~ 1,
        educ == 4 ~ 2,
        educ %in% c(5, 6) ~ 3,
        educ %in% c(7, 8) ~ 4,
        TRUE ~ NA_real_
      )
    } else {
      educ <- rep(NA_real_, nrow(data))
    }
  } else {
    educ <- rep(NA_real_, nrow(data))
  }
  
  return(educ)
}

# Function to harmonize income
harmonize_income <- function(data, year) {
  if (year == 2002) {
    if ("INCOME" %in% names(data)) {
      income <- clean_values(data$INCOME)
    } else if ("INC1" %in% names(data)) {
      income <- clean_values(data$INC1)
    } else {
      income <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("INCOME" %in% names(data)) {
      income <- clean_values(data$INCOME)
    } else {
      income <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("income" %in% names(data)) {
      income <- clean_values(data$income)
    } else if ("qn56" %in% names(data)) {
      income <- clean_values(data$qn56)
    } else {
      income <- rep(NA_real_, nrow(data))
    }
  } else {
    income <- rep(NA_real_, nrow(data))
  }
  
  return(income)
}

# Additional harmonization functions (keeping existing logic)
harmonize_marital_status <- function(data, year) {
  if (year == 2002) {
    if ("QN92" %in% names(data)) {
      marital <- clean_values(data$QN92)
      marital <- case_when(
        marital == 1 ~ 1,  # Married
        marital == 2 ~ 2,  # Divorced
        marital == 3 ~ 3,  # Widowed
        marital == 4 ~ 4,  # Separated
        marital == 5 ~ 5,  # Never married
        TRUE ~ NA_real_
      )
    } else {
      marital <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn47" %in% names(data)) {
      marital <- clean_values(data$qn47)
      marital <- case_when(
        marital == 1 ~ 1,
        marital == 2 ~ 2,
        marital == 3 ~ 3,
        marital == 4 ~ 4,
        marital == 5 ~ 5,
        TRUE ~ NA_real_
      )
    } else {
      marital <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn48" %in% names(data)) {
      marital <- clean_values(data$qn48)
      marital <- case_when(
        marital == 1 ~ 1,
        marital == 2 ~ 2,
        marital == 3 ~ 3,
        marital == 4 ~ 4,
        marital == 5 ~ 5,
        TRUE ~ NA_real_
      )
    } else {
      marital <- rep(NA_real_, nrow(data))
    }
  } else {
    marital <- rep(NA_real_, nrow(data))
  }
  
  return(marital)
}

harmonize_employment <- function(data, year) {
  if (year == 2002) {
    if ("QN16" %in% names(data)) {
      employ <- clean_values(data$QN16)
      employ <- case_when(
        employ %in% c(1, 2) ~ 1,  # Employed
        employ == 3 ~ 2,          # Unemployed
        employ %in% c(4, 5, 6, 7) ~ 3,  # Not in labor force
        TRUE ~ NA_real_
      )
    } else {
      employ <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn52" %in% names(data)) {
      employ <- clean_values(data$qn52)
      employ <- case_when(
        employ %in% c(1, 2) ~ 1,
        employ == 3 ~ 2,
        employ %in% c(4, 5, 6, 7) ~ 3,
        TRUE ~ NA_real_
      )
    } else {
      employ <- rep(NA_real_, nrow(data))
    }
  } else {
    employ <- rep(NA_real_, nrow(data))
  }
  
  return(employ)
}

harmonize_state <- function(data, year) {
  if (year == 2002) {
    if ("STATE" %in% names(data)) {
      state_var <- data$STATE
      if (is.character(state_var) || is.factor(state_var)) {
        state <- as.numeric(as.factor(as.character(state_var)))
      } else {
        state <- clean_values(state_var)
      }
    } else if ("FIPSTATE" %in% names(data)) {
      state_var <- data$FIPSTATE
      if (is.character(state_var) || is.factor(state_var)) {
        state <- as.numeric(as.factor(as.character(state_var)))
      } else {
        state <- clean_values(state_var)
      }
    } else {
      state <- rep(NA_real_, nrow(data))
    }
  } else {
    # Search for state variables
    state_vars <- names(data)[grepl("state|STATE|region|REGION", names(data), ignore.case = TRUE)]
    if (length(state_vars) > 0) {
      state_var <- data[[state_vars[1]]]
      if (is.character(state_var) || is.factor(state_var)) {
        state <- as.numeric(as.factor(as.character(state_var)))
      } else {
        state <- clean_values(state_var)
      }
    } else {
      state <- rep(NA_real_, nrow(data))
    }
  }
  
  return(state)
}

# Immigration attitude variables (key for research focus)
harmonize_immigration_levels <- function(data, year) {
  if (year == 2002) {
    if ("QN23" %in% names(data)) {
      levels <- clean_values(data$QN23)
      # Recode to 1=Less restrictive, 2=Moderate, 3=More restrictive
      levels <- case_when(
        levels == 1 ~ 1,  # Less restrictive
        levels == 2 ~ 2,  # Moderate/same
        levels == 3 ~ 3,  # More restrictive
        TRUE ~ NA_real_
      )
    } else {
      levels <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn24" %in% names(data)) {
      levels <- clean_values(data$qn24)
      levels <- case_when(
        levels == 1 ~ 1,
        levels == 2 ~ 2,
        levels == 3 ~ 3,
        TRUE ~ NA_real_
      )
    } else {
      levels <- rep(NA_real_, nrow(data))
    }
  } else {
    levels <- rep(NA_real_, nrow(data))
  }
  
  return(levels)
}

harmonize_legalization_support <- function(data, year) {
  if (year == 2002) {
    if ("QN26" %in% names(data)) {
      legal <- clean_values(data$QN26)
      # Recode to 0=Oppose, 0.5=Temporary, 1=Support
      legal <- case_when(
        legal == 1 ~ 1,    # Support
        legal == 2 ~ 0.5,  # Temporary/conditional
        legal == 3 ~ 0,    # Oppose
        TRUE ~ NA_real_
      )
    } else {
      legal <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN40" %in% names(data)) {
      legal <- clean_values(data$QN40)
      legal <- case_when(
        legal == 1 ~ 1,
        legal == 2 ~ 0.5,
        legal == 3 ~ 0,
        TRUE ~ NA_real_
      )
    } else {
      legal <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn13" %in% names(data)) {
      legal <- clean_values(data$qn13)
      legal <- case_when(
        legal == 1 ~ 1,
        legal == 2 ~ 0.5,
        legal == 3 ~ 0,
        TRUE ~ NA_real_
      )
    } else {
      legal <- rep(NA_real_, nrow(data))
    }
  } else {
    legal <- rep(NA_real_, nrow(data))
  }
  
  return(legal)
}

harmonize_deportation_worry <- function(data, year) {
  if (year == 2007) {
    if ("qn33" %in% names(data)) {
      worry <- clean_values(data$qn33)
      # Recode to 1=Not at all, 2=A little, 3=Somewhat, 4=A lot
      worry <- case_when(
        worry == 1 ~ 1,  # Not at all
        worry == 2 ~ 2,  # A little
        worry == 3 ~ 3,  # Somewhat
        worry == 4 ~ 4,  # A lot
        TRUE ~ NA_real_
      )
    } else {
      worry <- rep(NA_real_, nrow(data))
    }
  } else {
    worry <- rep(NA_real_, nrow(data))
  }
  
  return(worry)
}

harmonize_political_party <- function(data, year) {
  if (year == 2002) {
    if ("QN90" %in% names(data)) {
      party <- clean_values(data$QN90)
      party <- case_when(
        party == 1 ~ 1,  # Democrat
        party == 2 ~ 2,  # Republican
        party == 3 ~ 3,  # Independent
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn45" %in% names(data)) {
      party <- clean_values(data$qn45)
      party <- case_when(
        party == 1 ~ 1,
        party == 2 ~ 2,
        party == 3 ~ 3,
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn17" %in% names(data)) {
      party <- clean_values(data$qn17)
      party <- case_when(
        party == 1 ~ 1,
        party == 2 ~ 2,
        party == 3 ~ 3,
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else {
    party <- rep(NA_real_, nrow(data))
  }
  
  return(party)
}

# ===================================================================
# MAIN HARMONIZATION FUNCTION
# ===================================================================

harmonize_survey_data_CORRECTED <- function(data, year) {
  cat(sprintf("Processing %d data with %d variables\n", year, ncol(data)))
  
  # Core demographics (CORRECTED)
  gender <- harmonize_gender(data, year)
  age <- harmonize_age(data, year)
  education <- harmonize_education(data, year)
  income <- harmonize_income(data, year)
  marital_status <- harmonize_marital_status(data, year)
  employment <- harmonize_employment(data, year)
  state <- harmonize_state(data, year)
  
  # Immigration/nativity variables (CORRECTED)
  citizenship_status <- harmonize_citizenship(data, year)
  place_birth <- harmonize_place_birth(data, year)
  parent_nativity <- harmonize_parent_nativity(data, year)
  
  # Derive immigrant generation using CORRECTED Portes protocol
  immigrant_generation <- derive_immigrant_generation(data, year, place_birth, parent_nativity)
  
  # Immigration attitude variables (key for research)
  immigration_levels_opinion <- harmonize_immigration_levels(data, year)
  legalization_support <- harmonize_legalization_support(data, year)
  deportation_worry <- harmonize_deportation_worry(data, year)
  
  # Political variables
  political_party <- harmonize_political_party(data, year)
  
  # Create harmonized dataset
  harmonized_data <- data.frame(
    gender = gender,
    age = age,
    education = education,
    income = income,
    marital_status = marital_status,
    employment = employment,
    state = state,
    citizenship_status = citizenship_status,
    place_birth = place_birth,
    parent_nativity = parent_nativity,
    immigrant_generation = immigrant_generation,
    immigration_levels_opinion = immigration_levels_opinion,
    legalization_support = legalization_support,
    deportation_worry = deportation_worry,
    political_party = political_party
  )
  
  # Add descriptive labels as attributes
  attr(harmonized_data$gender, "label") <- "Gender (1=Male, 2=Female)"
  attr(harmonized_data$age, "label") <- "Age in years"
  attr(harmonized_data$education, "label") <- "Education level (1=<HS, 2=HS, 3=Some college, 4=College+)"
  attr(harmonized_data$income, "label") <- "Household income category"
  attr(harmonized_data$marital_status, "label") <- "Marital status (1=Married, 2=Divorced, 3=Widowed, 4=Separated, 5=Never married)"
  attr(harmonized_data$employment, "label") <- "Employment status (1=Employed, 2=Unemployed, 3=Not in labor force)"
  attr(harmonized_data$state, "label") <- "State code"
  attr(harmonized_data$citizenship_status, "label") <- "US citizenship status (1=Yes, 0=No)"
  attr(harmonized_data$place_birth, "label") <- "Place of birth (1=US/PR, 2=Foreign)"
  attr(harmonized_data$parent_nativity, "label") <- "Parent nativity (1=Both US, 2=One foreign, 3=Both foreign)"
  attr(harmonized_data$immigrant_generation, "label") <- "Immigrant generation (1=1st gen, 2=2nd gen, 3=3rd+ gen)"
  attr(harmonized_data$immigration_levels_opinion, "label") <- "Immigration levels opinion (1=Less restrictive, 2=Moderate, 3=More restrictive)"
  attr(harmonized_data$legalization_support, "label") <- "Support for legalization (0=Oppose, 0.5=Temporary, 1=Support)"
  attr(harmonized_data$deportation_worry, "label") <- "Worry about deportation (1=Not at all, 4=A lot)"
  attr(harmonized_data$political_party, "label") <- "Political party (1=Democrat, 2=Republican, 3=Independent)"
  
  return(harmonized_data)
}

# ===================================================================
# DATA PROCESSING
# ===================================================================

# Define file mappings
file_mappings <- list(
  "2002" = "2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004" = "2004 Political Survey Rev 1-6-05.sav", 
  "2006" = "f1171_050207 uploaded dataset.sav",
  "2007" = "publicreleaseNSL07_UPDATED_3.7.22.sav"
)

# Process each file
for (year_str in names(file_mappings)) {
  year <- as.numeric(year_str)
  filename <- file_mappings[[year_str]]
  
  cat(sprintf("\nProcessing %d data: %s \n", year, filename))
  
  # Load data
  tryCatch({
    data <- haven::read_sav(filename)
    
    # Harmonize data  
    harmonized_data <- harmonize_survey_data_CORRECTED(data, year)
    
    cat(sprintf("Original data dimensions: %d %d \n", nrow(data), ncol(data)))
    cat(sprintf("Harmonized data dimensions: %d %d \n", nrow(harmonized_data), ncol(harmonized_data)))
    
    # Print variable summary
    cat("\nVariable Summary:\n")
    for (var in names(harmonized_data)) {
      n_unique <- length(unique(harmonized_data[[var]][!is.na(harmonized_data[[var]])]))
      pct_missing <- round(sum(is.na(harmonized_data[[var]])) / nrow(harmonized_data) * 100, 1)
      cat(sprintf("%-25s: %d unique values, %s%% missing\n", var, n_unique, pct_missing))
    }
    
    # Save harmonized data
    output_file <- paste0("cleaned_data_CORRECTED/cleaned_", year, ".csv")
    write_csv(harmonized_data, output_file)
    cat(sprintf("Saved: %s \n", output_file))
    
  }, error = function(e) {
    cat(sprintf("Error processing %s: %s\n", filename, e$message))
  })
}

cat("\nCORRECTED harmonization complete!\n")