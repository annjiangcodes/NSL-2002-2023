# =============================================================================
# QUICK TEST: Generation Data Recovery v3.1
# =============================================================================
# Purpose: Test how many generation observations we can recover with fixed mappings
# Expected: ~7,000+ additional observations from years 2008, 2009, 2015, 2018

library(haven)
library(dplyr)

cat("=================================================================\n")
cat("TESTING GENERATION DATA RECOVERY v3.1\n") 
cat("=================================================================\n")

# Source the CORRECTED generation functions
source("ANALYSIS_v2_6_GENERATION_FIXED.R")

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
        place_birth <- harmonize_place_birth_corrected(data, as.numeric(year_str))
        parent_nativity <- harmonize_parent_nativity_corrected(data, as.numeric(year_str))
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