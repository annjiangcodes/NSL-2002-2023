# =============================================================================
# SIMPLE GENERATION DATA RECOVERY TEST v3.1
# =============================================================================
# Purpose: Test how many generation observations we can recover with fixed mappings
# Expected: ~7,000+ additional observations from years 2008, 2009, 2015, 2018

library(haven)
library(dplyr)

cat("=================================================================\n")
cat("TESTING GENERATION DATA RECOVERY v3.1 (SIMPLE VERSION)\n") 
cat("=================================================================\n")

# CORRECTED GENERATION FUNCTIONS (extracted from ANALYSIS_v2_6_GENERATION_FIXED.R)

load_survey_data_robust <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }
  
  # Determine file type and read accordingly
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
  # Convert to numeric and remove invalid codes (negative values, very high codes)
  x_num <- as.numeric(x)
  ifelse(x_num < 0 | x_num > 10, NA, x_num)
}

harmonize_place_birth_corrected <- function(data, year) {
  cat(sprintf("    Processing place of birth for year %d...\n", year))
  
  if (year %in% c(2002, 2004)) {
    # 2002/2004: Check multiple possible variables
    if ("qn3" %in% names(data)) {
      place_birth <- clean_values(data$qn3)
    } else if ("q3" %in% names(data)) {
      place_birth <- clean_values(data$q3)
    } else if ("Q3" %in% names(data)) {
      place_birth <- clean_values(data$Q3)
    } else {
      place_birth <- rep(NA_real_, nrow(data))
    }
  } else if (year %in% c(2006, 2007, 2008, 2009, 2010, 2011, 2012)) {
    # 2006-2012: Use qn5 for place of birth
    place_birth <- if ("qn5" %in% names(data)) clean_values(data$qn5) else rep(NA_real_, nrow(data))
  } else if (year %in% c(2015, 2016, 2018)) {
    # 2015, 2016, 2018: Use qn5 for place of birth
    place_birth <- if ("qn5" %in% names(data)) clean_values(data$qn5) else rep(NA_real_, nrow(data))
  } else if (year %in% c(2021, 2022, 2023)) {
    # ATP surveys: Use BORN_A for place of birth
    place_birth <- if ("BORN_A" %in% names(data)) clean_values(data$BORN_A) else rep(NA_real_, nrow(data))
  } else {
    place_birth <- rep(NA_real_, nrow(data))
  }
  
  return(place_birth)
}

harmonize_parent_nativity_corrected <- function(data, year) {
  cat(sprintf("    Processing parent nativity for year %d...\n", year))
  
  if (year %in% c(2002, 2004)) {
    # 2002/2004: Use qn7 (mother) and qn8 (father)
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
  } else if (year %in% c(2006, 2007, 2010, 2011, 2012)) {
    # 2006-2012: Use qn7 (mother) and qn8 (father)
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
  } else if (year %in% c(2008, 2009)) {
    # 2008, 2009 use qn7 (mother) and qn8 (father) - SAME FORMAT AS 2007/2010
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
  } else if (year %in% c(2015, 2018)) {
    # 2015, 2018 likely use similar qn7/qn8 pattern - test both cases
    if ("qn7" %in% names(data) && "qn8" %in% names(data)) {
      mother <- clean_values(data$qn7)
      father <- clean_values(data$qn8)
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else if ("Q7" %in% names(data) && "Q8" %in% names(data)) {
      # Try uppercase Q7/Q8 format
      mother <- clean_values(data$Q7)
      father <- clean_values(data$Q8)
      parent_nat <- case_when(
        (mother == 3 & father == 3) ~ 3,  # Both foreign born
        (mother == 3 | father == 3) ~ 2,  # One foreign born
        (mother %in% c(1,2) & father %in% c(1,2)) ~ 1,  # Both US/PR born
        TRUE ~ NA_real_
      )
    } else {
      parent_nat <- rep(NA_real_, nrow(data))
    }
  } else if (year == 2016) {
    # 2016: Use qn7 (mother) and qn8 (father) 
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
  } else if (year %in% c(2021, 2022, 2023)) {
    # ATP surveys: Use MOM_BORN_A and DAD_BORN_A
    if ("MOM_BORN_A" %in% names(data) && "DAD_BORN_A" %in% names(data)) {
      mother <- clean_values(data$MOM_BORN_A)
      father <- clean_values(data$DAD_BORN_A)
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

# Test specific years that had 0% coverage before
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
cat("GENERATION RECOVERY SUMMARY\n")
cat("=================================================================\n")

if (nrow(recovery_results) > 0) {
  print(recovery_results)
  
  total_recovered <- sum(recovery_results$generation_recovered)
  cat(sprintf("\nTOTAL GENERATION OBSERVATIONS RECOVERED: %d\n", total_recovered))
  cat(sprintf("AVERAGE RECOVERY RATE: %.1f%%\n", mean(recovery_results$recovery_rate)))
  
  cat("\nIMPACT:\n")
  cat(sprintf("- Years with generation data: BEFORE 8 years → AFTER %d years\n", 8 + nrow(recovery_results)))
  cat(sprintf("- Total observations with generation: BEFORE ~22K → AFTER ~%dK\n", round((22000 + total_recovered)/1000)))
  cat(sprintf("- Percentage improvement: +%.0f%% more generation coverage\n", 100 * total_recovered / 22000))
}

cat("\n=================================================================\n")
cat("GENERATION RECOVERY TEST COMPLETE\n")
cat("=================================================================\n")