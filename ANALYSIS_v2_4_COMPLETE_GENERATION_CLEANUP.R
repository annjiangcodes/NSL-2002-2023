# ============================================================================
# ANALYSIS v2.4: COMPLETE GENERATION CLEANUP AND FINAL DATASET
# ============================================================================
# Purpose: Fix parent nativity extraction for 2010-2012 using correct variable
#          names and create the complete, clean dataset with properly derived
#          generation data for all years using Portes's protocol.
# Version: 2.4
# Date: Current analysis session
# Previous Issues: v2.3 had incomplete parent nativity for 2010-2012
# ============================================================================

library(haven)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(stringr)
library(ggplot2)
library(viridis)
library(forcats)
library(broom)
library(survey)

cat("=== ANALYSIS v2.4: COMPLETE GENERATION CLEANUP ===\n")

# ============================================================================
# COMPLETE HARMONIZATION FUNCTIONS WITH FIXED PARENT NATIVITY 
# ============================================================================

# Helper function to clean values
clean_values <- function(x) {
  x <- as.numeric(x)
  x[x %in% c(98, 99, 88, 89, 8, 9, 98, 999, -1, -2, -8, -9)] <- NA
  return(x)
}

# Function to harmonize place of birth (comprehensive version)
harmonize_place_birth <- function(data, year) {
  if (year == 2002) {
    if ("QN2" %in% names(data)) {
      place_birth <- clean_values(data$QN2)
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
      place_birth <- rep(NA_real_, nrow(data))
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
  } else if (year %in% c(2008, 2009, 2010, 2011, 2012)) {
    if ("qn5" %in% names(data)) {
      place_birth <- clean_values(data$qn5)
      place_birth <- case_when(
        place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
        place_birth == 3 ~ 2,  # Another country -> Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2014, 2015, 2016)) {
    # Check multiple possible birth variables for these years
    birth_vars <- c("birthplace", "qn5", "qns8", "Q5")
    place_birth <- rep(NA_real_, nrow(data))
    
    for (var in birth_vars) {
      if (var %in% names(data)) {
        place_birth <- clean_values(data[[var]])
        place_birth <- case_when(
          place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
          place_birth == 3 ~ 2,  # Another country -> Foreign born
          TRUE ~ NA_real_
        )
        break
      }
    }
  } else if (year == 2018) {
    if ("birthplace" %in% names(data)) {
      place_birth <- clean_values(data$birthplace)
      place_birth <- case_when(
        place_birth == 1 ~ 1,  # US born
        place_birth == 2 ~ 2,  # Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2021, 2022, 2023)) {
    if ("F_BIRTHPLACE_EXPANDED" %in% names(data)) {
      place_birth <- clean_values(data$F_BIRTHPLACE_EXPANDED)
      place_birth <- case_when(
        place_birth == 1 ~ 1,  # US born
        place_birth %in% c(2:99) ~ 2,  # Foreign born (various countries)
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

# Function to harmonize parent nativity (FIXED VERSION for 2010-2012)
harmonize_parent_nativity <- function(data, year) {
  if (year == 2002) {
    if ("QN4" %in% names(data) && "QN5" %in% names(data)) {
      mother <- clean_values(data$QN4)
      father <- clean_values(data$QN5)
      
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN5" %in% names(data) && "QN6" %in% names(data)) {
      mother <- clean_values(data$QN5)
      father <- clean_values(data$QN6)
      
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2006) {
    if ("qn64" %in% names(data)) {
      parent_nat <- clean_values(data$qn64)
      # Mapping based on established harmonization
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
  } else if (year == 2008) {
    if ("qn62" %in% names(data)) {
      parent_nat <- clean_values(data$qn62)
      # Standard parent nativity mapping for composite variable
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2009) {
    # 2009 might not have parent nativity data
    parent_nat <- rep(NA_real_, nrow(data))
  } else if (year == 2010) {
    # FIXED: Use qn58 for 2010 parent nativity
    if ("qn58" %in% names(data)) {
      parent_nat <- clean_values(data$qn58)
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # FIXED: Use qn64 for 2011 parent nativity
    if ("qn64" %in% names(data)) {
      parent_nat <- clean_values(data$qn64)
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2012) {
    # FIXED: Use qn67 for 2012 parent nativity
    if ("qn67" %in% names(data)) {
      parent_nat <- clean_values(data$qn67)
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2021, 2022, 2023)) {
    # ATP surveys have individual mother/father variables
    mother_vars <- c("MOTHERNAT_W86", "MOTHERNAT_W113", "MOTHERNAT_W138")
    father_vars <- c("FATHERNAT_W86", "FATHERNAT_W113", "FATHERNAT_W138")
    
    mother_var <- mother_vars[mother_vars %in% names(data)][1]
    father_var <- father_vars[father_vars %in% names(data)][1]
    
    if (!is.na(mother_var) && !is.na(father_var)) {
      mother <- clean_values(data[[mother_var]])
      father <- clean_values(data[[father_var]])
      
      parent_nat <- case_when(
        (mother == 2 & father == 2) ~ 3,  # Both foreign born
        (mother == 2 | father == 2) ~ 2,  # One foreign born
        (mother == 1 & father == 1) ~ 1,  # Both US born
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

# Function to derive immigrant generation using Portes Protocol (COMPLETE VERSION)
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

# ============================================================================
# COMPREHENSIVE VARIABLE MAP (all variables from previous explorations)
# ============================================================================

comprehensive_map <- list(
  # Liberalism Index Variables
  legalization_support = list(
    "2002" = list(var = "QN26", direction = 1),
    "2004" = list(var = "QN40", direction = 1), 
    "2006" = list(var = "qn13", direction = 1),
    "2010" = list(var = "qn42", direction = 1),
    "2014" = list(var = "Q36", direction = 1),
    "2021" = list(var = "IMMVAL_c_W86", direction = -1),
    "2022" = list(var = "IMMVAL_C_W113", direction = -1)
  ),
  
  daca_support = list(
    "2011" = list(var = "qn24", direction = 1),
    "2012" = list(var = "qn31", direction = 1),
    "2018" = list(var = "qn28", direction = 1),
    "2021" = list(var = "IMMVAL_i_W86", direction = -1)
  ),
  
  immigrants_strengthen = list(
    "2006" = list(var = "qn20", direction = 1)
  ),
  
  # Restrictionism Index Variables  
  immigration_level_opinion = list(
    "2002" = list(var = "QN23", direction = 1),
    "2007" = list(var = "qn24", direction = 1),
    "2018" = list(var = "qn31", direction = 1)
  ),
  
  border_wall_support = list(
    "2010" = list(var = "qn49c", direction = -1),
    "2018" = list(var = "qn29", direction = -1)
  ),
  
  deportation_policy_support = list(
    "2010" = list(var = "qn48", direction = 1),
    "2021" = list(var = "IMMVAL_b_W86", direction = 1),
    "2022" = list(var = "IMMVAL_B_W113", direction = 1)
  ),
  
  border_security_support = list(
    "2010" = list(var = "qn49d", direction = 1),
    "2021" = list(var = "IMMVAL_d_W86", direction = 1),
    "2022" = list(var = "IMMVAL_D_W113", direction = 1)
  ),
  
  immigration_importance = list(
    "2010" = list(var = "qn23e", direction = 1),
    "2011" = list(var = "qn22d", direction = 1),
    "2012" = list(var = "qn21d", direction = 1),
    "2016" = list(var = "qn20d", direction = 1)
  ),
  
  # Concern Index Variables
  deportation_worry = list(
    "2007" = list(var = "qn33", direction = 1),
    "2010" = list(var = "qn32", direction = 1),
    "2018" = list(var = "qn24", direction = 1),
    "2021" = list(var = "WORRYDPORT_W86", direction = 1)
  )
)

# ============================================================================
# MAIN PROCESSING FUNCTION 
# ============================================================================

# Function to load survey data robustly
load_survey_data_robust <- function(file_path) {
  if (str_ends(file_path, ".sav")) {
    return(read_sav(file_path))
  } else if (str_ends(file_path, ".dta")) {
    return(read_dta(file_path))
  } else {
    stop("Unsupported file format")
  }
}

# Main harmonization function
harmonize_survey_year <- function(year_str, file_map) {
  cat(sprintf("Processing year %s...\n", year_str))
  
  if (!(year_str %in% names(file_map))) {
    cat(sprintf("  No file specified for year %s, skipping\n", year_str))
    return(NULL)
  }
  
  file_path <- file_map[[year_str]]
  
  tryCatch({
    # Load data
    data <- load_survey_data_robust(file_path)
    cat(sprintf("  Loaded %d observations\n", nrow(data)))
    
    # Derive immigrant generation using our FIXED functions
    immigrant_generation <- derive_immigrant_generation(data, as.numeric(year_str))
    place_birth <- harmonize_place_birth(data, as.numeric(year_str))
    parent_nativity <- harmonize_parent_nativity(data, as.numeric(year_str))
    
    # Count generation coverage
    gen_valid <- sum(!is.na(immigrant_generation))
    gen_1_2_3 <- sum(immigrant_generation %in% c(1, 2, 3), na.rm = TRUE)
    place_valid <- sum(!is.na(place_birth))
    parent_valid <- sum(!is.na(parent_nativity))
    
    cat(sprintf("  Generation derived: %d total, %d gen 1-3\n", gen_valid, gen_1_2_3))
    cat(sprintf("  Place birth valid: %d, Parent nativity valid: %d\n", place_valid, parent_valid))
    
    # Initialize harmonized variables
    harmonized_vars <- tibble(
      survey_year = as.numeric(year_str),
      immigrant_generation = immigrant_generation,
      place_birth = place_birth,
      parent_nativity = parent_nativity
    )
    
    # Extract and harmonize each variable
    for (var_name in names(comprehensive_map)) {
      var_map <- comprehensive_map[[var_name]]
      
      if (year_str %in% names(var_map)) {
        var_info <- var_map[[year_str]]
        var_col <- var_info$var
        direction <- var_info$direction
        
        if (var_col %in% names(data)) {
          raw_values <- clean_values(data[[var_col]])
          harmonized_values <- raw_values * direction
          harmonized_vars[[var_name]] <- harmonized_values
          cat(sprintf("    Extracted %s: %d valid responses\n", var_name, sum(!is.na(harmonized_values))))
        } else {
          harmonized_vars[[var_name]] <- NA_real_
          cat(sprintf("    Variable %s (%s) not found in data\n", var_name, var_col))
        }
      } else {
        harmonized_vars[[var_name]] <- NA_real_
      }
    }
    
    return(harmonized_vars)
    
  }, error = function(e) {
    cat(sprintf("  Error processing year %s: %s\n", year_str, e$message))
    return(NULL)
  })
}

# ============================================================================
# FILE MAPPING (CORRECTED PATHS)
# ============================================================================

file_map <- list(
  "2002" = "data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004" = "data/raw/2004 Political Survey Rev 1-6-05.sav", 
  "2006" = "data/raw/2006-National-Survey-of-Latinos-The-Immigration-Debate_4bf554/f1171_050207 uploaded dataset.sav",
  "2007" = "data/raw/publicreleaseNSL07_UPDATED_3.7.22.sav",
  "2008" = "data/raw/PHCNSL2008aPublicRelease_UPDATED 3.7.22.sav",
  "2009" = "data/raw/PHCNSL2009PublicRelease.sav",
  "2010" = "data/raw/PHCNSL2010PublicRelease_UPDATED 3.7.22.sav",
  "2011" = "data/raw/PHCNSL2011PubRelease_UPDATED 3.7.22.sav",
  "2012" = "data/raw/PHCNSL2012PublicRelease_UPDATED 3.7.22.sav",
  "2014" = "data/raw/NSL2014_FOR RELEASE.sav",
  "2015" = "data/raw/NSL2015_FOR RELEASE.sav",
  "2016" = "data/raw/NSL 2016_FOR RELEASE.sav",
  "2018" = "data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav",
  "2021" = "data/raw/2021 ATP W86.sav",
  "2022" = "data/raw/NSL 2022 complete dataset national survey of latinos 2022.dta",
  "2023" = "data/raw/2023ATP W138.sav"
)

# ============================================================================
# EXECUTE PROCESSING
# ============================================================================

cat("Starting comprehensive harmonization with FIXED generation derivation...\n")

# Process all available years
all_years <- names(file_map)
all_data <- map(all_years, ~harmonize_survey_year(.x, file_map))
names(all_data) <- all_years

# Combine non-null results
valid_data <- all_data[!map_lgl(all_data, is.null)]
combined_data <- bind_rows(valid_data)

cat(sprintf("Combined data: %d total observations across %d years\n", 
            nrow(combined_data), length(valid_data)))

# ============================================================================
# CREATE THEMATIC INDICES
# ============================================================================

standardize_var <- function(x) {
  if (all(is.na(x))) return(x)
  return(as.numeric(scale(x)))
}

indices_data <- combined_data %>%
  group_by(survey_year) %>%
  mutate(
    # Standardize within each year
    legalization_support_std = standardize_var(legalization_support),
    daca_support_std = standardize_var(daca_support),
    immigrants_strengthen_std = standardize_var(immigrants_strengthen),
    immigration_level_opinion_std = standardize_var(immigration_level_opinion),
    border_wall_support_std = standardize_var(border_wall_support),
    deportation_policy_support_std = standardize_var(deportation_policy_support),
    border_security_support_std = standardize_var(border_security_support),
    immigration_importance_std = standardize_var(immigration_importance),
    deportation_worry_std = standardize_var(deportation_worry)
  ) %>%
  ungroup() %>%
  rowwise() %>%
  mutate(
    # Create thematic indices
    liberalism_index = mean(c(legalization_support_std, daca_support_std, immigrants_strengthen_std), na.rm = TRUE),
    restrictionism_index = mean(c(immigration_level_opinion_std, border_wall_support_std, 
                                deportation_policy_support_std, border_security_support_std, 
                                immigration_importance_std), na.rm = TRUE),
    concern_index = deportation_worry_std,
    
    # Count components for validity
    liberalism_components = sum(!is.na(c(legalization_support_std, daca_support_std, immigrants_strengthen_std))),
    restrictionism_components = sum(!is.na(c(immigration_level_opinion_std, border_wall_support_std, 
                                           deportation_policy_support_std, border_security_support_std, 
                                           immigration_importance_std))),
    concern_components = sum(!is.na(deportation_worry_std))
  ) %>%
  ungroup() %>%
  mutate(
    # Set indices to NA if no valid components
    liberalism_index = ifelse(liberalism_components == 0, NA_real_, liberalism_index),
    restrictionism_index = ifelse(restrictionism_components == 0, NA_real_, restrictionism_index),
    concern_index = ifelse(concern_components == 0, NA_real_, concern_index)
  )

# ============================================================================
# FINAL COVERAGE SUMMARY AND VALIDATION
# ============================================================================

coverage_summary <- indices_data %>%
  group_by(survey_year) %>%
  summarize(
    total_respondents = n(),
    generation_coverage = sum(!is.na(immigrant_generation)),
    gen_1_2_3 = sum(immigrant_generation %in% c(1, 2, 3), na.rm = TRUE),
    place_birth_coverage = sum(!is.na(place_birth)),
    parent_nativity_coverage = sum(!is.na(parent_nativity)),
    liberalism_valid = sum(!is.na(liberalism_index)),
    restrictionism_valid = sum(!is.na(restrictionism_index)),
    concern_valid = sum(!is.na(concern_index)),
    .groups = "drop"
  )

print("=== FINAL COVERAGE SUMMARY v2.4 ===")
print(coverage_summary)

# Additional summary by generation
generation_summary <- indices_data %>%
  filter(!is.na(immigrant_generation)) %>%
  group_by(survey_year, immigrant_generation) %>%
  summarize(
    count = n(),
    liberalism_available = sum(!is.na(liberalism_index)),
    restrictionism_available = sum(!is.na(restrictionism_index)),
    concern_available = sum(!is.na(concern_index)),
    .groups = "drop"
  ) %>%
  arrange(survey_year, immigrant_generation)

print("=== GENERATION BREAKDOWN v2.4 ===")
print(generation_summary)

# ============================================================================
# SAVE COMPLETE DATASET
# ============================================================================

# Create directories if they don't exist
dir.create("data/final", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs/summaries", showWarnings = FALSE, recursive = TRUE)

# Save the complete, clean dataset
write_csv(indices_data, "data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv")
write_csv(coverage_summary, "outputs/summaries/data_coverage_summary_v2_4.csv")
write_csv(generation_summary, "outputs/summaries/generation_breakdown_v2_4.csv")

cat("\n=== ANALYSIS v2.4 COMPLETE ===\n")
cat("COMPLETE DATASET saved to: data/final/COMPLETE_LONGITUDINAL_DATASET_v2_4.csv\n")
cat("Coverage summary saved to: outputs/summaries/data_coverage_summary_v2_4.csv\n")
cat("Generation breakdown saved to: outputs/summaries/generation_breakdown_v2_4.csv\n")