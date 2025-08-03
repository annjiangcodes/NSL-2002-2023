# ============================================================================
# ANALYSIS v2.1 FIXED: CORRECTED FILE PATHS AND DATA COVERAGE
# ============================================================================
# Purpose: Fix the data points issue by using correct file paths that match
#          the actual files in data/raw directory and restoring full coverage.
# Version: 2.1 Fixed
# Date: Current analysis session
# Previous Issues: v2.1 had incorrect file paths causing missing data
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

cat("=== ANALYSIS v2.1 FIXED: CORRECTED HARMONIZATION ===\n")

# ============================================================================
# 1. DEFINE EXPANDED VARIABLE MAP (including all findings from exploration)
# ============================================================================
cat("1. Defining expanded variable map with all discovered variables...\n")

# This is the COMPLETE map based on our thorough exploration of survey files
expanded_variable_map <- list(
  # ----- Index 1: Immigration Policy Liberalism -----
  legalization_support = list(
    `2002` = list(var = "QN26", direction = 1),
    `2004` = list(var = "QN40", direction = 1), 
    `2006` = list(var = "qn13", direction = 1),
    `2010` = list(var = "qn42", direction = 1),  # From our exploration
    `2014` = list(var = "Q36", direction = 1),   # From our exploration  
    `2021` = list(var = "IMMVAL_c_W86", direction = -1),
    `2022` = list(var = "IMMVAL_C_W113", direction = -1)
  ),
  daca_support = list(
    `2011` = list(var = "qn24", direction = 1),  # From our exploration
    `2012` = list(var = "qn31", direction = 1),  # From our exploration
    `2018` = list(var = "qn28", direction = 1),
    `2021` = list(var = "IMMVAL_i_W86", direction = -1)
  ),
  immigrants_strengthen = list(
    `2006` = list(var = "qn20", direction = 1)
  ),
  # ----- Index 2: Immigration Policy Restrictionism -----
  immigration_level_opinion = list(
    `2002` = list(var = "QN23", direction = 1),
    `2007` = list(var = "qn24", direction = 1),
    `2018` = list(var = "qn31", direction = 1)
  ),
  border_wall_support = list(
    `2010` = list(var = "qn49c", direction = -1), # From our exploration
    `2018` = list(var = "qn29", direction = -1)
  ),
  border_security_support = list(
    `2010` = list(var = "qn49d", direction = 1),  # From our exploration
    `2021` = list(var = "IMMVAL_d_W86", direction = 1),
    `2022` = list(var = "IMMVAL_D_W113", direction = 1)
  ),
  deportation_policy_support = list(
    `2010` = list(var = "qn48", direction = 1),   # From our exploration
    `2021` = list(var = "IMMVAL_b_W86", direction = 1),
    `2022` = list(var = "IMMVAL_B_W113", direction = 1)
  ),
  immigration_importance = list(
    `2010` = list(var = "qn23e", direction = 1),  # From our exploration
    `2011` = list(var = "qn22d", direction = 1),  # From our exploration
    `2012` = list(var = "qn21d", direction = 1),  # From our exploration
    `2016` = list(var = "qn20d", direction = 1)   # From our exploration
  ),
  # ----- Index 3: Deportation Concern -----
  deportation_worry = list(
    `2007` = list(var = "qn33", direction = 1),
    `2010` = list(var = "qn32", direction = 1),   # From our exploration
    `2018` = list(var = "qn24", direction = 1),
    `2021` = list(var = "WORRYDPORT_W86", direction = 1)
  )
)

# ============================================================================
# 2. HELPER FUNCTIONS
# ============================================================================
cat("2. Setting up helper functions...\n")

clean_values <- function(x) {
  missing_codes <- c(8, 9, 98, 99, -1, 999, -999, "8", "9", "98", "99")
  x[x %in% missing_codes] <- NA
  as.numeric(x)
}

