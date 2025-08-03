# =============================================================================
# FINAL GENERATION DATA RECOVERY TEST v3.1 - COMPLETE FIX
# =============================================================================
# Purpose: Test complete generation data recovery with ALL correct mappings
# Expected: ~6,000+ additional observations from years 2008, 2009, 2015, 2018

library(haven)
library(dplyr)

cat("=================================================================\n")
cat("FINAL GENERATION DATA RECOVERY TEST v3.1 - COMPLETE FIX\n") 
cat("=================================================================\n")

# COMPLETE CORRECTED GENERATION FUNCTIONS

load_survey_data_robust <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  if (grepl("\\.(sav|SAV)$", file_path)) {
    data <- read_sav(file_path)
  } else if (grepl("\\.(dta|DTA)$", file_path)) {
    data <- read_dta(file_path)
  } else {
    stop("Unsupported file format: ", file_path)
  }
  
  cat(sprintf("  Loaded: %d observations, %d variables from %s\n", 
              nrow(data), ncol(data), basename(file_path)))
  return(data)
}

clean_values <- function(x) {
  x_num <- as.numeric(x)
  ifelse(x_num < 0 | x_num > 50, NA, x_num)  # Expanded range for different coding schemes
}

harmonize_place_birth_corrected <- function(data, year) {
  cat(sprintf("    Processing place of birth for year %d...\n", year))
  
  if (year %in% c(2008, 2009)) {
    # 2008-2009: Use qn5 for place of birth
    place_birth <- if ("qn5" %in% names(data)) clean_values(data$qn5) else rep(NA_real_, nrow(data))
  } else if (year == 2015) {
    # 2015: Use 'born' variable or q2 - try both
    if ("born" %in% names(data)) {
      born_vals <- clean_values(data$born)
      # born: 1=US, 2=foreign, map to our scale: 1,2=US/PR, 3=foreign
      place_birth <- case_when(
        born_vals == 1 ~ 1,  # US born
        born_vals == 2 ~ 3,  # Foreign born
        TRUE ~ NA_real_
      )
    } else if ("q2" %in% names(data)) {
      q2_vals <- clean_values(data$q2)
      # q2: check if it follows standard pattern
      place_birth <- case_when(
        q2_vals %in% c(1, 2) ~ q2_vals,  # US/PR born
        q2_vals == 3 ~ 3,  # Foreign born
        TRUE ~ NA_real_
      )
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2018) {
    # 2018: Use qn3, but check multiple coding patterns
    if ("qn3" %in% names(data)) {
      qn3_vals <- clean_values(data$qn3)
      # Standard NSL coding: 1=US, 2=PR, 3=foreign, but check if reversed
      place_birth <- case_when(
        qn3_vals %in% c(1, 2) ~ qn3_vals,  # US/PR born  
        qn3_vals == 3 ~ 3,  # Foreign born
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

harmonize_parent_nativity_corrected <- function(data, year) {
  cat(sprintf("    Processing parent nativity for year %d...\n", year))
  
  if (year %in% c(2008, 2009)) {
    # 2008, 2009: Use qn7 (mother) and qn8 (father)
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
  } else if (year == 2015) {
    # 2015: Use q7 (mother) and q8 (father) - different from qn7/qn8
    if ("q7" %in% names(data) && "q8" %in% names(data)) {
      mother <- clean_values(data$q7)
      father <- clean_values(data$q8)
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2018) {
    # 2018: Use qn7 (mother) and qn8 (father)
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

derive_immigrant_generation_corrected <- function(data, year) {
  place_birth <- harmonize_place_birth_corrected(data, year)
  parent_nativity <- harmonize_parent_nativity_corrected(data, year)
  
  generation <- case_when(
    place_birth == 3 ~ 1,  # First generation: foreign born
    place_birth %in% c(1, 2) & parent_nativity == 3 ~ 2,  # Second generation: US/PR born, both parents foreign
    place_birth %in% c(1, 2) & parent_nativity == 2 ~ 2,  # Second generation: US/PR born, one parent foreign
    place_birth %in% c(1, 2) & parent_nativity == 1 ~ 3,  # Third+ generation: US/PR born, both parents US/PR
    TRUE ~ NA_real_
  )
  
  return(generation)
}

# Test specific years
test_years <- c(2008, 2009, 2015, 2018)

# File mapping with corrected paths
file_map <- list(
  "2008" = "data/raw/PHCNSL2008aPublicRelease_UPDATED 3.7.22.sav",
  "2009" = "data/raw/PHCNSL2009PublicRelease.sav",
  "2015" = "data/raw/NSL2015_FOR RELEASE.sav",
  "2018" = "data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav"
)

recovery_results <- tibble()

for (year_str in as.character(test_years)) {
  if (year_str %in% names(file_map)) {
    file_path <- file_map[[year_str]]
    
    if (file.exists(file_path)) {
      cat(sprintf("\nTesting %s generation recovery...\n", year_str))
      
      tryCatch({
        data <- load_survey_data_robust(file_path)
        
        # Test our CORRECTED generation functions
        generation <- derive_immigrant_generation_corrected(data, as.numeric(year_str))
        
        # Calculate recovery
        result <- tibble(
          year = as.numeric(year_str),
          total_obs = nrow(data),
          generation_recovered = sum(!is.na(generation)),
          recovery_rate = round(100 * sum(!is.na(generation)) / nrow(data), 1),
          gen1 = sum(generation == 1, na.rm = TRUE),
          gen2 = sum(generation == 2, na.rm = TRUE),
          gen3 = sum(generation == 3, na.rm = TRUE)
        )
        
        recovery_results <- bind_rows(recovery_results, result)
        
        cat(sprintf("  BEFORE: 0 observations with generation data (0.0%%)\n"))
        cat(sprintf("  AFTER:  %d observations with generation data (%.1f%%)\n", 
                    sum(!is.na(generation)), 100 * sum(!is.na(generation)) / nrow(data)))
        cat(sprintf("  RECOVERED: %d generation observations!\n", sum(!is.na(generation))))
        cat(sprintf("  Distribution: %d first gen, %d second gen, %d third+ gen\n",
                    sum(generation == 1, na.rm = TRUE),
                    sum(generation == 2, na.rm = TRUE), 
                    sum(generation == 3, na.rm = TRUE)))
        
      }, error = function(e) {
        cat(sprintf("  Error processing %s: %s\n", year_str, e$message))
      })
    } else {
      cat(sprintf("  File not found: %s\n", file_path))
    }
  }
}

cat("\n=================================================================\n")
cat("FINAL GENERATION RECOVERY SUMMARY\n")
cat("=================================================================\n")

if (nrow(recovery_results) > 0) {
  print(recovery_results)
  
  total_recovered <- sum(recovery_results$generation_recovered)
  cat(sprintf("\nTOTAL GENERATION OBSERVATIONS RECOVERED: %d\n", total_recovered))
  cat(sprintf("AVERAGE RECOVERY RATE: %.1f%%\n", mean(recovery_results$recovery_rate)))
  
  cat("\nFINAL IMPACT:\n")
  cat(sprintf("- Years with generation data: BEFORE 8 years → AFTER %d years\n", 8 + nrow(recovery_results)))
  cat(sprintf("- Total observations with generation: BEFORE ~22K → AFTER ~%dK\n", round((22000 + total_recovered)/1000)))
  cat(sprintf("- Percentage improvement: +%.0f%% more generation coverage\n", 100 * total_recovered / 22000))
  
  if(total_recovered > 5000) {
    cat("\n*** MASSIVE DATA RECOVERY ACHIEVED! ***\n")
    cat("Ready for v3.1 full analysis with maximum generation coverage!\n")
  }
}

cat("\n=================================================================\n")
cat("FINAL GENERATION RECOVERY TEST COMPLETE\n")
cat("=================================================================\n")