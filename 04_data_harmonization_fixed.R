# ==============================================================================
# Step 4: Fixed Data Harmonization and Cleaning Script (Extended 2007-2012)
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
  } else if (year == 2006) {
    # Use qn5 and qn6b variables
    if ("qn5" %in% names(data)) {
      citizenship <- clean_values(data$qn5)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship %in% c(2, 3) ~ 2,  # Non-citizen
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # Use qn9 variable: "Are you a citizen of the United States?"
    if ("qn9" %in% names(data)) {
      citizenship <- clean_values(data$qn9)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship == 2 ~ 2,  # Non-citizen
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2008) {
    # Use qn9 or combo14 (citizenship & registration)
    if ("qn9" %in% names(data)) {
      citizenship <- clean_values(data$qn9)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship == 2 ~ 2,  # Non-citizen
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # Use qn9 variable
    if ("qn9" %in% names(data)) {
      citizenship <- clean_values(data$qn9)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship == 2 ~ 2,  # Non-citizen
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2010) {
    # Use qn9 variable
    if ("qn9" %in% names(data)) {
      citizenship <- clean_values(data$qn9)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship == 2 ~ 2,  # Non-citizen
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # Use qn84 or qn85 variables
    if ("qn84" %in% names(data)) {
      citizenship <- clean_values(data$qn84)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship == 2 ~ 2,  # Non-citizen
        TRUE ~ NA_real_
      )
    } else {
      citizenship <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2012) {
    # Use qn76, qn79, or qn80 variables
    if ("qn76" %in% names(data)) {
      citizenship <- clean_values(data$qn76)
      citizenship <- case_when(
        citizenship == 1 ~ 1,  # US Citizen
        citizenship == 2 ~ 2,  # Non-citizen
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
  } else if (year == 2006) {
    # Use qn71a for nativity information
    if ("qn71a" %in% names(data)) {
      place_birth <- clean_values(data$qn71a)
      place_birth <- case_when(
        place_birth == 1 ~ 1,  # US born
        place_birth == 2 ~ 2,  # Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # Use qn5: "Were you born on the island of Puerto Rico, in the United States, or in another country?"
    if ("qn5" %in% names(data)) {
      place_birth <- clean_values(data$qn5)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # Puerto Rico or US -> US born
        place_birth == 3 ~ 2,  # Another country -> Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2008) {
    # Use combo5a (nativity & country of birth) or qn5
    if ("combo5a" %in% names(data)) {
      place_birth <- clean_values(data$combo5a)
    } else if ("qn5" %in% names(data)) {
      place_birth <- clean_values(data$qn5)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # Puerto Rico or US
        place_birth == 3 ~ 2,  # Another country
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # Derive from citizenship if direct nativity not available
    citizenship <- harmonize_citizenship(data, year)
    place_birth <- case_when(
      citizenship == 1 ~ 1,  # Citizen -> likely US born (approximate)
      citizenship == 2 ~ 2,  # Non-citizen -> likely foreign born
      TRUE ~ NA_real_
    )
  } else if (year == 2010) {
    # Use available nativity questions
    if ("qn53" %in% names(data)) {
      place_birth <- clean_values(data$qn53)
    } else {
      # Derive from citizenship
      citizenship <- harmonize_citizenship(data, year)
      place_birth <- case_when(
        citizenship == 1 ~ 1,  # Approximate
        citizenship == 2 ~ 2,
        TRUE ~ NA_real_
      )
    }
  } else if (year == 2011) {
    # Derive from citizenship or available birth variables
    citizenship <- harmonize_citizenship(data, year)
    place_birth <- case_when(
      citizenship == 1 ~ 1,  # Approximate
      citizenship == 2 ~ 2,
      TRUE ~ NA_real_
    )
  } else if (year == 2012) {
    # Use qn78 for nativity information
    if ("qn78" %in% names(data)) {
      place_birth <- clean_values(data$qn78)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US born
        place_birth == 3 ~ 2,  # Foreign born
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

# Function to harmonize parent nativity (mother and father birth)
harmonize_parent_nativity <- function(data, year) {
  mother_birth <- rep(NA_real_, nrow(data))
  father_birth <- rep(NA_real_, nrow(data))
  
  if (year == 2007) {
    # Use qn7 and qn8 for parent nativity
    if ("qn7" %in% names(data)) {
      mother_birth <- clean_values(data$qn7)
      mother_birth <- case_when(
        mother_birth %in% c(1, 2) ~ 1,  # Puerto Rico or US
        mother_birth == 3 ~ 2,  # Another country
        TRUE ~ NA_real_
      )
    }
    if ("qn8" %in% names(data)) {
      father_birth <- clean_values(data$qn8)
      father_birth <- case_when(
        father_birth %in% c(1, 2) ~ 1,  # Puerto Rico or US
        father_birth == 3 ~ 2,  # Another country
        TRUE ~ NA_real_
      )
    }
  } else if (year == 2008) {
    # Use combo6 and combo9 or individual parent questions
    if ("combo6" %in% names(data)) {
      mother_birth <- clean_values(data$combo6)
    }
    if ("combo9" %in% names(data)) {
      father_birth <- clean_values(data$combo9)
    }
  }
  
  return(list(mother = mother_birth, father = father_birth))
}

# Function to derive immigrant generation
derive_immigrant_generation <- function(data, year) {
  place_birth <- harmonize_place_birth(data, year)
  parent_nativity <- harmonize_parent_nativity(data, year)
  
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
      generation <- case_when(
        place_birth == 2 ~ 1,  # Foreign born = first generation
        place_birth == 1 ~ 2,  # US born = assume second generation (conservative)
        TRUE ~ NA_real_
      )
    }
  } else if (year == 2004) {
    # Derive from citizenship/nativity proxy
    generation <- case_when(
      place_birth == 2 ~ 1,  # Foreign born = first generation
      place_birth == 1 ~ 2,  # US born = assume second generation
      TRUE ~ NA_real_
    )
  } else if (year == 2006) {
    # Derive from available nativity information
    generation <- case_when(
      place_birth == 2 ~ 1,  # Foreign born = first generation
      place_birth == 1 ~ 2,  # US born = assume second generation
      TRUE ~ NA_real_
    )
  } else if (year == 2007) {
    # Implement full derivation logic with parent nativity
    mother_birth <- parent_nativity$mother
    father_birth <- parent_nativity$father
    
    generation <- case_when(
      place_birth == 2 ~ 1,  # First generation: respondent foreign-born
      place_birth == 1 & (mother_birth == 2 | father_birth == 2) ~ 2,  # Second generation: US-born with ≥1 foreign-born parent
      place_birth == 1 & mother_birth == 1 & father_birth == 1 ~ 3,  # Third+ generation: US-born with both parents US-born
      TRUE ~ NA_real_
    )
  } else if (year == 2008) {
    # Use parent nativity combos if available
    mother_birth <- parent_nativity$mother
    father_birth <- parent_nativity$father
    
    generation <- case_when(
      place_birth == 2 ~ 1,  # First generation
      place_birth == 1 & (mother_birth == 2 | father_birth == 2) ~ 2,  # Second generation
      place_birth == 1 & mother_birth == 1 & father_birth == 1 ~ 3,  # Third+ generation
      place_birth == 1 ~ 2,  # Default to second generation if parent info missing
      TRUE ~ NA_real_
    )
  } else if (year %in% c(2009, 2010)) {
    # Basic derivation from nativity
    generation <- case_when(
      place_birth == 2 ~ 1,  # Foreign born = first generation
      place_birth == 1 ~ 2,  # US born = assume second generation
      TRUE ~ NA_real_
    )
  } else if (year == 2011) {
    # Use qn70 if available for generation information
    if ("qn70" %in% names(data)) {
      generation <- clean_values(data$qn70)
      generation <- case_when(
        generation == 1 ~ 1,  # First generation
        generation == 2 ~ 2,  # Second generation
        generation %in% c(3, 4) ~ 3,  # Third+ generation
        TRUE ~ NA_real_
      )
    } else {
      generation <- case_when(
        place_birth == 2 ~ 1,  # Foreign born = first generation
        place_birth == 1 ~ 2,  # US born = assume second generation
        TRUE ~ NA_real_
      )
    }
  } else if (year == 2012) {
    # Basic derivation from nativity
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
  } else if (year == 2006) {
    # Look for party identification variables
    if ("qn6b" %in% names(data)) {
      party <- clean_values(data$qn6b)
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # Use qn18: "Do you consider yourself closer to the Republican party or the Democratic party?"
    if ("qn18" %in% names(data)) {
      party <- clean_values(data$qn18)
      party <- case_when(
        party == 1 ~ 2,  # Republican
        party == 2 ~ 1,  # Democrat
        party == 3 ~ 3,  # Independent/Neither
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2008) {
    # Use combo22 (leaned party identification) or individual party questions
    if ("combo22" %in% names(data)) {
      party <- clean_values(data$combo22)
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # Limited party variables in 2009
    party <- rep(NA_real_, nrow(data))
  } else if (year == 2010) {
    # Use qn13 or qn14 for party preference
    if ("qn13" %in% names(data)) {
      party <- clean_values(data$qn13)
      party <- case_when(
        party == 1 ~ 2,  # Republican
        party == 2 ~ 1,  # Democrat
        TRUE ~ NA_real_
      )
    } else {
      party <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # Use available party variables
    party <- rep(NA_real_, nrow(data))
  } else if (year == 2012) {
    # Use available party variables
    party <- rep(NA_real_, nrow(data))
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
  } else if (year == 2006) {
    # Look for voting registration or intention
    if ("qn6b" %in% names(data)) {
      vote <- clean_values(data$qn6b)
    } else {
      vote <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # Use qn16: "Are you currently registered to vote at your present address"
    if ("qn16" %in% names(data)) {
      vote <- clean_values(data$qn16)
      vote <- case_when(
        vote == 1 ~ 1,  # Yes, registered
        vote == 2 ~ 0,  # No, not registered
        TRUE ~ NA_real_
      )
    } else {
      vote <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2008) {
    # Use combo14 (citizenship & registration) or combo23 (citizenship & whether voted)
    if ("combo23" %in% names(data)) {
      vote <- clean_values(data$combo23)
    } else if ("combo14" %in% names(data)) {
      vote <- clean_values(data$combo14)
    } else {
      vote <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # Limited voting variables
    vote <- rep(NA_real_, nrow(data))
  } else if (year == 2010) {
    # Use qn12 or qn13 for election interest/intention
    if ("qn12" %in% names(data)) {
      vote <- clean_values(data$qn12)
      vote <- case_when(
        vote == 1 ~ 1,  # Quite a lot of thought
        vote == 2 ~ 0,  # Only a little
        TRUE ~ NA_real_
      )
    } else {
      vote <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # Limited voting variables
    vote <- rep(NA_real_, nrow(data))
  } else if (year == 2012) {
    # Look for voting or election variables
    vote <- rep(NA_real_, nrow(data))
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
  } else if (year == 2006) {
    # Use qn3a or other immigration attitude variables
    if ("qn3a" %in% names(data)) {
      attitude <- clean_values(data$qn3a)
      attitude <- case_when(
        attitude == 1 ~ 1,  # Favor
        attitude == 2 ~ 0,  # Oppose
        TRUE ~ NA_real_
      )
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # Use qn26: "undocumented or illegal immigrants help the economy"
    if ("qn26" %in% names(data)) {
      attitude <- clean_values(data$qn26)
      attitude <- case_when(
        attitude == 1 ~ 1,  # Help economy (pro-immigrant)
        attitude == 2 ~ 0,  # Hurt economy (anti-immigrant)
        TRUE ~ NA_real_
      )
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2008) {
    # Look for immigration attitude variables
    if ("qn17g" %in% names(data)) {
      attitude <- clean_values(data$qn17g)
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # Limited immigration attitude variables
    attitude <- rep(NA_real_, nrow(data))
  } else if (year == 2010) {
    # Use qn21b or other immigration variables
    if ("qn21b" %in% names(data)) {
      attitude <- clean_values(data$qn21b)
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # Use qn24 or qn25
    if ("qn24" %in% names(data)) {
      attitude <- clean_values(data$qn24)
    } else {
      attitude <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2012) {
    # Use qn21d or other variables
    if ("qn21d" %in% names(data)) {
      attitude <- clean_values(data$qn21d)
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
  } else if (year == 2006) {
    # Use qn15b or similar
    if ("qn15b" %in% names(data)) {
      border <- clean_values(data$qn15b)
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2007) {
    # Use qn24: "too many, too few, or about the right amount of immigrants"
    if ("qn24" %in% names(data)) {
      border <- clean_values(data$qn24)
      border <- case_when(
        border == 1 ~ 3,  # Too many -> restrictive
        border == 2 ~ 1,  # Too few -> permissive
        border == 3 ~ 2,  # About right -> moderate
        TRUE ~ NA_real_
      )
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2008) {
    # Use qn40ca or other border variables
    if ("qn40ca" %in% names(data)) {
      border <- clean_values(data$qn40ca)
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # Limited border security variables
    border <- rep(NA_real_, nrow(data))
  } else if (year == 2010) {
    # Use qn44, qn47, or qn48
    if ("qn44" %in% names(data)) {
      border <- clean_values(data$qn44)
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # Use qn24, qn25, or qn28
    if ("qn24" %in% names(data)) {
      border <- clean_values(data$qn24)
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2012) {
    # Use qn31
    if ("qn31" %in% names(data)) {
      border <- clean_values(data$qn31)
    } else {
      border <- rep(NA_real_, nrow(data))
    }
  } else {
    border <- rep(NA_real_, nrow(data))
  }
  
  return(border)
}

# Enhanced function to harmonize demographic variables (age, gender)
harmonize_demographics <- function(data, year) {
  # Age harmonization - comprehensive approach
  age <- rep(NA_real_, nrow(data))
  
  # Year-specific age variables - COMPREHENSIVE MAPPING
  age_var_map <- list(
    "2002" = c("AGE", "age", "RAGES", "qn_age"),
    "2004" = c("AGE1", "AGE2", "age", "RAGES"), 
    "2006" = c("qn74year", "age", "RAGES"),
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
        
        # Convert age ranges to approximate midpoint values
        if (var %in% c("AGE1", "AGE2")) {
          # 2004 age ranges: 1=18-29, 2=30-39, 3=40-54, 4=55+, 5=65+ (AGE2 only)
          age <- case_when(
            age == 1 ~ 24,   # 18-29 → 24
            age == 2 ~ 35,   # 30-39 → 35  
            age == 3 ~ 47,   # 40-54 → 47
            age == 4 ~ 62,   # 55+ → 62
            age == 5 ~ 70,   # 65+ → 70 (AGE2 only)
            TRUE ~ NA_real_
          )
        } else if (var == "qn74year") {
          # 2006 age ranges - convert to approximate ages
          # Need to check what these represent, for now use as ranges
          age <- case_when(
            age >= 1 & age <= 20 ~ age + 20,  # Approximate conversion
            TRUE ~ NA_real_
          )
        }
        break
      }
    }
  }
  
  # Gender harmonization - comprehensive approach
  gender <- rep(NA_real_, nrow(data))
  
  # Year-specific gender variables
  gender_var_map <- list(
    "2002" = c("gender", "RSEX", "qnd18"),
    "2004" = c("gender", "RSEX", "qnd18"),
    "2006" = c("gender", "RSEX", "qnd18"),
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
harmonize_race_ethnicity <- function(data, year) {
  race <- rep(NA_real_, nrow(data))
  ethnicity <- rep(NA_real_, nrow(data))
  
  # Ethnicity harmonization (Hispanic/Latino heritage)
  ethnicity_var_map <- list(
    "2002" = "QN1",  # Hispanic/Latino origin question
    "2004" = "QN1",  # Check if 2004 has similar
    "2006" = "qn1",  # Check if 2006 has similar
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

# Enhanced function to harmonize language spoken at home
harmonize_language <- function(data, year) {
  language <- rep(NA_real_, nrow(data))
  
  # Language variable mapping
  lang_var_map <- list(
    "2002" = "QN2",   # Language preference question
    "2004" = "LANGUAGE", # Check if this exists
    "2006" = "language", # Check if this exists
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

# Main harmonization function
harmonize_survey_data <- function(file_path, year) {
  cat("Processing", year, "data:", file_path, "\n")
  
  # Read the data
  data <- read_survey_data(file_path)
  cat("Original data dimensions:", dim(data), "\n")
  
  # Get demographics
  demographics <- harmonize_demographics(data, year)
  race_eth <- harmonize_race_ethnicity(data, year)
  language <- harmonize_language(data, year)
  
  # Create harmonized dataset
  harmonized_data <- data.frame(
    survey_year = year,
    age = demographics$age,
    gender = demographics$gender,
    race = race_eth$race,
    ethnicity = race_eth$ethnicity,
    language_home = language,
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
  attr(harmonized_data$age, "label") <- "Age in years"
  attr(harmonized_data$gender, "label") <- "Gender (1=Male, 2=Female)"
  attr(harmonized_data$race, "label") <- "Race/ethnicity"
  attr(harmonized_data$ethnicity, "label") <- "Hispanic/Latino ethnicity"
  attr(harmonized_data$language_home, "label") <- "Language spoken at home (1=English, 2=Spanish)"
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
    cat(sprintf("%-25s: %d unique values, %s%% missing\n", var, n_unique, pct_missing))
  }
  
  return(harmonized_data)
}

# Process files
process_survey_files <- function() {
  
  # Create output directory
  if (!dir.exists("cleaned_data")) {
    dir.create("cleaned_data")
  }
  
  # Define file mappings for 2002-2012
  file_mappings <- list(
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
  cat("=== Running Fixed Data Harmonization (2002-2012) ===\n\n")
  harmonized_files <- process_survey_files()
  
  # Validate each file
  for (year in names(harmonized_files)) {
    validate_harmonized_data(harmonized_files[[year]], year)
  }
  
  cat("Fixed harmonization complete!\n")
}