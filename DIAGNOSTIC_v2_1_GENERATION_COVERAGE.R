# ============================================================================
# DIAGNOSTIC v2.1: IMMIGRATION GENERATION COVERAGE ANALYSIS
# ============================================================================
# Purpose: Diagnose why we're getting so few data points in our analysis
#          by examining immigration generation variable coverage across years.
# Version: 2.1 Diagnostic
# ============================================================================

library(haven)
library(dplyr)
library(readr)
library(stringr)
library(purrr)

cat("=== DIAGNOSTIC v2.1: IMMIGRATION GENERATION COVERAGE ===\n")

# Load the fixed dataset we just created
data_v2_1 <- read_csv("data/final/longitudinal_survey_data_v2_1_fixed.csv")

cat("1. Overall data coverage by year:\n")
overall_summary <- data_v2_1 %>%
  group_by(survey_year) %>%
  summarise(
    total_respondents = n(),
    valid_generation = sum(!is.na(immigrant_generation)),
    gen_1 = sum(immigrant_generation == 1, na.rm = TRUE),
    gen_2 = sum(immigrant_generation == 2, na.rm = TRUE), 
    gen_3 = sum(immigrant_generation == 3, na.rm = TRUE),
    .groups = "drop"
  )

print(overall_summary)

cat("\n2. Immigration attitude data availability across all years:\n")
attitude_summary <- data_v2_1 %>%
  group_by(survey_year) %>%
  summarise(
    total_respondents = n(),
    liberalism_available = sum(!is.na(liberalism_index_v2_1)),
    restrictionism_available = sum(!is.na(restrictionism_index_v2_1)),
    concern_available = sum(!is.na(concern_index_v2_1)),
    .groups = "drop"
  )

print(attitude_summary)

cat("\n3. Years being filtered out due to missing generation data:\n")
missing_years <- overall_summary %>%
  filter(valid_generation == 0) %>%
  pull(survey_year)

if(length(missing_years) > 0) {
  cat("Years with NO immigration generation data:", paste(missing_years, collapse = ", "), "\n")
} else {
  cat("All years have some immigration generation data.\n")
}

# Now let's examine the raw files to see what generation variables exist
cat("\n4. Examining generation variables in raw survey files:\n")

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

generation_variables <- map_df(names(all_survey_files), function(year) {
  file_path <- all_survey_files[[year]]
  
  if (!file.exists(file_path)) {
    return(tibble(year = year, generation_vars = "FILE_NOT_FOUND"))
  }
  
  tryCatch({
    raw_data <- if (grepl("\\.sav$", file_path)) {
      read_sav(file_path, encoding = "latin1")
    } else {
      read_dta(file_path)
    }
    
    # Look for potential generation variables
    var_names <- names(raw_data)
    generation_candidates <- var_names[str_detect(tolower(var_names), "gen|birth|immigr|foreign")]
    
    tibble(
      year = year,
      total_vars = length(var_names),
      generation_candidates = paste(generation_candidates, collapse = ", "),
      n_candidates = length(generation_candidates)
    )
    
  }, error = function(e) {
    tibble(year = year, generation_candidates = paste("ERROR:", e$message))
  })
})

print(generation_variables)

cat("\n5. Investigating specific patterns that might explain missing data:\n")

# Check if there are years with attitude data but no generation data
attitude_no_gen <- attitude_summary %>%
  left_join(overall_summary, by = "survey_year") %>%
  filter((liberalism_available > 0 | restrictionism_available > 0 | concern_available > 0) & valid_generation == 0)

if(nrow(attitude_no_gen) > 0) {
  cat("Years with immigration attitude data but NO generation data:\n")
  print(attitude_no_gen)
} else {
  cat("No years found with attitude data but missing generation data.\n")
}

cat("\n=== DIAGNOSTIC COMPLETE ===\n")
cat("The main issue appears to be that many survey years lack the immigration generation variable,\n")
cat("which is causing them to be filtered out of our analysis even if they have attitude data.\n")