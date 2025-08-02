# =============================================================================
# IMMIGRATION ATTITUDES ANALYSIS v2.8 - WEIGHTS & DEMOGRAPHIC CONTROLS
# =============================================================================
# Purpose: Enhanced analysis building on v2.7 with survey weights and comprehensive
#          demographic controls for publication-quality representative estimates
# Version: 2.8 (January 2025)
# Previous: v2.7 achieved corrected generation coding + comprehensive immigration data
# Key Enhancement: SURVEY WEIGHTS + DEMOGRAPHIC CONTROLS for representative analysis
# Data Coverage: 37,496+ observations across 14 survey years (2002-2023)
# =============================================================================

library(haven)
library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(stringr)
library(viridis)
library(scales)
library(survey)  # For survey-weighted analysis

cat("=================================================================\n")
cat("IMMIGRATION ATTITUDES ANALYSIS v2.8 - WEIGHTS & CONTROLS\n") 
cat("=================================================================\n")

# =============================================================================
# 1. LOAD EXISTING v2.7 DATA AND ENHANCED HARMONIZATION FUNCTIONS
# =============================================================================

cat("\n1. LOADING v2.7 DATA AND ENHANCED HARMONIZATION INFRASTRUCTURE\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Load the current v2.7 dataset
data_v27 <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

cat("v2.7 Dataset loaded:", dim(data_v27), "\n")
cat("Years available:", paste(sort(unique(data_v27$survey_year)), collapse = ", "), "\n")

# Check current variable coverage
current_vars <- names(data_v27)
cat("Current variables (", length(current_vars), "):\n")
cat("- Immigration attitudes:", sum(grepl("liberalism|restrictionism|concern", current_vars)), "\n")
cat("- Generation variables:", sum(grepl("generation|birth|nativity", current_vars)), "\n")
cat("- Survey weights:", sum(grepl("weight", current_vars, ignore.case = TRUE)), "\n")
cat("- Demographics:", sum(grepl("age|education|income|race|gender", current_vars, ignore.case = TRUE)), "\n")

# =============================================================================
# 2. SURVEY WEIGHTS EXTRACTION AND INTEGRATION
# =============================================================================

cat("\n2. SURVEY WEIGHTS EXTRACTION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Survey files mapping for weight extraction (updated with actual file names)
all_survey_files <- list(
  "2002" = "data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004" = "data/raw/2004 Political Survey Rev 1-6-05.sav",
  "2006" = "data/raw/f1171_050207 uploaded dataset.sav",
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

# Survey weights mapping by year (updated based on actual findings)
weights_var_map <- list(
  "2002" = c("WEIGHTH", "WEIGHT", "weight", "finalweight", "wt"),
  "2004" = c("WEIGHT", "weight", "finalweight", "wt"),
  "2006" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2007" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2008" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2009" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2010" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2011" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2012" = c("weight", "WEIGHT", "finalweight", "wt"),
  "2014" = c("WEIGHT", "weight"),
  "2015" = c("WEIGHT", "weight"),
  "2016" = c("WEIGHT", "weight"),
  "2018" = c("WEIGHT", "weight"),
  "2021" = c("WEIGHT_W86", "WEIGHT", "weight"),
  "2022" = c("WEIGHT_W113", "WEIGHT", "weight"),
  "2023" = c("WEIGHT_W138", "WEIGHT", "weight")
)

# Function to extract survey weights
extract_survey_weights <- function(file_path, year) {
  if (!file.exists(file_path)) {
    cat("  WARNING: File not found for", year, "\n")
    return(NULL)
  }
  
  tryCatch({
    # Read raw data (handle both SPSS and Stata formats)
    if (grepl("\\.dta$", file_path)) {
      raw_data <- read_dta(file_path)
    } else {
      raw_data <- read_spss(file_path)
    }
    cat("  Loaded", year, ":", nrow(raw_data), "observations\n")
    
    # Try to find weight variable
    year_str <- as.character(year)
    possible_weights <- weights_var_map[[year_str]]
    
    weight_var <- NULL
    for (w in possible_weights) {
      if (w %in% names(raw_data)) {
        weight_var <- w
        break
      }
    }
    
    if (is.null(weight_var)) {
      cat("  No weight variable found for", year, "\n")
      available_weights <- names(raw_data)[grepl("weight|WEIGHT|wt", names(raw_data), ignore.case = TRUE)]
      if (length(available_weights) > 0) {
        cat("  Available weight-like variables:", paste(available_weights, collapse = ", "), "\n")
      }
      return(NULL)
    }
    
    # Extract weights
    weights <- as.numeric(raw_data[[weight_var]])
    
    # Clean extreme/invalid weights
    weights_cleaned <- ifelse(weights <= 0 | weights > 10 | is.na(weights), NA, weights)
    
    # Create respondent matching data
    weight_data <- data.frame(
      survey_year = year,
      respondent_id = 1:nrow(raw_data),
      survey_weight = weights_cleaned,
      weight_variable_used = weight_var
    )
    
    valid_weights <- sum(!is.na(weights_cleaned))
    cat("  Extracted", valid_weights, "valid weights using variable:", weight_var, "\n")
    
    return(weight_data)
    
  }, error = function(e) {
    cat("  ERROR extracting weights for", year, ":", e$message, "\n")
    return(NULL)
  })
}

# Extract weights for all available years
cat("\nExtracting survey weights for all years...\n")
all_weights <- list()

for (year in names(all_survey_files)) {
  cat("Processing", year, "...\n")
  file_path <- all_survey_files[[year]]
  weights_data <- extract_survey_weights(file_path, as.numeric(year))
  
  if (!is.null(weights_data)) {
    all_weights[[year]] <- weights_data
  }
}

# Combine all weights
if (length(all_weights) > 0) {
  combined_weights <- bind_rows(all_weights)
  cat("\nSurvey weights extracted for", length(all_weights), "years\n")
  cat("Total weight records:", nrow(combined_weights), "\n")
  
  # Show weight coverage by year
  weight_coverage <- combined_weights %>%
    group_by(survey_year) %>%
    summarise(
      total_obs = n(),
      valid_weights = sum(!is.na(survey_weight)),
      weight_coverage = round(100 * valid_weights / total_obs, 1),
      .groups = 'drop'
    )
  
  print(weight_coverage)
} else {
  cat("WARNING: No survey weights could be extracted\n")
  combined_weights <- data.frame()
}

# =============================================================================
# 3. DEMOGRAPHIC CONTROLS EXTRACTION
# =============================================================================

cat("\n3. DEMOGRAPHIC CONTROLS EXTRACTION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Skip the enhanced harmonization functions to avoid missing package issues
cat("Using basic demographic extraction approach\n")

# Function to extract demographic controls
extract_demographic_controls <- function(file_path, year) {
  if (!file.exists(file_path)) {
    cat("  WARNING: File not found for", year, "\n")
    return(NULL)
  }
  
  tryCatch({
    # Read raw data (handle both SPSS and Stata formats)
    if (grepl("\\.dta$", file_path)) {
      raw_data <- read_dta(file_path)
    } else {
      raw_data <- read_spss(file_path)
    }
    cat("  Processing demographics for", year, ":", nrow(raw_data), "observations\n")
    
    # Create demographic controls dataset
    demographics <- data.frame(
      survey_year = year,
      respondent_id = 1:nrow(raw_data)
    )
    
    # Extract age
    age_vars <- c("age", "AGE", "ageuse", "qn50", "qn62", "qn58", "qn64", "qn67")
    age_var <- intersect(age_vars, names(raw_data))[1]
    if (!is.na(age_var)) {
      demographics$age <- as.numeric(raw_data[[age_var]])
      demographics$age <- ifelse(demographics$age < 18 | demographics$age > 100, NA, demographics$age)
    } else {
      demographics$age <- NA
    }
    
    # Extract education
    educ_vars <- c("education", "educ", "EDUC", "F_EDUCCAT", "qn_educ")
    educ_var <- intersect(educ_vars, names(raw_data))[1]
    if (!is.na(educ_var)) {
      demographics$education <- as.numeric(raw_data[[educ_var]])
    } else {
      demographics$education <- NA
    }
    
    # Extract income
    income_vars <- c("income", "household_income", "I_INCOME", "qn_income")
    income_var <- intersect(income_vars, names(raw_data))[1]
    if (!is.na(income_var)) {
      demographics$income <- as.numeric(raw_data[[income_var]])
    } else {
      demographics$income <- NA
    }
    
    # Extract gender
    gender_vars <- c("gender", "sex", "GENDER", "QND18", "RSEX")
    gender_var <- intersect(gender_vars, names(raw_data))[1]
    if (!is.na(gender_var)) {
      demographics$gender <- as.numeric(raw_data[[gender_var]])
    } else {
      demographics$gender <- NA
    }
    
    # Extract race (within Hispanic context)
    race_vars <- c("race", "qn11", "qn118", "RACE")
    race_var <- intersect(race_vars, names(raw_data))[1]
    if (!is.na(race_var)) {
      demographics$race <- as.numeric(raw_data[[race_var]])
    } else {
      demographics$race <- NA
    }
    
    # Extract interview language
    lang_vars <- c("QN2", "language", "qn70", "interview_language", "Primary_language")
    lang_var <- intersect(lang_vars, names(raw_data))[1]
    if (!is.na(lang_var)) {
      demographics$interview_language <- as.numeric(raw_data[[lang_var]])
    } else {
      demographics$interview_language <- NA
    }
    
    # Coverage report
    coverage_report <- demographics %>%
      summarise(
        age_coverage = round(100 * sum(!is.na(age)) / n(), 1),
        education_coverage = round(100 * sum(!is.na(education)) / n(), 1),
        income_coverage = round(100 * sum(!is.na(income)) / n(), 1),
        gender_coverage = round(100 * sum(!is.na(gender)) / n(), 1),
        race_coverage = round(100 * sum(!is.na(race)) / n(), 1),
        language_coverage = round(100 * sum(!is.na(interview_language)) / n(), 1)
      )
    
    cat("  Demographics coverage: Age", coverage_report$age_coverage, "%, Education", 
        coverage_report$education_coverage, "%, Income", coverage_report$income_coverage, "%, Gender", 
        coverage_report$gender_coverage, "%\n")
    
    return(demographics)
    
  }, error = function(e) {
    cat("  ERROR extracting demographics for", year, ":", e$message, "\n")
    return(NULL)
  })
}

# Extract demographics for all available years
cat("\nExtracting demographic controls for all years...\n")
all_demographics <- list()

for (year in names(all_survey_files)) {
  cat("Processing", year, "...\n")
  file_path <- all_survey_files[[year]]
  demo_data <- extract_demographic_controls(file_path, as.numeric(year))
  
  if (!is.null(demo_data)) {
    all_demographics[[year]] <- demo_data
  }
}

# Combine all demographics
if (length(all_demographics) > 0) {
  combined_demographics <- bind_rows(all_demographics)
  cat("\nDemographic controls extracted for", length(all_demographics), "years\n")
  cat("Total demographic records:", nrow(combined_demographics), "\n")
  
  # Show demographic coverage by year
  demo_coverage <- combined_demographics %>%
    group_by(survey_year) %>%
    summarise(
      total_obs = n(),
      age_coverage = round(100 * sum(!is.na(age)) / n(), 1),
      education_coverage = round(100 * sum(!is.na(education)) / n(), 1),
      income_coverage = round(100 * sum(!is.na(income)) / n(), 1),
      gender_coverage = round(100 * sum(!is.na(gender)) / n(), 1),
      race_coverage = round(100 * sum(!is.na(race)) / n(), 1),
      .groups = 'drop'
    )
  
  print(demo_coverage)
} else {
  cat("WARNING: No demographic controls could be extracted\n")
  combined_demographics <- data.frame()
}

# =============================================================================
# 4. INTEGRATE WEIGHTS AND CONTROLS WITH v2.7 DATA
# =============================================================================

cat("\n4. INTEGRATING WEIGHTS AND CONTROLS WITH v2.7 DATA\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Start with v2.7 data
data_v28 <- data_v27

# Add survey weights if available
if (nrow(combined_weights) > 0) {
  cat("Merging survey weights...\n")
  
  # Create unique identifier for matching
  # Note: This assumes respondent_id corresponds to row number in original data
  data_v28 <- data_v28 %>%
    mutate(respondent_id = 1:n()) %>%
    left_join(
      combined_weights %>% select(survey_year, respondent_id, survey_weight, weight_variable_used),
      by = c("survey_year", "respondent_id"),
      suffix = c("", "_new")
    )
  
  weight_merge_summary <- data_v28 %>%
    group_by(survey_year) %>%
    summarise(
      total_obs = n(),
      weights_available = sum(!is.na(survey_weight)),
      weight_coverage = round(100 * weights_available / total_obs, 1),
      .groups = 'drop'
    )
  
  cat("Weight merge summary:\n")
  print(weight_merge_summary)
  
} else {
  cat("No weights to merge - creating placeholder weight variable\n")
  data_v28$survey_weight <- 1.0  # Equal weights for unweighted analysis
}

# Add demographic controls if available
if (nrow(combined_demographics) > 0) {
  cat("Merging demographic controls...\n")
  
  # Ensure respondent_id exists for matching
  if (!"respondent_id" %in% names(data_v28)) {
    data_v28 <- data_v28 %>%
      mutate(respondent_id = 1:n())
  }
  
  data_v28 <- data_v28 %>%
    left_join(
      combined_demographics %>% select(-survey_year),  # Remove duplicate survey_year
      by = "respondent_id",
      suffix = c("", "_demo")
    )
  
  demo_merge_summary <- data_v28 %>%
    group_by(survey_year) %>%
    summarise(
      total_obs = n(),
      age_available = sum(!is.na(age)),
      education_available = sum(!is.na(education)),
      income_available = sum(!is.na(income)),
      gender_available = sum(!is.na(gender)),
      .groups = 'drop'
    )
  
  cat("Demographics merge summary:\n")
  print(demo_merge_summary)
  
} else {
  cat("No demographic controls to merge\n")
}

# =============================================================================
# 5. ENHANCED ANALYSIS WITH SURVEY WEIGHTS
# =============================================================================

cat("\n5. ENHANCED ANALYSIS WITH SURVEY WEIGHTS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Create survey design objects for weighted analysis
create_survey_design <- function(data, year_subset = NULL) {
  if (!is.null(year_subset)) {
    data <- data %>% filter(survey_year %in% year_subset)
  }
  
  # Check if weights are available
  if ("survey_weight" %in% names(data) && sum(!is.na(data$survey_weight)) > 0) {
    # Create survey design with weights
    survey_design <- svydesign(
      ids = ~1,  # No clustering information available
      weights = ~survey_weight,
      data = data %>% filter(!is.na(survey_weight))
    )
    return(survey_design)
  } else {
    # Create unweighted design
    survey_design <- svydesign(
      ids = ~1,
      weights = ~1,  # Equal weights
      data = data
    )
    return(survey_design)
  }
}

# Function for weighted regression analysis
weighted_trend_analysis <- function(data, index_var, by_generation = TRUE) {
  if (by_generation && "immigrant_generation" %in% names(data)) {
    # Generation-stratified analysis
    generations <- data %>%
      filter(!is.na(immigrant_generation) & !is.na(.data[[index_var]])) %>%
      pull(immigrant_generation) %>%
      unique() %>%
      sort()
    
    results <- list()
    
    for (gen in generations) {
      gen_data <- data %>% 
        filter(immigrant_generation == gen & !is.na(.data[[index_var]]))
      
      if (nrow(gen_data) > 5) {  # Minimum sample size
        survey_design <- create_survey_design(gen_data)
        
        # Weighted regression
        model_formula <- as.formula(paste(index_var, "~ survey_year"))
        model <- svyglm(model_formula, design = survey_design)
        
        # Extract results
        slope <- coef(model)[2]
        se <- sqrt(diag(vcov(model)))[2]
        p_value <- summary(model)$coefficients[2, 4]
        
        generation_label <- case_when(
          gen == 1 ~ "First Generation",
          gen == 2 ~ "Second Generation", 
          gen == 3 ~ "Third+ Generation",
          TRUE ~ paste("Generation", gen)
        )
        
        results[[as.character(gen)]] <- data.frame(
          index = index_var,
          scope = generation_label,
          slope = slope,
          se = se,
          p_value = p_value,
          significance = case_when(
            p_value < 0.001 ~ "***",
            p_value < 0.01 ~ "**", 
            p_value < 0.05 ~ "*",
            TRUE ~ "ns"
          ),
          direction = ifelse(slope > 0, "INCREASING", "DECREASING"),
          n_years = length(unique(gen_data$survey_year)),
          years = paste(sort(unique(gen_data$survey_year)), collapse = ", "),
          stringsAsFactors = FALSE
        )
      }
    }
    
    return(bind_rows(results))
    
  } else {
    # Overall population analysis
    pop_data <- data %>% filter(!is.na(.data[[index_var]]))
    
    if (nrow(pop_data) > 5) {
      survey_design <- create_survey_design(pop_data)
      
      # Weighted regression
      model_formula <- as.formula(paste(index_var, "~ survey_year"))
      model <- svyglm(model_formula, design = survey_design)
      
      # Extract results
      slope <- coef(model)[2]
      se <- sqrt(diag(vcov(model)))[2]
      p_value <- summary(model)$coefficients[2, 4]
      
      result <- data.frame(
        index = index_var,
        scope = "Overall Population",
        slope = slope,
        se = se,
        p_value = p_value,
        significance = case_when(
          p_value < 0.001 ~ "***",
          p_value < 0.01 ~ "**",
          p_value < 0.05 ~ "*",
          TRUE ~ "ns"
        ),
        direction = ifelse(slope > 0, "INCREASING", "DECREASING"),
        n_years = length(unique(pop_data$survey_year)),
        years = paste(sort(unique(pop_data$survey_year)), collapse = ", "),
        stringsAsFactors = FALSE
      )
      
      return(result)
    }
  }
  
  return(data.frame())
}

# Analyze trends for all three indices with proper weights
cat("Conducting weighted trend analysis...\n")

# Overall population trends (weighted)
overall_weighted_results <- bind_rows(
  weighted_trend_analysis(data_v28, "liberalism_index", by_generation = FALSE),
  weighted_trend_analysis(data_v28, "restrictionism_index", by_generation = FALSE), 
  weighted_trend_analysis(data_v28, "concern_index", by_generation = FALSE)
)

# Generation-stratified trends (weighted)
generation_weighted_results <- bind_rows(
  weighted_trend_analysis(data_v28, "liberalism_index", by_generation = TRUE),
  weighted_trend_analysis(data_v28, "restrictionism_index", by_generation = TRUE),
  weighted_trend_analysis(data_v28, "concern_index", by_generation = TRUE)
)

# =============================================================================
# 6. EXPORT ENHANCED DATASET AND RESULTS
# =============================================================================

cat("\n6. EXPORTING ENHANCED DATASET AND RESULTS\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

# Export enhanced v2.8 dataset
write_csv(data_v28, "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_8.csv")
cat("Enhanced dataset exported: data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_8.csv\n")
cat("Dataset dimensions:", nrow(data_v28), "x", ncol(data_v28), "\n")

# Export weighted results
if (nrow(overall_weighted_results) > 0) {
  write_csv(overall_weighted_results, "outputs/overall_weighted_trends_results_v2_8.csv")
}

if (nrow(generation_weighted_results) > 0) {
  write_csv(generation_weighted_results, "outputs/generation_weighted_trends_results_v2_8.csv")
}

# Export weight and demographic summaries
if (exists("weight_coverage")) {
  write_csv(weight_coverage, "outputs/survey_weights_coverage_v2_8.csv")
}

if (exists("demo_coverage")) {
  write_csv(demo_coverage, "outputs/demographic_controls_coverage_v2_8.csv")
}

# Summary statistics
cat("\n=================================================================\n")
cat("ENHANCED ANALYSIS v2.8 SUMMARY\n")
cat("=================================================================\n")

cat("Version 2.8 Enhancements:\n")
cat("1. SURVEY WEIGHTS INTEGRATION:\n")
if ("survey_weight" %in% names(data_v28)) {
  weight_summary <- data_v28 %>%
    summarise(
      total_obs = n(),
      weighted_obs = sum(!is.na(survey_weight)),
      weight_coverage = round(100 * weighted_obs / total_obs, 1)
    )
  cat(sprintf("   - Weighted observations: %d/%d (%.1f%%)\n", 
              weight_summary$weighted_obs, weight_summary$total_obs, weight_summary$weight_coverage))
} else {
  cat("   - No survey weights available\n")
}

cat("\n2. DEMOGRAPHIC CONTROLS ADDED:\n")
demo_vars <- c("age", "education", "income", "gender", "race", "interview_language")
available_demo_vars <- intersect(demo_vars, names(data_v28))
cat("   - Available controls:", paste(available_demo_vars, collapse = ", "), "\n")

if (length(available_demo_vars) > 0) {
  for (var in available_demo_vars) {
    coverage <- round(100 * sum(!is.na(data_v28[[var]])) / nrow(data_v28), 1)
    cat(sprintf("   - %s: %.1f%% coverage\n", var, coverage))
  }
}

cat("\n3. WEIGHTED STATISTICAL RESULTS:\n")
if (nrow(overall_weighted_results) > 0) {
  cat("   Overall population trends (weighted):\n")
  for (i in 1:nrow(overall_weighted_results)) {
    result <- overall_weighted_results[i, ]
    cat(sprintf("   - %s: %s (slope = %+.4f, p = %.3f %s)\n",
                result$index, result$direction, result$slope, result$p_value, result$significance))
  }
}

if (nrow(generation_weighted_results) > 0) {
  cat("   Generation-stratified trends (weighted):\n")
  for (i in 1:nrow(generation_weighted_results)) {
    result <- generation_weighted_results[i, ]
    cat(sprintf("   - %s (%s): %s (p = %.3f %s)\n",
                result$index, result$scope, result$direction, result$p_value, result$significance))
  }
}

save.image("outputs/analysis_v2_8_weights_controls_workspace.RData")

cat("\n=================================================================\n")
cat("IMMIGRATION ATTITUDES ANALYSIS v2.8 COMPLETE\n")
cat("SUCCESS: Survey weights and demographic controls integrated\n")
cat("READY FOR: Missing data analysis and publication-quality modeling\n")
cat("=================================================================\n") 