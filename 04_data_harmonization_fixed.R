# ==============================================================================
# Step 4: Fixed Data Harmonization and Cleaning Script
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
clean_values <- function(x) {
  # Convert common missing value codes to NA
  x <- case_when(
    x %in% c(8, 9, 98, 99, -1, 999, -999) ~ NA_real_,
    TRUE ~ as.numeric(x)
  )
  return(x)
}

# Function to harmonize citizenship status
harmonize_citizenship <- function(data, year) {
  if (year == 2002) {
    # Use CITIZEN2 variable: 0=non-citizen, 1=citizen, 98/99=refuse/don't know
    if ("CITIZEN2" %in% names(data)) {
      citizenship <- clean_values(data$CITIZEN2)
      citizenship <- case_when(
        citizenship == 0 ~ 2,  # Non-citizen -> 2
        citizenship == 1 ~ 1,  # Citizen -> 1
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # Use QN17 variable with different coding
    if ("QN17" %in% names(data)) {
      citizenship <- clean_values(data$QN17)
      # Based on the values: 1=citizen, 2-4=non-citizen variants
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship %in% c(2, 3, 4) ~ 2,  # Non-citizen/other status
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
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
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # 2004 doesn't seem to have explicit nativity variable
    # We can derive it from citizenship status as approximation
    if ("QN17" %in% names(data)) {
      qn17 <- clean_values(data$QN17)
      place_birth <- case_when(
        qn17 == 1 ~ 1,  # US citizen -> likely US born (imperfect)
        qn17 %in% c(2, 3, 4) ~ 2,  # Non-citizen -> likely foreign born
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

# Function to derive immigrant generation
derive_immigrant_generation <- function(data, year) {
  if (year == 2002) {
    # Use existing GEN1TO4 variable but clean it
    if ("GEN1TO4" %in% names(data)) {
      generation <- clean_values(data$GEN1TO4)
      # Recode to standard format: 1=first, 2=second, 3=third+
      generation <- case_when(
        generation == 1 ~ 1,  # First generation
        generation == 2 ~ 2,  # Second generation  
        generation %in% c(3, 4) ~ 3,  # Third+ generation
        TRUE ~ NA_real_
      )
    } else {
      # Derive from nativity if GEN1TO4 not available
      place_birth <- harmonize_place_birth(data, year)
      generation <- case_when(
        place_birth == 2 ~ 1,  # Foreign born = first generation
        place_birth == 1 ~ 2,  # US born = assume second generation (conservative)
        TRUE ~ NA_real_
      )
    }
  } else if (year == 2004) {
    # Derive from citizenship/nativity proxy
    place_birth <- harmonize_place_birth(data, year)
    generation <- case_when(
      place_birth == 2 ~ 1,  # Foreign born = first generation
      place_birth == 1 ~ 2,  # US born = assume second generation
      TRUE ~ NA_real_
    )
  } else {
    generation <- rep(NA_real_, nrow(data))
  }
  
  return(generation)
}

# Function to harmonize political party affiliation
harmonize_political_party <- function(data, year) {
  if (year == 2002) {
    # Use QN90 for party identification
    if ("QN90" %in% names(data)) {
      party <- clean_values(data$QN90)
      # Standard coding: 1=Republican, 2=Democrat, 3=Independent, 4=Other
      party <- case_when(
        party == 1 ~ 2,  # Republican
        party == 2 ~ 1,  # Democrat  
        party == 3 ~ 3,  # Independent
        party == 4 ~ 4,  # Other
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # Look for party variables in 2004
    party_vars <- names(data)[grepl("party|QN1[0-9]", names(data), ignore.case = TRUE)]
    if (length(party_vars) > 0) {
      # Use first available party variable
      party <- clean_values(data[[party_vars[1]]])
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else {
    party <- rep(NA_real_, nrow(data))
  }
  
  return(party)
}

# Function to harmonize vote intention
harmonize_vote_intention <- function(data, year) {
  if (year == 2002) {
    # Look for voting variables
    vote_vars <- names(data)[grepl("vote|elect", names(data), ignore.case = TRUE)]
    if (length(vote_vars) > 0) {
      vote <- clean_values(data[[vote_vars[1]]])
      # Standardize to 1=Yes, 0=No
      vote <- case_when(
        vote == 1 ~ 1,
        vote == 0 ~ 0,
        TRUE ~ NA_real_
      )
    } else {
      vote <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # Look for voting variables in 2004
    vote_vars <- names(data)[grepl("vote|elect", names(data), ignore.case = TRUE)]
    if (length(vote_vars) > 0) {
      vote <- clean_values(data[[vote_vars[1]]])
    } else {
      vote <- rep(NA_real_, nrow(data))
    }
  } else {
    vote <- rep(NA_real_, nrow(data))
  }
  
  return(vote)
}

# Function to harmonize immigration attitudes
harmonize_immigration_attitude <- function(data, year) {
  if (year == 2002) {
    # Use QN26 (proposal for legal status)
    if ("QN26" %in% names(data)) {
      attitude <- clean_values(data$QN26)
      # Standardize to 1=Favor, 0=Oppose
      attitude <- case_when(
        attitude == 1 ~ 1,  # Favor
        attitude == 2 ~ 0,  # Oppose
        TRUE ~ NA_real_
      )
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # Use QN40 (similar immigration proposal)
    if ("QN40" %in% names(data)) {
      attitude <- clean_values(data$QN40)
      # Standardize to 1=Favor, 0=Oppose
      attitude <- case_when(
        attitude == 1 ~ 1,  # Favor
        attitude == 2 ~ 0,  # Oppose
        TRUE ~ NA_real_
      )
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else {
    attitude <- rep(NA_real_, nrow(data))
  }
  
  return(attitude)
}

# Function to harmonize border security attitudes
harmonize_border_security <- function(data, year) {
  if (year == 2002) {
    # Use QN23 (too many immigrants)
    if ("QN23" %in% names(data)) {
      border <- clean_values(data$QN23)
      # Higher values = more restrictive
      border <- case_when(
        border %in% c(1, 2, 3) ~ border,
        TRUE ~ NA_real_
      )
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    # Look for border/immigration restriction variables
    border_vars <- names(data)[grepl("QN3[0-9]|border|restrict", names(data), ignore.case = TRUE)]
    if (length(border_vars) > 0) {
      border <- clean_values(data[[border_vars[1]]])
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else {
    border <- rep(NA_real_, nrow(data))
  }
  
  return(border)
}

# Main harmonization function
harmonize_survey_data <- function(file_path, year) {
  cat("Processing", year, "data:", file_path, "\n")
  
  # Read the data
  data <- read_survey_data(file_path)
  cat("Original data dimensions:", dim(data), "\n")
  
  # Create harmonized dataset
  harmonized_data <- data.frame(
    survey_year = year,
    citizenship_status = harmonize_citizenship(data, year),
    place_birth = harmonize_place_birth(data, year),
    immigrant_generation = derive_immigrant_generation(data, year),
    immigration_attitude = harmonize_immigration_attitude(data, year),
    border_security_attitude = harmonize_border_security(data, year),
    political_party = harmonize_political_party(data, year),
    vote_intention = harmonize_vote_intention(data, year),
    approval_rating = rep(NA_real_, nrow(data))  # Placeholder
  )
  
  # Add variable labels
  attr(harmonized_data$citizenship_status, "label") <- "Citizenship status (1=US Citizen, 2=Non-citizen)"
  attr(harmonized_data$place_birth, "label") <- "Place of birth (1=US born, 2=Foreign born)"
  attr(harmonized_data$immigrant_generation, "label") <- "Immigrant generation (1=First, 2=Second, 3=Third+)"
  attr(harmonized_data$immigration_attitude, "label") <- "Immigration attitude (1=Pro-immigrant, 0=Anti-immigrant)"
  attr(harmonized_data$border_security_attitude, "label") <- "Border security attitude (higher=more restrictive)"
  attr(harmonized_data$political_party, "label") <- "Political party (1=Democrat, 2=Republican, 3=Independent, 4=Other)"
  attr(harmonized_data$vote_intention, "label") <- "Vote intention (1=Yes, 0=No)"
  
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

# Process files
process_survey_files <- function() {
  
  # Create output directory
  if (!dir.exists("cleaned_data")) {
    dir.create("cleaned_data")
  }
  
  # Define file mappings
  file_mappings <- list(
    "2002" = "2002 RAE008b FINAL DATA FOR RELEASE.sav",
    "2004" = "2004 Political Survey Rev 1-6-05.sav"
  )
  
  harmonized_files <- list()
  
  for (year in names(file_mappings)) {
    file_path <- file_mappings[[year]]
    
    if (file.exists(file_path)) {
      # Harmonize the data
      harmonized_data <- harmonize_survey_data(file_path, as.numeric(year))
      
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

# Add data validation function
validate_harmonized_data <- function(data, year) {
  cat("Validating", year, "data:\n")
  
  issues <- c()
  
  # Check citizenship_status
  cs_unique <- length(unique(data$citizenship_status[!is.na(data$citizenship_status)]))
  if (cs_unique < 2) {
    issues <- c(issues, paste("citizenship_status has only", cs_unique, "unique values"))
  }
  
  # Check place_birth
  pb_unique <- length(unique(data$place_birth[!is.na(data$place_birth)]))
  if (pb_unique < 2) {
    issues <- c(issues, paste("place_birth has only", pb_unique, "unique values"))
  }
  
  # Check for excessive missingness
  for (var in c("citizenship_status", "place_birth", "immigrant_generation")) {
    missing_pct <- sum(is.na(data[[var]]))/nrow(data) * 100
    if (missing_pct > 80) {
      issues <- c(issues, paste(var, "is", round(missing_pct, 1), "% missing"))
    }
  }
  
  if (length(issues) > 0) {
    cat("ISSUES FOUND:\n")
    for (issue in issues) {
      cat("- ", issue, "\n")
    }
  } else {
    cat("No major issues detected.\n")
  }
  
  cat("\n")
}

# Run the harmonization
if (!interactive()) {
  cat("=== Running Fixed Data Harmonization ===\n\n")
  harmonized_files <- process_survey_files()
  
  # Validate each file
  for (year in names(harmonized_files)) {
    validate_harmonized_data(harmonized_files[[year]], year)
  }
  
  cat("Fixed harmonization complete!\n")
}