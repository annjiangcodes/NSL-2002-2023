# ============================================================================
# ANALYSIS v2.0: DATA INVESTIGATION AND DIAGNOSTIC
# ============================================================================
# Purpose: Investigate why our latest analysis has fewer data points than 
#          expected. Compare what variables we should have vs. what we got.
# Version: 2.0
# Date: Current analysis session
# ============================================================================

library(haven)
library(dplyr)
library(readr)
library(stringr)
library(purrr)

cat("=== ANALYSIS v2.0: DATA INVESTIGATION ===\n")

# ============================================================================
# 1. DEFINE WHAT WE SHOULD HAVE (based on our exploration)
# ============================================================================
cat("1. Defining expected data coverage...\n")

# From our previous exploration, these are the years we found relevant variables in:
expected_coverage <- list(
  liberalism_variables = list(
    legalization_support = c("2002", "2004", "2006", "2010", "2014", "2021", "2022"),
    daca_support = c("2011", "2012", "2018", "2021"),
    immigrants_strengthen = c("2006")
  ),
  restrictionism_variables = list(
    immigration_level_opinion = c("2002", "2007", "2018"),
    border_wall_support = c("2010", "2018"),
    border_security_support = c("2010", "2021", "2022"),
    deportation_policy_support = c("2010", "2021", "2022"),
    immigration_importance = c("2010", "2011", "2012", "2016")
  ),
  concern_variables = list(
    deportation_worry = c("2007", "2010", "2018", "2021")
  )
)

# ============================================================================
# 2. CHECK WHICH FILES ACTUALLY EXIST
# ============================================================================
cat("2. Checking file availability...\n")

all_survey_files <- list(
  "2002"="data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004"="data/raw/2004 Political Survey Rev 1-6-05.sav",
  "2006"="data/raw/f1171_050207 uploaded dataset.sav",
  "2007"="data/raw/publicreleaseNSL07_UPDATED_3.7.22.sav",
  "2010"="data/raw/PHCNSL2010PublicRelease_UPDATED 3.7.22.sav",
  "2011"="data/raw/PHCNSL2011PubRelease_UPDATED 3.7.22.sav",
  "2012"="data/raw/PHCNSL2012PublicRelease_UPDATED 3.7.22.sav",
  "2014"="data/raw/Pew National Survey of Latinos, 2014.dta",
  "2016"="data/raw/NSL 2016_FOR RELEASE.sav",
  "2018"="data/raw/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav",
  "2021"="data/raw/2021 ATP W86.sav",
  "2022"="data/raw/NSL 2022 complete dataset national survey of latinos 2022.dta"
)

file_status <- map_df(names(all_survey_files), function(year) {
  file_path <- all_survey_files[[year]]
  exists <- file.exists(file_path)
  tibble(year = year, file_path = file_path, file_exists = exists)
})

cat("File availability summary:\n")
print(file_status)

# ============================================================================
# 3. TEST VARIABLE EXTRACTION FOR KEY YEARS
# ============================================================================
cat("\n3. Testing variable extraction for key years...\n")

# Define the variable map we used in our latest analysis
definitive_map <- list(
  legalization_support = list(
    `2002`="QN26", `2004`="QN40", `2006`="qn13", `2010`="qn42", `2014`="Q36",
    `2021`="IMMVAL_c_W86", `2022`="IMMVAL_C_W113"
  ),
  daca_support = list(
    `2011`="qn24", `2012`="qn31", `2018`="qn28", `2021`="IMMVAL_i_W86"
  ),
  immigrants_strengthen = list(
    `2006`="qn20"
  ),
  immigration_level_opinion = list(
    `2002`="QN23", `2007`="qn24", `2018`="qn31"
  ),
  border_wall_support = list(
    `2010`="qn49c", `2018`="qn29"
  ),
  border_security_support = list(
    `2010`="qn49d", `2021`="IMMVAL_d_W86", `2022`="IMMVAL_D_W113"
  ),
  deportation_policy_support = list(
    `2010`="qn48", `2021`="IMMVAL_b_W86", `2022`="IMMVAL_B_W113"
  ),
  immigration_importance = list(
    `2010`="qn23e", `2011`="qn22d", `2012`="qn21d", `2016`="qn20d"
  ),
  deportation_worry = list(
    `2007`="qn33", `2010`="qn32", `2018`="qn24", `2021`="WORRYDPORT_W86"
  )
)