standardize_z <- function(x) {
  if(length(na.omit(x)) < 2) return(rep(NA_real_, length(x)))
  (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
}

apply_direction <- function(x, direction) {
  if(direction == -1) {
    # Reverse coding
    if(is.numeric(x)) {
      max_val <- max(x, na.rm = TRUE)
      min_val <- min(x, na.rm = TRUE)
      return((max_val + min_val) - x)
    }
  }
  return(x)
}

# ============================================================================
# 3. CORRECTED FILE PATHS (matching actual files in data/raw)
# ============================================================================
cat("3. Setting up corrected file paths...\n")

# CORRECTED paths that match the actual files in data/raw
all_survey_files <- list(
  "2002"="data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004"="data/raw/2004 Political Survey Rev 1-6-05.sav", 
  "2006"="data/raw/f1171_050207 uploaded dataset.sav",
  "2007"="data/raw/publicreleaseNSL07_UPDATED_3.7.22.sav",
  "2008"="data/raw/PHCNSL2008aPublicRelease_UPDATED 3.7.22.sav",
  "2009"="data/raw/PHCNSL2009PublicRelease.sav",
  "2010"="data/raw/PHCNSL2010PublicRelease_UPDATED 3.7.22.sav",
  "2011"="data/raw/PHCNSL2011PubRelease_UPDATED 3.7.22.sav",
  "2012"="data/raw/PHCNSL2012PublicRelease_UPDATED 3.7.22.sav",
  "2014"="data/raw/NSL2014_FOR RELEASE.sav",   # Corrected filename
  "2015"="data/raw/NSL2015_FOR RELEASE.sav",
  "2016"="data/raw/NSL 2016_FOR RELEASE.sav",
  "2018"="data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav",
  "2021"="data/raw/2021 ATP W86.sav",
  "2022"="data/raw/NSL 2022 complete dataset national survey of latinos 2022.dta",
  "2023"="data/raw/2023ATP W138.sav"   # Adding 2023 as well
)

# ============================================================================
# 4. COMPREHENSIVE DATA HARMONIZATION WITH BETTER ERROR HANDLING
# ============================================================================
cat("4. Running comprehensive harmonization with corrected paths...\n")

# Run harmonization with better error handling and progress tracking
harmonized_data_v2_1_fixed <- map_df(names(all_survey_files), function(year) {
  file_path <- all_survey_files[[year]]
  
  if (!file.exists(file_path)) {
    cat("  ", year, ": File not found -", file_path, "\n")
    return(NULL)
  }
  
  cat("  Processing", year, "...")
  
  # Read data with better error handling
  tryCatch({
    raw_data <- if (grepl("\\.sav$", file_path)) {
      read_sav(file_path, encoding = "latin1")  # Try latin1 encoding for problematic files
    } else {
      read_dta(file_path)
    }
    cat(" [", nrow(raw_data), "rows]")
    
    # Initialize the output dataframe
    df <- tibble(
      survey_year = as.integer(year),
      respondent_id = 1:nrow(raw_data)
    )
    
    # Extract each measure
    variables_extracted <- 0
    for (measure_name in names(expanded_variable_map)) {
      measure_map <- expanded_variable_map[[measure_name]]
      
      if (year %in% names(measure_map)) {
        var_info <- measure_map[[year]]
        var_name <- var_info$var
        direction <- var_info$direction
        
        if (var_name %in% names(raw_data)) {
          raw_values <- clean_values(raw_data[[var_name]])
          df[[measure_name]] <- apply_direction(raw_values, direction)
          variables_extracted <- variables_extracted + 1
        } else {
          df[[measure_name]] <- NA_real_
        }
      } else {
        df[[measure_name]] <- NA_real_
      }
    }
    
    # Add demographics and weights
    gen_var <- names(raw_data)[str_detect(names(raw_data), "immgen|GEN1TO4|generations")]
    if (length(gen_var) > 0) {
      df$immigrant_generation <- clean_values(raw_data[[gen_var[1]]])
    } else {
      df$immigrant_generation <- NA_integer_
    }
    
    wt_var <- names(raw_data)[str_detect(tolower(names(raw_data)), "weight|wt")]
    if(length(wt_var) > 0) {
      df$survey_weight <- as.numeric(raw_data[[wt_var[1]]])
    } else {
      df$survey_weight <- 1
    }
    
    cat(" [", variables_extracted, "vars extracted]\n")
    return(df)
    
  }, error = function(e) {
    cat(" ERROR:", e$message, "\n")
    return(NULL)
  })
})

# ============================================================================
# 5. CREATE INDICES WITH FULL DATA
# ============================================================================
cat("5. Creating indices with standardization...\n")

# Standardize variables within each year
standardized_data_v2_1_fixed <- harmonized_data_v2_1_fixed %>%
  group_by(survey_year) %>%
  mutate(
    across(all_of(names(expanded_variable_map)), standardize_z, .names = "{.col}_z")
  ) %>%
  ungroup()

# Create the three thematic indices
final_data_v2_1_fixed <- standardized_data_v2_1_fixed %>%
  rowwise() %>%
  mutate(
    liberalism_index_v2_1 = mean(c_across(any_of(c(
      "legalization_support_z", "daca_support_z", "immigrants_strengthen_z"
    ))), na.rm = TRUE),
    
    restrictionism_index_v2_1 = mean(c_across(any_of(c(
      "immigration_level_opinion_z", "border_wall_support_z", 
      "deportation_policy_support_z", "border_security_support_z", 
      "immigration_importance_z"
    ))), na.rm = TRUE),
    
    concern_index_v2_1 = mean(c_across(any_of(c(
      "deportation_worry_z"
    ))), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    across(c(liberalism_index_v2_1, restrictionism_index_v2_1, concern_index_v2_1), 
           ~ifelse(is.nan(.x), NA, .x))
  ) %>%
  select(survey_year, respondent_id, immigrant_generation, survey_weight, 
         liberalism_index_v2_1, restrictionism_index_v2_1, concern_index_v2_1)

# ============================================================================
# 6. DATA COVERAGE SUMMARY
# ============================================================================
cat("6. Summarizing data coverage...\n")

coverage_summary_fixed <- final_data_v2_1_fixed %>%
  filter(immigrant_generation %in% c(1, 2, 3)) %>%
  group_by(survey_year) %>%
  summarise(
    n_respondents = n(),
    liberalism_data = sum(!is.na(liberalism_index_v2_1)),
    restrictionism_data = sum(!is.na(restrictionism_index_v2_1)),
    concern_data = sum(!is.na(concern_index_v2_1)),
    .groups = "drop"
  ) %>%
  mutate(
    liberalism_coverage = liberalism_data > 0,
    restrictionism_coverage = restrictionism_data > 0,
    concern_coverage = concern_data > 0
  )

cat("\n=== DATA COVERAGE SUMMARY v2.1 FIXED ===\n")
print(coverage_summary_fixed)

# ============================================================================
# 7. SAVE RESULTS WITH v2.1 FIXED VERSIONING
# ============================================================================
cat("7. Saving results with v2.1 fixed versioning...\n")

write_csv(final_data_v2_1_fixed, "data/final/longitudinal_survey_data_v2_1_fixed.csv")
write_csv(coverage_summary_fixed, "outputs/summaries/data_coverage_summary_v2_1_fixed.csv")

cat("\n=== ANALYSIS v2.1 FIXED COMPLETE ===\n")
cat("Data points by index:\n")
cat("- Liberalism:", sum(coverage_summary_fixed$liberalism_coverage), "years\n")
cat("- Restrictionism:", sum(coverage_summary_fixed$restrictionism_coverage), "years\n") 
cat("- Concern:", sum(coverage_summary_fixed$concern_coverage), "years\n")
cat("\nFiles saved with v2_1_fixed versioning.\n")
cat("\nTotal survey years processed:", nrow(coverage_summary_fixed), "\n")