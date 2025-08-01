# =============================================================================
# IMMIGRATION ATTITUDES ANALYSIS v2.6 - GENERATION CODING FIXED
# =============================================================================
# Purpose: Fix the fundamental generation coding errors that prevent proper
#          stratification across all years. Use correct variable names and
#          coding schemes for each survey year.
# Issue Found: v2.4 was using wrong variables (qn58 vs qn7/qn8, qn5 vs qn3)
# Solution: Apply correct generation derivation to enable BOTH maximum data
#           utilization AND proper generation stratification
# =============================================================================

library(haven)
library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)
library(viridis)
library(scales)

cat("=================================================================\n")
cat("IMMIGRATION ATTITUDES ANALYSIS v2.6 - GENERATION CODING FIXED\n") 
cat("=================================================================\n")

# =============================================================================
# 1. CORRECTED GENERATION CODING FUNCTIONS
# =============================================================================

cat("\n1. IMPLEMENTING CORRECTED GENERATION CODING\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Standardized function to clean common missing value codes
clean_values <- function(x) {
  missing_codes <- c(8, 9, 98, 99, -1, 999, -999, "8", "9", "98", "99")
  x[x %in% missing_codes] <- NA
  as.numeric(x)
}

# CORRECTED: Place of birth harmonization with PROPER variables and coding
harmonize_place_birth_corrected <- function(data, year) {
  if (year == 2002) {
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
    # 2006/2007 use qns8 or qn5
    birth_var <- NULL
    if ("qns8" %in% names(data)) {
      birth_var <- "qns8"
    } else if ("qn5" %in% names(data)) {
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
  } else if (year %in% c(2008, 2009)) {
    # Years that may not have good birth data
    place_birth <- rep(NA_real_, nrow(data))
  } else if (year == 2010) {
    # FIXED: 2010 should use qn3 (simple coding), NOT qn5 (country codes)
    if ("qn3" %in% names(data)) {
      place_birth <- clean_values(data$qn3)
      place_birth <- case_when(
        place_birth == 1 ~ 1,  # US born
        place_birth == 2 ~ 1,  # PR born (US territory)
        place_birth >= 3 ~ 2,  # Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2011, 2012)) {
    # Similar coding as 2010
    if ("qn3" %in% names(data)) {
      place_birth <- clean_values(data$qn3)
      place_birth <- case_when(
        place_birth == 1 ~ 1,  # US born
        place_birth == 2 ~ 1,  # PR born (US territory)
        place_birth >= 3 ~ 2,  # Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2015, 2016)) {
    # Check for various possible birth variables
    birth_vars <- c("qn3", "birthplace", "qn5", "qns8", "Q5")
    place_birth <- rep(NA_real_, nrow(data))
    
    for (var in birth_vars) {
      if (var %in% names(data)) {
        place_birth <- clean_values(data[[var]])
        if (var == "birthplace") {
          # Simple binary coding
          place_birth <- case_when(
            place_birth == 1 ~ 1,  # US born
            place_birth == 2 ~ 2,  # Foreign born
            TRUE ~ NA_real_
          )
        } else {
          # Standard 3-category coding
          place_birth <- case_when(
            place_birth %in% c(1, 2) ~ 1,  # US or PR -> US born
            place_birth >= 3 ~ 2,  # Foreign born
            TRUE ~ NA_real_
          )
        }
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
        place_birth >= 2 ~ 2,  # Foreign born (various countries)
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

# CORRECTED: Parent nativity harmonization with PROPER variables
harmonize_parent_nativity_corrected <- function(data, year) {
  if (year == 2002) {
    if ("QN106" %in% names(data)) {
      parent_nat <- clean_values(data$QN106)
      parent_nat <- case_when(
        parent_nat == 1 ~ 2,  # Mother only -> One foreign born
        parent_nat == 2 ~ 2,  # Father only -> One foreign born
        parent_nat == 3 ~ 3,  # Both parents -> Both foreign born
        parent_nat == 4 ~ 1,  # No -> Both US born
        parent_nat == 5 ~ 1,  # Born in Puerto Rico -> US born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2004) {
    if ("QN77" %in% names(data)) {
      parent_nat <- clean_values(data$QN77)
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
  } else if (year == 2007) {
    # CORRECTED: 2007 uses qn7 (mother) and qn8 (father)
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
  } else if (year == 2010) {
    # FIXED: 2010 uses qn7 (mother) and qn8 (father), NOT qn58
    if ("qn7" %in% names(data) && "qn8" %in% names(data)) {
      mother <- clean_values(data$qn7)
      father <- clean_values(data$qn8)
      
      # Similar coding as 2007
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2011) {
    # Use whatever parent variable is actually available
    if ("qn64" %in% names(data)) {
      parent_nat <- clean_values(data$qn64)
      parent_nat <- case_when(
        parent_nat == 1 ~ 3,  # Both foreign born
        parent_nat == 2 ~ 2,  # One foreign born
        parent_nat == 3 ~ 1,  # Both US born
        TRUE ~ NA_real_
      )
    } else if ("qn7" %in% names(data) && "qn8" %in% names(data)) {
      # Fallback to individual parent variables
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
  } else if (year == 2012) {
    # CORRECTED: Use qn67 which actually exists in 2012
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

# CORRECTED: Immigrant generation derivation using FIXED functions
derive_immigrant_generation_corrected <- function(data, year) {
  place_birth <- harmonize_place_birth_corrected(data, year)
  parent_nativity <- harmonize_parent_nativity_corrected(data, year)
  
  if (year == 2002 && "GEN1TO4" %in% names(data)) {
    # Use existing generation variable if available
    generation <- clean_values(data$GEN1TO4)
    generation <- case_when(
      generation == 1 ~ 1,  # First generation
      generation == 2 ~ 2,  # Second generation  
      generation %in% c(3, 4) ~ 3,  # Third+ generation
      TRUE ~ NA_real_
    )
  } else {
    # Derive using Portes protocol
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

# =============================================================================
# 2. REBUILD DATASET WITH CORRECTED GENERATION CODING
# =============================================================================

cat("\n2. REBUILDING DATASET WITH CORRECTED GENERATION CODING\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Survey files mapping
all_survey_files <- list(
  "2002" = "data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004" = "data/raw/2004 Political Survey Rev 1-6-05.sav",
  "2006" = "data/raw/f1171_050207 uploaded dataset.sav",
  "2007" = "data/raw/publicreleaseNSL07_UPDATED_3.7.22.sav",
  "2008" = "data/raw/PHCNSL2008_FINAL_PublicRelease_UPDATED_3.7.22.sav",
  "2009" = "data/raw/PHCNSL2009_FullPublicRelease_UPDATED_3.7.22.sav",
  "2010" = "data/raw/PHCNSL2010PublicRelease_UPDATED 3.7.22.sav",
  "2011" = "data/raw/PHCNSL2011PubRelease_UPDATED 3.7.22.sav",
  "2012" = "data/raw/PHCNSL2012PublicRelease_UPDATED 3.7.22.sav",
  "2015" = "data/raw/PHCNSL2015_FullPublicRelease_UPDATED_3.7.22.sav",
  "2016" = "data/raw/NSL 2016_FOR RELEASE.sav",
  "2018" = "data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav",
  "2021" = "data/raw/2021 ATP W86.sav",
  "2022" = "data/raw/NSL 2022 complete dataset national survey of latinos 2022.dta",
  "2023" = "data/raw/2023 NSL Comprehensive Final.sav"
)

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

# Test corrected generation coding on a few key years
test_years <- c(2002, 2004, 2007, 2010, 2011, 2012, 2021, 2022)

generation_test_results <- tibble()

for (year_str in as.character(test_years)) {
  if (year_str %in% names(all_survey_files)) {
    file_path <- all_survey_files[[year_str]]
    
    if (file.exists(file_path)) {
      cat(sprintf("Testing generation coding for year %s...\n", year_str))
      
      tryCatch({
        data <- load_survey_data_robust(file_path)
        
        # Test our corrected functions
        place_birth <- harmonize_place_birth_corrected(data, as.numeric(year_str))
        parent_nativity <- harmonize_parent_nativity_corrected(data, as.numeric(year_str))
        generation <- derive_immigrant_generation_corrected(data, as.numeric(year_str))
        
        # Calculate coverage
        result <- tibble(
          year = as.numeric(year_str),
          total_obs = nrow(data),
          place_birth_coverage = sum(!is.na(place_birth)),
          parent_nativity_coverage = sum(!is.na(parent_nativity)),
          generation_coverage = sum(!is.na(generation)),
          generation_pct = round(100 * sum(!is.na(generation)) / nrow(data), 1),
          gen1 = sum(generation == 1, na.rm = TRUE),
          gen2 = sum(generation == 2, na.rm = TRUE),
          gen3 = sum(generation == 3, na.rm = TRUE)
        )
        
        generation_test_results <- bind_rows(generation_test_results, result)
        
        cat(sprintf("  %d observations total\n", nrow(data)))
        cat(sprintf("  %d place birth (%d%%), %d parent nativity (%d%%), %d generation (%d%%)\n",
                    sum(!is.na(place_birth)), round(100*sum(!is.na(place_birth))/nrow(data)),
                    sum(!is.na(parent_nativity)), round(100*sum(!is.na(parent_nativity))/nrow(data)),
                    sum(!is.na(generation)), round(100*sum(!is.na(generation))/nrow(data))))
        cat(sprintf("  Generation distribution: %d first, %d second, %d third+\n\n",
                    sum(generation == 1, na.rm = TRUE),
                    sum(generation == 2, na.rm = TRUE),
                    sum(generation == 3, na.rm = TRUE)))
        
      }, error = function(e) {
        cat(sprintf("  ERROR: %s\n\n", e$message))
      })
    } else {
      cat(sprintf("File not found for year %s\n\n", year_str))
    }
  }
}

# Display test results
cat("CORRECTED GENERATION CODING TEST RESULTS:\n")
print(generation_test_results)

# Compare to v2.4 problematic years
cat("\n=================================================================\n")
cat("COMPARISON TO PREVIOUS v2.4 PROBLEMS\n")
cat("=================================================================\n")

cat("Previous v2.4 issues:\n")
cat("- 2010: Only 7 people with generation data (out of 1,375) = 0.5%\n")
cat("- 2011: Only 7 people with generation data (out of 1,220) = 0.6%\n")
cat("- 2012: Only 9 people with generation data (out of 1,765) = 0.5%\n")

if (nrow(generation_test_results) > 0) {
  problematic_years <- generation_test_results %>%
    filter(year %in% c(2010, 2011, 2012))
  
  if (nrow(problematic_years) > 0) {
    cat("\nCORRECTED results for previously problematic years:\n")
    for (i in 1:nrow(problematic_years)) {
      row <- problematic_years[i, ]
      cat(sprintf("- %d: %d people with generation data (out of %d) = %s%%\n",
                  row$year, row$generation_coverage, row$total_obs, row$generation_pct))
    }
    
    cat("\nGeneration distributions for corrected years:\n")
    for (i in 1:nrow(problematic_years)) {
      row <- problematic_years[i, ]
      cat(sprintf("- %d: %d first gen, %d second gen, %d third+ gen\n",
                  row$year, row$gen1, row$gen2, row$gen3))
    }
  }
}

cat("\n=================================================================\n")
cat("GENERATION CODING DIAGNOSTIC COMPLETE\n")
cat("=================================================================\n")

# Save test results
write_csv(generation_test_results, "outputs/generation_coding_test_results_corrected.csv")
cat("Test results saved to outputs/generation_coding_test_results_corrected.csv\n")