# ============================================================================
# ANALYSIS v2.2: COMPLETE GENERATION VARIABLE FIX
# ============================================================================
# Purpose: Fix the generation variable extraction to properly capture all
#          the different generation variable names across survey years.
#          This should dramatically increase our data coverage.
# Version: 2.2
# Date: Current analysis session
# Previous Issues: v2.1 missed generation variables due to restrictive pattern
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

cat("=== ANALYSIS v2.2: COMPLETE GENERATION VARIABLE FIX ===\n")

# ============================================================================
# 1. DEFINE EXPANDED VARIABLE MAP (same as before)
# ============================================================================
cat("1. Defining expanded variable map...\n")

expanded_variable_map <- list(
  # ----- Index 1: Immigration Policy Liberalism -----
  legalization_support = list(
    `2002` = list(var = "QN26", direction = 1),
    `2004` = list(var = "QN40", direction = 1), 
    `2006` = list(var = "qn13", direction = 1),
    `2010` = list(var = "qn42", direction = 1),  
    `2014` = list(var = "Q36", direction = 1),   
    `2021` = list(var = "IMMVAL_c_W86", direction = -1),
    `2022` = list(var = "IMMVAL_C_W113", direction = -1)
  ),
  daca_support = list(
    `2011` = list(var = "qn24", direction = 1),  
    `2012` = list(var = "qn31", direction = 1),  
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
    `2010` = list(var = "qn49c", direction = -1), 
    `2018` = list(var = "qn29", direction = -1)
  ),
  border_security_support = list(
    `2010` = list(var = "qn49d", direction = 1),  
    `2021` = list(var = "IMMVAL_d_W86", direction = 1),
    `2022` = list(var = "IMMVAL_D_W113", direction = 1)
  ),
  deportation_policy_support = list(
    `2010` = list(var = "qn48", direction = 1),   
    `2021` = list(var = "IMMVAL_b_W86", direction = 1),
    `2022` = list(var = "IMMVAL_B_W113", direction = 1)
  ),
  immigration_importance = list(
    `2010` = list(var = "qn23e", direction = 1),  
    `2011` = list(var = "qn22d", direction = 1),  
    `2012` = list(var = "qn21d", direction = 1),  
    `2016` = list(var = "qn20d", direction = 1)   
  ),
  # ----- Index 3: Deportation Concern -----
  deportation_worry = list(
    `2007` = list(var = "qn33", direction = 1),
    `2010` = list(var = "qn32", direction = 1),   
    `2018` = list(var = "qn24", direction = 1),
    `2021` = list(var = "WORRYDPORT_W86", direction = 1)
  )
)

# ============================================================================
# 2. COMPREHENSIVE GENERATION VARIABLE MAPPING
# ============================================================================
cat("2. Setting up comprehensive generation variable mapping...\n")

# Based on our diagnostic, here are the actual generation variable names:
generation_variable_map <- list(
  "2002" = "GEN1TO4",           # Found: GEN1TO4, GEN1TO2, GEN1_3
  "2004" = NULL,                # No generation variable found
  "2006" = NULL,                # No generation variable found  
  "2007" = NULL,                # No generation variable found
  "2008" = NULL,                # No generation variable found
  "2009" = NULL,                # No generation variable found (gender is not generation)
  "2010" = NULL,                # No generation variable found
  "2011" = NULL,                # No generation variable found
  "2012" = NULL,                # No generation variable found
  "2014" = NULL,                # No generation variable found
  "2015" = "immgen",            # Found: immgen, immgen1
  "2016" = "generations",       # Found: generations
  "2018" = "immgen",            # Found: immgen
  "2021" = "IMMGEN_W86",        # Found in candidates list
  "2022" = "SPANGEN_W113",      # Found in candidates list
  "2023" = NULL                 # Need to check specific variable names
)

# ============================================================================
# 3. HELPER FUNCTIONS (same as before)
# ============================================================================
cat("3. Setting up helper functions...\n")

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
    if(is.numeric(x)) {
      max_val <- max(x, na.rm = TRUE)
      min_val <- min(x, na.rm = TRUE)
      return((max_val + min_val) - x)
    }
  }
  return(x)
}

# ============================================================================
# 4. CORRECTED FILE PATHS AND COMPREHENSIVE HARMONIZATION
# ============================================================================
cat("4. Running comprehensive harmonization with proper generation variables...\n")

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
  "2014"="data/raw/NSL2014_FOR RELEASE.sav",
  "2015"="data/raw/NSL2015_FOR RELEASE.sav",
  "2016"="data/raw/NSL 2016_FOR RELEASE.sav",
  "2018"="data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav",
  "2021"="data/raw/2021 ATP W86.sav",
  "2022"="data/raw/NSL 2022 complete dataset national survey of latinos 2022.dta",
  "2023"="data/raw/2023ATP W138.sav"
)

