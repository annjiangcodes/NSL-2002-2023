# =============================================================================
# VARIABLE EXTRACTION FOR 2014-2023 SURVEY EXTENSION
# =============================================================================
# Purpose: Extract and analyze variables from 2014-2023 survey files
# Handles: NSL format (2014-2018) and ATP format (2021-2023)
# Author: Survey Harmonization Extension Project
# =============================================================================

library(haven)
library(dplyr)
library(stringr)
library(readr)
library(purrr)

# Set up logging
cat("=== VARIABLE EXTRACTION FOR 2014-2023 EXTENSION ===\n")
cat("Starting at:", as.character(Sys.time()), "\n\n")

# =============================================================================
# ENHANCED EXTRACTION FUNCTION WITH ERROR HANDLING
# =============================================================================

extract_variables_robust <- function(file_path, year, survey_type = "NSL") {
  cat("Processing:", basename(file_path), "(", year, ")\n")
  
  tryCatch({
    # Try multiple encoding approaches for problematic files
    data <- NULL
    
    # Method 1: Standard haven
    try({
      data <- read_sav(file_path)
    }, silent = TRUE)
    
    # Method 2: Force encoding if standard fails
    if (is.null(data)) {
      try({
        data <- read_sav(file_path, encoding = "latin1")
      }, silent = TRUE)
    }
    
    # Method 3: Alternative encoding
    if (is.null(data)) {
      try({
        data <- read_sav(file_path, encoding = "UTF-8")
      }, silent = TRUE)
    }
    
    if (is.null(data)) {
      cat("  ERROR: Could not read file with any encoding method\n")
      return(NULL)
    }
    
    cat("  Successfully loaded:", nrow(data), "observations,", ncol(data), "variables\n")
    
    # Extract variable information
    variables_info <- tibble(
      year = year,
      survey_type = survey_type,
      file_name = basename(file_path),
      variable_name = names(data),
      variable_label = map_chr(names(data), ~ {
        label <- attr(data[[.x]], "label")
        if (is.null(label)) "" else as.character(label)
      }),
      variable_type = map_chr(names(data), ~ class(data[[.x]])[1]),
      unique_values = map_int(names(data), ~ length(unique(data[[.x]], na.rm = TRUE))),
      missing_count = map_int(names(data), ~ sum(is.na(data[[.x]]))),
      total_obs = nrow(data)
    )
    
    # Add concept matching flags
    variables_info <- variables_info %>%
      mutate(
        # Demographic concepts
        is_age = str_detect(tolower(paste(variable_name, variable_label)), 
                           "age|birth|year"),
        is_gender = str_detect(tolower(paste(variable_name, variable_label)), 
                              "gender|sex|male|female"),
        is_race = str_detect(tolower(paste(variable_name, variable_label)), 
                            "race|racial|white|black|asian|hispanic"),
        is_ethnicity = str_detect(tolower(paste(variable_name, variable_label)), 
                                 "ethnic|hispanic|latino|mexican|puerto|cuban"),
        is_language = str_detect(tolower(paste(variable_name, variable_label)), 
                                "language|english|spanish|interview"),
        is_citizenship = str_detect(tolower(paste(variable_name, variable_label)), 
                                   "citizen|citizenship|legal|status"),
        is_nativity = str_detect(tolower(paste(variable_name, variable_label)), 
                                "born|birth|place|country|nativity"),
        is_generation = str_detect(tolower(paste(variable_name, variable_label)), 
                                  "generation|first|second|third"),
        
        # Political concepts
        is_political = str_detect(tolower(paste(variable_name, variable_label)), 
                                 "politic|party|vote|election|democrat|republican"),
        is_immigration = str_detect(tolower(paste(variable_name, variable_label)), 
                                   "immigr|border|undocument|illegal|amnesty|daca"),
        is_approval = str_detect(tolower(paste(variable_name, variable_label)), 
                                "approve|approval|president|job"),
        
        # Summary concept flags
        concept_count = rowSums(select(., starts_with("is_")), na.rm = TRUE)
      )
    
    cat("  Found", nrow(variables_info), "variables\n")
    cat("  Demographic matches:", sum(variables_info$is_age | variables_info$is_gender | 
                                     variables_info$is_race | variables_info$is_ethnicity), "\n")
    cat("  Political matches:", sum(variables_info$is_political | variables_info$is_immigration), "\n\n")
    
    return(variables_info)
    
  }, error = function(e) {
    cat("  CRITICAL ERROR:", e$message, "\n\n")
    return(NULL)
  })
}

# =============================================================================
# SURVEY FILE MAPPING FOR 2014-2023
# =============================================================================

survey_files_2014_2023 <- list(
  "2014" = list(
    file = "data/raw/NSL2014_FOR RELEASE.sav",
    type = "NSL"
  ),
  "2015" = list(
    file = "data/raw/NSL2015_FOR RELEASE.sav", 
    type = "NSL"
  ),
  "2016" = list(
    file = "data/raw/NSL 2016_FOR RELEASE.sav",
    type = "NSL" 
  ),
  "2018" = list(
    file = "data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav",
    type = "NSL"
  ),
  "2021" = list(
    file = "data/raw/2021 ATP W86.sav",
    type = "ATP"
  ),
  "2023" = list(
    file = "data/raw/2023ATP W138.sav", 
    type = "ATP"
  )
)

