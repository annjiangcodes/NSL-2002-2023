# ==============================================================================
# FINAL Comprehensive Data Harmonization for 2002-2007 Survey Data  
# Focus: Immigration Attitudes, Rich Demographics, and Policy Preferences
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

# Function to clean and standardize values
clean_values <- function(x, missing_codes = c(8, 9, 98, 99, -1, 999, -999)) {
  # Convert common missing value codes to NA
  x <- case_when(
    x %in% missing_codes ~ NA_real_,
    TRUE ~ as.numeric(x)
  )
  return(x)
}

# Function to harmonize gender across years
harmonize_gender <- function(data, year) {
  if (year == 2002) {
    if ("QN114" %in% names(data)) {
      gender <- clean_values(data$QN114)
      gender <- case_when(
        gender == 1 ~ 1,  # Male
        gender == 2 ~ 2,  # Female
        TRUE ~ NA_real_
      )
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qnd18" %in% names(data)) {
      gender <- clean_values(data$qnd18)
      gender <- case_when(
        gender == 1 ~ 1,  # Male
        gender == 2 ~ 2,  # Female
        TRUE ~ NA_real_
      )
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  } else {
    # For 2004 and 2006, check for any gender variable
    gender_vars <- names(data)[grepl("gender|sex", names(data), ignore.case = TRUE)]
    if (length(gender_vars) > 0) {
      gender <- clean_values(data[[gender_vars[1]]])
      gender <- case_when(
        gender == 1 ~ 1,  # Male
        gender == 2 ~ 2,  # Female
        TRUE ~ NA_real_
      )
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  }
  
  return(gender)
}

# Function to harmonize age across years
harmonize_age <- function(data, year) {
  if (year == 2002) {
    if ("PAGE" %in% names(data)) {
      age <- clean_values(data$PAGE)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn63" %in% names(data)) {
      age <- clean_values(data$qn63)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn50" %in% names(data)) {
      age <- clean_values(data$qn50)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else {
    # For 2004, check for age variables
    age_vars <- names(data)[grepl("^age|age$", names(data), ignore.case = TRUE)]
    if (length(age_vars) > 0) {
      age <- clean_values(data[[age_vars[1]]])
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  }
  
  # Cap reasonable age range
  age <- case_when(
    age >= 18 & age <= 100 ~ age,
    TRUE ~ NA_real_
  )
  
  return(age)
}

# Function to harmonize education
harmonize_education <- function(data, year) {
  if (year == 2002) {
    if ("EDUC" %in% names(data)) {
      education <- clean_values(data$EDUC)
      # Recode to standard categories
      education <- case_when(
        education %in% c(1, 2) ~ 1,  # Less than HS
        education == 3 ~ 2,  # High school
        education == 4 ~ 3,  # Some college
        education >= 5 ~ 4,  # College+
        TRUE ~ NA_real_
      )
    } else {
      education <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn59" %in% names(data)) {
      education <- clean_values(data$qn59)
      # Recode education levels
      education <- case_when(
        education <= 11 ~ 1,  # Less than HS
        education == 12 ~ 2,  # High school
        education %in% c(13, 14, 15) ~ 3,  # Some college
        education >= 16 ~ 4,  # College+
        TRUE ~ NA_real_
      )
    } else {
      education <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn51" %in% names(data)) {
      education <- clean_values(data$qn51)
      # Recode education levels
      education <- case_when(
        education <= 11 ~ 1,  # Less than HS
        education == 12 ~ 2,  # High school
        education %in% c(13, 14, 15) ~ 3,  # Some college
        education >= 16 ~ 4,  # College+
        TRUE ~ NA_real_
      )
    } else {
      education <- rep(NA_real_, nrow(data))
    }
  } else {
    education <- rep(NA_real_, nrow(data))
  }
  
  return(education)
}

# Function to harmonize income across years
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

# Function to harmonize marital status
harmonize_marital_status <- function(data, year) {
  if (year == 2002) {
    if ("QN92" %in% names(data)) {
      marital <- clean_values(data$QN92)
      marital <- case_when(
        marital == 1 ~ 1,  # Married
        marital == 2 ~ 2,  # Living with partner
        marital == 3 ~ 4,  # Widowed
        marital == 4 ~ 3,  # Divorced
        marital == 5 ~ 3,  # Separated
        marital == 6 ~ 5,  # Never married
        TRUE ~ NA_real_
      )
    } else {
      marital <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn47" %in% names(data)) {
      marital <- clean_values(data$qn47)
      marital <- case_when(
        marital == 1 ~ 1,  # Married
        marital == 2 ~ 2,  # Living with partner
        marital == 3 ~ 4,  # Widowed
        marital == 4 ~ 3,  # Divorced
        marital == 5 ~ 3,  # Separated
        marital == 6 ~ 5,  # Never married
        TRUE ~ NA_real_
      )
    } else {
      marital <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn48" %in% names(data)) {
      marital <- clean_values(data$qn48)
      marital <- case_when(
        marital == 1 ~ 1,  # Married
        marital == 2 ~ 2,  # Living with partner
        marital == 3 ~ 4,  # Widowed
        marital == 4 ~ 3,  # Divorced
        marital == 5 ~ 3,  # Separated
        marital == 6 ~ 5,  # Never married
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

# Function to harmonize employment status
harmonize_employment <- function(data, year) {
  if (year == 2002) {
    if ("QN16" %in% names(data)) {
      employment <- clean_values(data$QN16)
      employment <- case_when(
        employment %in% c(1, 2) ~ 1,  # Employed (full/part time)
        employment == 3 ~ 2,  # Unemployed
        employment %in% c(4, 5, 6, 7, 8) ~ 3,  # Not in labor force
        TRUE ~ NA_real_
      )
    } else {
      employment <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn52" %in% names(data)) {
      employment <- clean_values(data$qn52)
      employment <- case_when(
        employment %in% c(1, 2) ~ 1,  # Employed (full/part time)
        employment == 3 ~ 2,  # Not employed
        TRUE ~ NA_real_
      )
    } else {
      employment <- rep(NA_real_, nrow(data))
    }
  } else {
    employment <- rep(NA_real_, nrow(data))
  }
  
  return(employment)
}

# Function to harmonize state/geography
harmonize_state <- function(data, year) {
  if (year == 2002) {
    if ("STATE" %in% names(data)) {
      # STATE is character, convert to factor/numeric for consistency
      state_var <- as.character(data$STATE)
      # Convert to numeric codes (could create state mapping later)
      state_codes <- as.numeric(as.factor(state_var))
      return(state_codes)
    } else if ("FIPSTATE" %in% names(data)) {
      state_codes <- clean_values(data$FIPSTATE)
      return(state_codes)
    } else {
      return(rep(NA_real_, nrow(data)))
    }
  } else {
    # For other years, look for state variables
    state_vars <- names(data)[grepl("state|fips", names(data), ignore.case = TRUE)]
    if (length(state_vars) > 0) {
      # Check if variable is character or numeric
      state_var <- data[[state_vars[1]]]
      if (is.character(state_var) || is.factor(state_var)) {
        # Convert character/factor to numeric codes
        state_codes <- as.numeric(as.factor(as.character(state_var)))
        return(state_codes)
      } else {
        # If numeric, use clean_values
        state_codes <- clean_values(state_var)
        return(state_codes)
      }
    } else {
      return(rep(NA_real_, nrow(data)))
    }
  }
}

# Function to harmonize citizenship status (from previous working version)
harmonize_citizenship <- function(data, year) {
  if (year == 2002) {
    if ("CITIZEN2" %in% names(data)) {
      citizenship <- clean_values(data$CITIZEN2)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # Citizen -> 1
        citizenship == 0 ~ 2,  # Non-citizen -> 2
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN17" %in% names(data)) {
      citizenship <- clean_values(data$QN17)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship %in% c(2, 3, 4) ~ 2,  # Non-citizen variants
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2006, 2007)) {
    if ("qn5" %in% names(data)) {
      citizenship <- clean_values(data$qn5)
    } else if ("qn9" %in% names(data)) {
      citizenship <- clean_values(data$qn9)
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
    
    citizenship <- case_when(
      citizenship == 1 ~ 1,  # Yes, citizen
      citizenship == 2 ~ 2,  # No, not citizen
      TRUE ~ NA_real_
    )
  } else {
    citizenship <- rep(NA_real_, nrow(data))
  }
  
  return(citizenship)
}

# Function to harmonize place of birth (from previous working version)
harmonize_place_birth <- function(data, year) {
  if (year == 2002) {
    if ("FORBORN2" %in% names(data)) {
      place_birth <- clean_values(data$FORBORN2)
      place_birth <- case_when(
        place_birth == 0 ~ 1,  # US born -> 1
        place_birth == 1 ~ 2,  # Foreign born -> 2
        TRUE ~ NA_real_
      )
    } else if ("QN3" %in% names(data)) {
      place_birth <- clean_values(data$QN3)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
        place_birth == 3 ~ 2,  # Another country -> Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN3" %in% names(data)) {
      place_birth <- clean_values(data$QN3)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
        place_birth == 3 ~ 2,  # Another country -> Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- harmonize_citizenship(data, year)
    }
  } else if (year %in% c(2006, 2007)) {
    birth_var <- NULL
    if ("qns8" %in% names(data)) {
      birth_var <- "qns8"
    } else if ("qn5" %in% names(data) && year == 2007) {
      birth_var <- "qn5"
    }
    
    if (!is.null(birth_var)) {
      place_birth <- clean_values(data[[birth_var]])
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
        place_birth == 3 ~ 2,  # Another country -> Foreign born
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

# Function to derive parent nativity (from previous working version)
harmonize_parent_nativity <- function(data, year) {
  if (year == 2002) {
    if ("QN106" %in% names(data)) {
      parent_nat <- clean_values(data$QN106)
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN77" %in% names(data)) {
      parent_nat <- clean_values(data$QN77)
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born  
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn64" %in% names(data)) {
      parent_nat <- clean_values(data$qn64)
      parent_nat <- case_when(
        parent_nat == 1 ~ 2,  # At least one foreign born
        parent_nat == 2 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn7" %in% names(data) && "qn8" %in% names(data)) {
      mother <- clean_values(data$qn7)
      father <- clean_values(data$qn8)
      
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

# Function to derive immigrant generation (from previous working version)
derive_immigrant_generation <- function(data, year) {
  place_birth <- harmonize_place_birth(data, year)
  parent_nativity <- harmonize_parent_nativity(data, year)
  
  if (year == 2002 && "GEN1TO4" %in% names(data)) {
    generation <- clean_values(data$GEN1TO4)
    generation <- case_when(
      generation == 1 ~ 1,  # First generation
      generation == 2 ~ 2,  # Second generation  
      generation %in% c(3, 4) ~ 3,  # Third+ generation
      TRUE ~ NA_real_
    )
  } else {
    generation <- case_when(
      place_birth == 2 ~ 1,  # Foreign born = first generation
      place_birth == 1 & parent_nativity %in% c(2, 3) ~ 2,  # US born, foreign parents = second generation
      place_birth == 1 & parent_nativity == 1 ~ 3,  # US born, US parents = third+ generation
      place_birth == 1 ~ 2,  # US born, unknown parents = assume second generation
      TRUE ~ NA_real_
    )
  }
  
  return(generation)
}

# IMMIGRATION POLICY ATTITUDES - The core focus!

# Function to harmonize immigration levels opinion
harmonize_immigration_levels <- function(data, year) {
  if (year == 2002) {
    if ("QN23" %in% names(data)) {
      levels <- clean_values(data$QN23)
      # 1=Too many, 2=About right, 3=Too few
      levels <- case_when(
        levels == 1 ~ 3,  # Too many -> More restrictive
        levels == 2 ~ 2,  # About right -> Moderate
        levels == 3 ~ 1,  # Too few -> Less restrictive
        TRUE ~ NA_real_
      )
    } else {
      levels <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn24" %in% names(data)) {
      levels <- clean_values(data$qn24)
      levels <- case_when(
        levels == 1 ~ 3,  # Too many -> More restrictive
        levels == 2 ~ 2,  # About right -> Moderate
        levels == 3 ~ 1,  # Too few -> Less restrictive
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

# Function to harmonize legalization attitudes
harmonize_legalization_support <- function(data, year) {
  if (year == 2002) {
    if ("QN26" %in% names(data)) {
      legalization <- clean_values(data$QN26)
      legalization <- case_when(
        legalization == 1 ~ 1,  # Favor
        legalization == 2 ~ 0,  # Oppose
        TRUE ~ NA_real_
      )
    } else {
      legalization <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN40" %in% names(data)) {
      legalization <- clean_values(data$QN40)
      legalization <- case_when(
        legalization == 1 ~ 1,  # Favor
        legalization == 2 ~ 0,  # Oppose
        TRUE ~ NA_real_
      )
    } else {
      legalization <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn13" %in% names(data)) {
      legalization <- clean_values(data$qn13)
      # May need adjustment based on response options
      legalization <- case_when(
        legalization == 1 ~ 1,  # Support path to citizenship
        legalization == 2 ~ 0.5,  # Temporary legal status
        legalization == 3 ~ 0,  # No legal status
        TRUE ~ NA_real_
      )
    } else {
      legalization <- rep(NA_real_, nrow(data))
    }
  } else {
    legalization <- rep(NA_real_, nrow(data))
  }
  
  return(legalization)
}

# Function to harmonize deportation concerns
harmonize_deportation_worry <- function(data, year) {
  if (year == 2007) {
    if ("qn33" %in% names(data)) {
      worry <- clean_values(data$qn33)
      worry <- case_when(
        worry == 1 ~ 4,  # A lot
        worry == 2 ~ 3,  # Some
        worry == 3 ~ 2,  # Not much
        worry == 4 ~ 1,  # Not at all
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

# Function to harmonize political party (improved)
harmonize_political_party <- function(data, year) {
  if (year == 2002) {
    if ("QN90" %in% names(data)) {
      party <- clean_values(data$QN90)
      party <- case_when(
        party == 2 ~ 1,  # Democrat
        party == 1 ~ 2,  # Republican  
        party == 3 ~ 3,  # Independent
        party == 4 ~ 4,  # Other
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn45" %in% names(data)) {
      party <- clean_values(data$qn45)
      party <- case_when(
        party == 2 ~ 1,  # Democrat
        party == 1 ~ 2,  # Republican
        party == 3 ~ 3,  # Independent
        party == 4 ~ 4,  # Other
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    if ("qn17" %in% names(data)) {
      party <- clean_values(data$qn17)
      party <- case_when(
        party == 2 ~ 1,  # Democrat
        party == 1 ~ 2,  # Republican
        party == 3 ~ 3,  # Independent
        party == 4 ~ 4,  # Other
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

# Main harmonization function
harmonize_survey_data_FINAL <- function(file_path, year) {
  cat("Processing", year, "data:", file_path, "\n")
  
  # Read the data
  data <- read_survey_data(file_path)
  cat("Original data dimensions:", dim(data), "\n")
  
  # Create comprehensive harmonized dataset
  harmonized_data <- data.frame(
    survey_year = year,
    
    # Core demographics
    gender = harmonize_gender(data, year),
    age = harmonize_age(data, year),
    education = harmonize_education(data, year),
    income = harmonize_income(data, year),
    marital_status = harmonize_marital_status(data, year),
    employment = harmonize_employment(data, year),
    state = harmonize_state(data, year),
    
    # Nativity and immigration status
    citizenship_status = harmonize_citizenship(data, year),
    place_birth = harmonize_place_birth(data, year),
    parent_nativity = harmonize_parent_nativity(data, year),
    immigrant_generation = derive_immigrant_generation(data, year),
    
    # Immigration Policy Attitudes (KEY FOCUS!)
    immigration_levels_opinion = harmonize_immigration_levels(data, year),
    legalization_support = harmonize_legalization_support(data, year),
    deportation_worry = harmonize_deportation_worry(data, year),
    
    # Political variables
    political_party = harmonize_political_party(data, year)
  )
  
  # Add comprehensive variable labels
  attr(harmonized_data$gender, "label") <- "Gender (1=Male, 2=Female)"
  attr(harmonized_data$age, "label") <- "Age in years"
  attr(harmonized_data$education, "label") <- "Education (1=<HS, 2=HS, 3=Some college, 4=College+)"
  attr(harmonized_data$income, "label") <- "Household income (categorical)"
  attr(harmonized_data$marital_status, "label") <- "Marital status (1=Married, 2=Partner, 3=Div/Sep, 4=Widowed, 5=Never married)"
  attr(harmonized_data$employment, "label") <- "Employment status (1=Employed, 2=Unemployed, 3=Not in labor force)"
  attr(harmonized_data$state, "label") <- "State/geographic code"
  attr(harmonized_data$citizenship_status, "label") <- "Citizenship status (1=US Citizen, 2=Non-citizen)"
  attr(harmonized_data$place_birth, "label") <- "Place of birth (1=US born, 2=Foreign born)"
  attr(harmonized_data$parent_nativity, "label") <- "Parent nativity (1=Both US, 2=One foreign, 3=Both foreign)"
  attr(harmonized_data$immigrant_generation, "label") <- "Immigrant generation (1=First, 2=Second, 3=Third+)"
  attr(harmonized_data$immigration_levels_opinion, "label") <- "Immigration levels opinion (1=Less restrictive, 2=Moderate, 3=More restrictive)"
  attr(harmonized_data$legalization_support, "label") <- "Support for legalization (0=Oppose, 1=Support)"
  attr(harmonized_data$deportation_worry, "label") <- "Worry about deportation (1=Not at all, 4=A lot)"
  attr(harmonized_data$political_party, "label") <- "Political party (1=Democrat, 2=Republican, 3=Independent, 4=Other)"
  
  cat("Harmonized data dimensions:", dim(harmonized_data), "\n")
  
  # Print summary statistics
  cat("\nVariable Summary:\n")
  for (var in names(harmonized_data)[2:ncol(harmonized_data)]) {
    values <- harmonized_data[[var]]
    n_unique <- length(unique(values[!is.na(values)]))
    pct_missing <- round(sum(is.na(values))/length(values) * 100, 1)
    cat(sprintf("%-25s: %d unique values, %s%% missing\n", var, n_unique, pct_missing))
  }
  
  return(harmonized_data)
}

# Process files function for 2002-2007
process_survey_files_FINAL <- function() {
  
  # Create output directory
  if (!dir.exists("cleaned_data_FINAL")) {
    dir.create("cleaned_data_FINAL")
  }
  
  # Define file mappings for 2002-2007
  file_mappings <- list(
    "2002" = "2002 RAE008b FINAL DATA FOR RELEASE.sav",
    "2004" = "2004 Political Survey Rev 1-6-05.sav",
    "2006" = "f1171_050207 uploaded dataset.sav",
    "2007" = "publicreleaseNSL07_UPDATED_3.7.22.sav"
  )
  
  harmonized_files <- list()
  
  for (year in names(file_mappings)) {
    file_path <- file_mappings[[year]]
    
    if (file.exists(file_path)) {
      # Harmonize the data
      harmonized_data <- harmonize_survey_data_FINAL(file_path, as.numeric(year))
      
      # Save cleaned data
      output_file <- file.path("cleaned_data_FINAL", paste0("cleaned_", year, ".csv"))
      write_csv(harmonized_data, output_file)
      cat("Saved:", output_file, "\n\n")
      
      harmonized_files[[year]] <- harmonized_data
    } else {
      cat("File not found:", file_path, "\n")
    }
  }
  
  return(harmonized_files)
}

# Run the harmonization
if (!interactive()) {
  cat("=== Running FINAL Comprehensive Data Harmonization for 2002-2007 ===\n\n")
  harmonized_files <- process_survey_files_FINAL()
  cat("FINAL harmonization complete!\n")
}