# Run harmonization with PROPER generation variable extraction
harmonized_data_v2_2 <- map_df(names(all_survey_files), function(year) {
  file_path <- all_survey_files[[year]]
  
  if (!file.exists(file_path)) {
    cat("  ", year, ": File not found\n")
    return(NULL)
  }
  
  cat("  Processing", year, "...")
  
  tryCatch({
    raw_data <- if (grepl("\\.sav$", file_path)) {
      read_sav(file_path, encoding = "latin1")
    } else {
      read_dta(file_path)
    }
    cat(" [", nrow(raw_data), "rows]")
    
    # Initialize dataframe
    df <- tibble(
      survey_year = as.integer(year),
      respondent_id = 1:nrow(raw_data)
    )
    
    # Extract immigration attitude measures
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
    
    # PROPERLY extract generation variable using our mapping
    gen_var_name <- generation_variable_map[[year]]
    if (!is.null(gen_var_name) && gen_var_name %in% names(raw_data)) {
      df$immigrant_generation <- clean_values(raw_data[[gen_var_name]])
      cat(" [GEN: ", gen_var_name, "]")
    } else {
      df$immigrant_generation <- NA_integer_
      cat(" [NO GEN]")
    }
    
    # Extract weights
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
# 5. CREATE INDICES (same as before)
# ============================================================================
cat("5. Creating indices with standardization...\n")

standardized_data_v2_2 <- harmonized_data_v2_2 %>%
  group_by(survey_year) %>%
  mutate(
    across(all_of(names(expanded_variable_map)), standardize_z, .names = "{.col}_z")
  ) %>%
  ungroup()

final_data_v2_2 <- standardized_data_v2_2 %>%
  rowwise() %>%
  mutate(
    liberalism_index_v2_2 = mean(c_across(any_of(c(
      "legalization_support_z", "daca_support_z", "immigrants_strengthen_z"
    ))), na.rm = TRUE),
    
    restrictionism_index_v2_2 = mean(c_across(any_of(c(
      "immigration_level_opinion_z", "border_wall_support_z", 
      "deportation_policy_support_z", "border_security_support_z", 
      "immigration_importance_z"
    ))), na.rm = TRUE),
    
    concern_index_v2_2 = mean(c_across(any_of(c(
      "deportation_worry_z"
    ))), na.rm = TRUE)
  ) %>%
  ungroup() %>%
  mutate(
    across(c(liberalism_index_v2_2, restrictionism_index_v2_2, concern_index_v2_2), 
           ~ifelse(is.nan(.x), NA, .x))
  ) %>%
  select(survey_year, respondent_id, immigrant_generation, survey_weight, 
         liberalism_index_v2_2, restrictionism_index_v2_2, concern_index_v2_2)

# ============================================================================
# 6. COMPREHENSIVE DATA COVERAGE SUMMARY
# ============================================================================
cat("6. Summarizing COMPLETE data coverage...\n")

# Show coverage for ALL respondents (not just those with generation data)
all_coverage_summary <- final_data_v2_2 %>%
  group_by(survey_year) %>%
  summarise(
    total_respondents = n(),
    valid_generation = sum(!is.na(immigrant_generation)),
    gen_1 = sum(immigrant_generation == 1, na.rm = TRUE),
    gen_2 = sum(immigrant_generation == 2, na.rm = TRUE),
    gen_3 = sum(immigrant_generation == 3, na.rm = TRUE),
    liberalism_data = sum(!is.na(liberalism_index_v2_2)),
    restrictionism_data = sum(!is.na(restrictionism_index_v2_2)),
    concern_data = sum(!is.na(concern_index_v2_2)),
    .groups = "drop"
  ) %>%
  mutate(
    has_generation = valid_generation > 0,
    has_liberalism = liberalism_data > 0,
    has_restrictionism = restrictionism_data > 0,
    has_concern = concern_data > 0
  )

cat("\n=== COMPLETE DATA COVERAGE SUMMARY v2.2 ===\n")
print(all_coverage_summary)

# Show filtered coverage (only respondents with generation data)
filtered_coverage_summary <- final_data_v2_2 %>%
  filter(immigrant_generation %in% c(1, 2, 3)) %>%
  group_by(survey_year) %>%
  summarise(
    n_respondents = n(),
    liberalism_data = sum(!is.na(liberalism_index_v2_2)),
    restrictionism_data = sum(!is.na(restrictionism_index_v2_2)),
    concern_data = sum(!is.na(concern_index_v2_2)),
    .groups = "drop"
  ) %>%
  mutate(
    liberalism_coverage = liberalism_data > 0,
    restrictionism_coverage = restrictionism_data > 0,
    concern_coverage = concern_data > 0
  )

cat("\n=== FILTERED COVERAGE (Generation 1-3 only) ===\n")
print(filtered_coverage_summary)

# ============================================================================
# 7. SAVE RESULTS
# ============================================================================
cat("7. Saving results with v2.2 versioning...\n")

write_csv(final_data_v2_2, "data/final/longitudinal_survey_data_v2_2.csv")
write_csv(all_coverage_summary, "outputs/summaries/complete_coverage_summary_v2_2.csv")
write_csv(filtered_coverage_summary, "outputs/summaries/filtered_coverage_summary_v2_2.csv")

cat("\n=== ANALYSIS v2.2 COMPLETE ===\n")
cat("COMPLETE data points by index (all respondents):\n")
cat("- Liberalism:", sum(all_coverage_summary$has_liberalism), "years\n")
cat("- Restrictionism:", sum(all_coverage_summary$has_restrictionism), "years\n") 
cat("- Concern:", sum(all_coverage_summary$has_concern), "years\n")
cat("\nFILTERED data points by index (generation 1-3 only):\n")
cat("- Liberalism:", sum(filtered_coverage_summary$liberalism_coverage), "years\n")
cat("- Restrictionism:", sum(filtered_coverage_summary$restrictionism_coverage), "years\n") 
cat("- Concern:", sum(filtered_coverage_summary$concern_coverage), "years\n")
cat("\nTotal survey years processed:", nrow(all_coverage_summary), "\n")