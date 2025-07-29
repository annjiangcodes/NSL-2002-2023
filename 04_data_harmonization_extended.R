# ==============================================================================
# Extended Data Harmonization for 2002-2007 Survey Data  
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
  
  # Look for gender/sex variables
  gender_vars <- names(data)[grepl("gender|sex|male|female", names(data), ignore.case = TRUE)]
  
  # Year-specific mappings
  if (year == 2002) {
    if ("PSEX" %in% names(data)) {
      gender <- clean_values(data$PSEX)
      gender <- case_when(
        gender == 1 ~ 1,  # Male
        gender == 2 ~ 2,  # Female
        TRUE ~ NA_real_
      )
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2004, 2006, 2007)) {
    # Look for standard gender variables
    if ("GENDER" %in% names(data)) {
      gender <- clean_values(data$GENDER)
    } else if ("SEX" %in% names(data)) {
      gender <- clean_values(data$SEX)
    } else if (length(gender_vars) > 0) {
      gender <- clean_values(data[[gender_vars[1]]])
    } else {
      gender <- rep(NA_real_, nrow(data))
    }
    
    # Standardize coding
    gender <- case_when(
      gender == 1 ~ 1,  # Male
      gender == 2 ~ 2,  # Female
      TRUE ~ NA_real_
    )
  } else {
    gender <- rep(NA_real_, nrow(data))
  }
  
  return(gender)
}

# Function to harmonize age across years
harmonize_age <- function(data, year) {
  
  # Look for age variables
  age_vars <- names(data)[grepl("^age|age$|birth|born", names(data), ignore.case = TRUE)]
  
  if (year == 2002) {
    if ("PAGE" %in% names(data)) {
      age <- clean_values(data$PAGE)
    } else if ("AGE" %in% names(data)) {
      age <- clean_values(data$AGE)
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2004, 2006, 2007)) {
    if ("AGE" %in% names(data)) {
      age <- clean_values(data$AGE)
    } else if (length(age_vars) > 0) {
      age <- clean_values(data[[age_vars[1]]])
    } else {
      age <- rep(NA_real_, nrow(data))
    }
  } else {
    age <- rep(NA_real_, nrow(data))
  }
  
  # Cap reasonable age range
  age <- case_when(
    age >= 18 & age <= 100 ~ age,
    TRUE ~ NA_real_
  )
  
  return(age)
}