# =============================================================================
# EXECUTE EXTRACTION FOR ALL AVAILABLE YEARS
# =============================================================================

cat("Starting variable extraction for", length(survey_files_2014_2023), "survey years...\n\n")

all_variables_2014_2023 <- map2_dfr(
  names(survey_files_2014_2023),
  survey_files_2014_2023,
  ~ {
    if (file.exists(.y$file)) {
      extract_variables_robust(.y$file, .x, .y$type)
    } else {
      cat("WARNING: File not found:", .y$file, "\n")
      NULL
    }
  }
)

# =============================================================================
# DETAILED ANALYSIS AND REPORTING
# =============================================================================

if (nrow(all_variables_2014_2023) > 0) {
  
  cat("=== EXTRACTION SUMMARY ===\n")
  
  # Overall summary
  summary_by_year <- all_variables_2014_2023 %>%
    group_by(year, survey_type) %>%
    summarise(
      total_variables = n(),
      demographic_vars = sum(is_age | is_gender | is_race | is_ethnicity | 
                            is_language | is_citizenship | is_nativity | is_generation),
      political_vars = sum(is_political | is_immigration | is_approval),
      total_obs = first(total_obs),
      .groups = 'drop'
    )
  
  print(summary_by_year)
  
  cat("\n=== CONCEPT ANALYSIS BY YEAR ===\n")
  
  # Concept availability by year
  concept_summary <- all_variables_2014_2023 %>%
    group_by(year) %>%
    summarise(
      age_vars = sum(is_age),
      gender_vars = sum(is_gender), 
      race_vars = sum(is_race),
      ethnicity_vars = sum(is_ethnicity),
      language_vars = sum(is_language),
      citizenship_vars = sum(is_citizenship),
      political_vars = sum(is_political),
      immigration_vars = sum(is_immigration),
      .groups = 'drop'
    )
  
  print(concept_summary)
  
  cat("\n=== KEY DEMOGRAPHIC VARIABLES BY YEAR ===\n")
  
  # Show key demographic variables for each year
  for (yr in unique(all_variables_2014_2023$year)) {
    cat("\n", yr, ":\n")
    
    yr_data <- all_variables_2014_2023 %>% filter(year == yr)
    
    # Age variables
    age_vars <- yr_data %>% 
      filter(is_age) %>% 
      select(variable_name, variable_label) %>%
      slice_head(n = 3)
    if (nrow(age_vars) > 0) {
      cat("  AGE:", paste(age_vars$variable_name, collapse = ", "), "\n")
    }
    
    # Gender variables
    gender_vars <- yr_data %>% 
      filter(is_gender) %>% 
      select(variable_name, variable_label) %>%
      slice_head(n = 3)
    if (nrow(gender_vars) > 0) {
      cat("  GENDER:", paste(gender_vars$variable_name, collapse = ", "), "\n")
    }
    
    # Race variables 
    race_vars <- yr_data %>% 
      filter(is_race) %>% 
      select(variable_name, variable_label) %>%
      slice_head(n = 3)
    if (nrow(race_vars) > 0) {
      cat("  RACE:", paste(race_vars$variable_name, collapse = ", "), "\n")
    }
    
    # Language variables
    lang_vars <- yr_data %>% 
      filter(is_language) %>% 
      select(variable_name, variable_label) %>%
      slice_head(n = 3)
    if (nrow(lang_vars) > 0) {
      cat("  LANGUAGE:", paste(lang_vars$variable_name, collapse = ", "), "\n")
    }
  }
  
  # =============================================================================
  # SAVE RESULTS
  # =============================================================================
  
  # Save comprehensive extraction results
  write_csv(all_variables_2014_2023, "outputs/summaries/all_variables_2014_2023.csv")
  write_csv(summary_by_year, "outputs/summaries/extraction_summary_2014_2023.csv")
  write_csv(concept_summary, "outputs/summaries/concept_analysis_2014_2023.csv")
  
  cat("\n=== RESULTS SAVED ===\n")
  cat("✅ all_variables_2014_2023.csv (", nrow(all_variables_2014_2023), "variables)\n")
  cat("✅ extraction_summary_2014_2023.csv\n") 
  cat("✅ concept_analysis_2014_2023.csv\n")
  
  # Show critical variables for harmonization planning
  cat("\n=== CRITICAL VARIABLES FOR HARMONIZATION ===\n")
  
  critical_vars <- all_variables_2014_2023 %>%
    filter(concept_count > 0) %>%
    arrange(year, desc(concept_count)) %>%
    select(year, variable_name, variable_label, concept_count, 
           is_age, is_gender, is_race, is_ethnicity, is_language)
  
  write_csv(critical_vars, "outputs/summaries/critical_variables_2014_2023.csv")
  cat("✅ critical_variables_2014_2023.csv (", nrow(critical_vars), "variables)\n")
  
} else {
  cat("ERROR: No variables extracted. Check file paths and encoding issues.\n")
}

cat("\n=== VARIABLE EXTRACTION COMPLETE ===\n")
cat("Completed at:", as.character(Sys.time()), "\n")