# Test extraction for each year
extraction_results <- map_df(names(all_survey_files), function(year) {
  file_path <- all_survey_files[[year]]
  if (!file.exists(file_path)) {
    return(tibble(year = year, status = "file_not_found", variables_found = 0, total_expected = 0))
  }
  
  cat("  Testing", year, "...\n")
  
  # Try to read the file
  tryCatch({
    raw_data <- if (grepl("\\.sav$", file_path)) read_sav(file_path) else read_dta(file_path)
    
    # Count expected vs found variables
    expected_vars <- map(definitive_map, function(measure_map) {
      if (year %in% names(measure_map)) measure_map[[year]] else NULL
    }) %>% keep(~!is.null(.x)) %>% unlist()
    
    found_vars <- expected_vars[expected_vars %in% names(raw_data)]
    
    tibble(
      year = year,
      status = "success",
      variables_found = length(found_vars),
      total_expected = length(expected_vars),
      found_vars = paste(found_vars, collapse = ", "),
      missing_vars = paste(setdiff(expected_vars, found_vars), collapse = ", ")
    )
    
  }, error = function(e) {
    tibble(year = year, status = paste("error:", e$message), variables_found = 0, total_expected = 0)
  })
})

cat("\n=== EXTRACTION RESULTS SUMMARY ===\n")
print(extraction_results)

# ============================================================================
# 4. CALCULATE EXPECTED VS ACTUAL DATA COVERAGE
# ============================================================================
cat("\n4. Calculating data coverage by index...\n")

# For each index, calculate which years should have data
index_coverage <- tibble(
  index = character(),
  expected_years = character(),
  years_with_files = character(),
  potential_data_points = integer()
)

# Liberalism index
lib_years <- unique(unlist(map(expected_coverage$liberalism_variables, identity)))
lib_files_exist <- lib_years[lib_years %in% file_status$year[file_status$file_exists]]
index_coverage <- bind_rows(index_coverage, 
  tibble(index = "liberalism", expected_years = paste(lib_years, collapse=","), 
         years_with_files = paste(lib_files_exist, collapse=","), 
         potential_data_points = length(lib_files_exist)))

# Restrictionism index  
rest_years <- unique(unlist(map(expected_coverage$restrictionism_variables, identity)))
rest_files_exist <- rest_years[rest_years %in% file_status$year[file_status$file_exists]]
index_coverage <- bind_rows(index_coverage,
  tibble(index = "restrictionism", expected_years = paste(rest_years, collapse=","),
         years_with_files = paste(rest_files_exist, collapse=","),
         potential_data_points = length(rest_files_exist)))

# Concern index
conc_years <- unique(unlist(map(expected_coverage$concern_variables, identity)))
conc_files_exist <- conc_years[conc_years %in% file_status$year[file_status$file_exists]]
index_coverage <- bind_rows(index_coverage,
  tibble(index = "concern", expected_years = paste(conc_years, collapse=","),
         years_with_files = paste(conc_files_exist, collapse=","),
         potential_data_points = length(conc_files_exist)))

cat("\n=== INDEX COVERAGE SUMMARY ===\n")
print(index_coverage)

# ============================================================================
# 5. SAVE DIAGNOSTIC RESULTS
# ============================================================================
cat("\n5. Saving diagnostic results...\n")

write_csv(file_status, "outputs/summaries/file_availability_v2_0.csv")
write_csv(extraction_results, "outputs/summaries/variable_extraction_test_v2_0.csv") 
write_csv(index_coverage, "outputs/summaries/index_coverage_analysis_v2_0.csv")

cat("\n=== DIAGNOSTIC COMPLETE ===\n")
cat("Results saved to outputs/summaries/ with v2_0 versioning.\n")
cat("Check the CSV files to understand the data coverage issues.\n")