# Function to harmonize citizenship status across years
harmonize_citizenship <- function(data, year) {
  if (year == 2002) {
    # Use CITIZEN2 variable: 0=non-citizen, 1=citizen
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
    # Use QN17 variable
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
    # Use qn5 or qn9 (citizen yes/no)
    if ("qn5" %in% names(data)) {
      citizenship <- clean_values(data$qn5)
    } else if ("qn9" %in% names(data)) {
      citizenship <- clean_values(data$qn9)
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
    
    # Standardize to 1=citizen, 2=non-citizen
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

# Function to harmonize place of birth/nativity
harmonize_place_birth <- function(data, year) {
  if (year == 2002) {
    # Use FORBORN2: 0=US born, 1=foreign born
    if ("FORBORN2" %in% names(data)) {
      place_birth <- clean_values(data$FORBORN2)
      place_birth <- case_when(
        place_birth == 0 ~ 1,  # US born -> 1
        place_birth == 1 ~ 2,  # Foreign born -> 2
        TRUE ~ NA_real_
      )
    } else if ("QN3" %in% names(data)) {
      # Alternative: QN3 (birth location)
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
    # Use QN3 for birth location
    if ("QN3" %in% names(data)) {
      place_birth <- clean_values(data$QN3)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
        place_birth == 3 ~ 2,  # Another country -> Foreign born
        TRUE ~ NA_real_
      )
    } else {
      # Derive from citizenship as proxy
      place_birth <- harmonize_citizenship(data, year)
    }
  } else if (year %in% c(2006, 2007)) {
    # Use qns8 or qn5 for birth location
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

# Function to derive parent nativity
harmonize_parent_nativity <- function(data, year) {
  
  if (year == 2002) {
    # Use QN106 (parents born outside US)
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
    # Use QN77 (parents born outside US)
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
    # Use qn64 (parents born outside US)
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
    # Use qn7 (mother) and qn8 (father) birth location
    if ("qn7" %in% names(data) && "qn8" %in% names(data)) {
      mother <- clean_values(data$qn7)
      father <- clean_values(data$qn8)
      
      # Count foreign-born parents
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

# Function to derive immigrant generation
derive_immigrant_generation <- function(data, year) {
  
  # Get place of birth and parent nativity
  place_birth <- harmonize_place_birth(data, year)
  parent_nativity <- harmonize_parent_nativity(data, year)
  
  # Use existing generation variables if available
  if (year == 2002 && "GEN1TO4" %in% names(data)) {
    generation <- clean_values(data$GEN1TO4)
    generation <- case_when(
      generation == 1 ~ 1,  # First generation
      generation == 2 ~ 2,  # Second generation  
      generation %in% c(3, 4) ~ 3,  # Third+ generation
      TRUE ~ NA_real_
    )
  } else {
    # Derive from nativity
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

# Function to harmonize ethnicity/race
harmonize_ethnicity <- function(data, year) {
  
  # Look for Hispanic origin variables
  hispanic_vars <- names(data)[grepl("hispanic|latino|origin|ethnic", names(data), ignore.case = TRUE)]
  
  if (length(hispanic_vars) > 0) {
    # Use first available Hispanic variable
    ethnicity <- clean_values(data[[hispanic_vars[1]]])
    
    # Try to standardize (this will need manual adjustment per dataset)
    if (year == 2002) {
      # Specific mappings for 2002 if known
      ethnicity <- case_when(
        ethnicity == 1 ~ 1,  # Mexican
        ethnicity == 2 ~ 2,  # Puerto Rican
        ethnicity == 3 ~ 3,  # Cuban
        ethnicity >= 4 ~ 4,  # Other Hispanic
        TRUE ~ NA_real_
      )
    } else {
      # Generic mapping for other years
      ethnicity <- case_when(
        ethnicity %in% c(1, 2, 3, 4, 5) ~ ethnicity,
        TRUE ~ NA_real_
      )
    }
  } else {
    ethnicity <- rep(NA_real_, nrow(data))
  }
  
  return(ethnicity)
}

# Function to harmonize language
harmonize_language <- function(data, year) {
  
  # Look for language variables
  lang_vars <- names(data)[grepl("language|speak|spanish|english", names(data), ignore.case = TRUE)]
  
  if (length(lang_vars) > 0) {
    language <- clean_values(data[[lang_vars[1]]])
    
    # Standardize to common categories
    language <- case_when(
      language == 1 ~ 1,  # English only
      language == 2 ~ 2,  # Spanish only  
      language == 3 ~ 3,  # Both/Bilingual
      language >= 4 ~ 4,  # Other
      TRUE ~ NA_real_
    )
  } else {
    language <- rep(NA_real_, nrow(data))
  }
  
  return(language)
}

# Function to harmonize political party
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
  } else {
    # Look for party variables in other years
    party_vars <- names(data)[grepl("party|democrat|republican|independent", names(data), ignore.case = TRUE)]
    if (length(party_vars) > 0) {
      party <- clean_values(data[[party_vars[1]]])
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  }
  
  return(party)
}

# Function to harmonize education
harmonize_education <- function(data, year) {
  
  # Look for education variables
  ed_vars <- names(data)[grepl("education|school|grade|college|degree", names(data), ignore.case = TRUE)]
  
  if (length(ed_vars) > 0) {
    education <- clean_values(data[[ed_vars[1]]])
    
    # Standardize to common categories (will need manual adjustment)
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
  
  return(education)
}

# Main harmonization function
harmonize_survey_data_extended <- function(file_path, year) {
  cat("Processing", year, "data:", file_path, "\n")
  
  # Read the data
  data <- read_survey_data(file_path)
  cat("Original data dimensions:", dim(data), "\n")
  
  # Create harmonized dataset with expanded variables
  harmonized_data <- data.frame(
    survey_year = year,
    
    # Core demographics
    gender = harmonize_gender(data, year),
    age = harmonize_age(data, year),
    
    # Nativity and immigration
    citizenship_status = harmonize_citizenship(data, year),
    place_birth = harmonize_place_birth(data, year),
    parent_nativity = harmonize_parent_nativity(data, year),
    immigrant_generation = derive_immigrant_generation(data, year),
    
    # Ethnicity and language
    hispanic_origin = harmonize_ethnicity(data, year),
    language_home = harmonize_language(data, year),
    
    # Political variables  
    political_party = harmonize_political_party(data, year),
    
    # Socioeconomic
    education = harmonize_education(data, year),
    
    # Placeholders for additional variables that need manual mapping
    income = rep(NA_real_, nrow(data)),
    employment = rep(NA_real_, nrow(data)),
    marital_status = rep(NA_real_, nrow(data)),
    religion = rep(NA_real_, nrow(data)),
    geography = rep(NA_real_, nrow(data)),
    
    # Attitude variables (placeholders)
    immigration_attitude = rep(NA_real_, nrow(data)),
    political_trust = rep(NA_real_, nrow(data)),
    vote_intention = rep(NA_real_, nrow(data))
  )
  
  # Add variable labels
  attr(harmonized_data$gender, "label") <- "Gender (1=Male, 2=Female)"
  attr(harmonized_data$age, "label") <- "Age in years"
  attr(harmonized_data$citizenship_status, "label") <- "Citizenship status (1=US Citizen, 2=Non-citizen)"
  attr(harmonized_data$place_birth, "label") <- "Place of birth (1=US born, 2=Foreign born)"
  attr(harmonized_data$parent_nativity, "label") <- "Parent nativity (1=Both US, 2=One foreign, 3=Both foreign)"
  attr(harmonized_data$immigrant_generation, "label") <- "Immigrant generation (1=First, 2=Second, 3=Third+)"
  attr(harmonized_data$hispanic_origin, "label") <- "Hispanic origin/ethnicity"
  attr(harmonized_data$language_home, "label") <- "Language spoken at home"
  attr(harmonized_data$political_party, "label") <- "Political party identification"
  attr(harmonized_data$education, "label") <- "Educational attainment"
  
  cat("Harmonized data dimensions:", dim(harmonized_data), "\n")
  
  # Print summary statistics
  cat("\nVariable Summary:\n")
  for (var in names(harmonized_data)[2:ncol(harmonized_data)]) {
    values <- harmonized_data[[var]]
    n_unique <- length(unique(values[!is.na(values)]))
    pct_missing <- round(sum(is.na(values))/length(values) * 100, 1)
    cat(sprintf("%-20s: %d unique values, %s%% missing\n", var, n_unique, pct_missing))
  }
  
  return(harmonized_data)
}

# Process files function for 2002-2007
process_survey_files_extended <- function() {
  
  # Create output directory
  if (!dir.exists("cleaned_data")) {
    dir.create("cleaned_data")
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
      harmonized_data <- harmonize_survey_data_extended(file_path, as.numeric(year))
      
      # Save cleaned data
      output_file <- file.path("cleaned_data", paste0("cleaned_", year, ".csv"))
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
  cat("=== Running Extended Data Harmonization for 2002-2007 ===\n\n")
  harmonized_files <- process_survey_files_extended()
  cat("Extended harmonization complete!\n")
}