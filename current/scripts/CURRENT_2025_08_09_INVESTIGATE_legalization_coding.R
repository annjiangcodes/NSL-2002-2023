# =============================================================================
# INVESTIGATE LEGALIZATION SUPPORT CODING ERROR
# =============================================================================
# Purpose: Diagnose and document the legalization support coding issue
# Date: 2025-08-09
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

message("=== INVESTIGATING LEGALIZATION SUPPORT CODING ERROR ===")

# Load data
df <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

# =============================================================================
# 1. EXAMINE CODING BY YEAR
# =============================================================================

message("\n1. UNIQUE VALUES BY YEAR:")
coding_by_year <- df %>%
  filter(!is.na(legalization_support)) %>%
  group_by(survey_year) %>%
  summarise(
    unique_values = paste(sort(unique(legalization_support)), collapse = ", "),
    n_obs = n(),
    min_val = min(legalization_support),
    max_val = max(legalization_support),
    mean_val = mean(legalization_support),
    .groups = "drop"
  )

print(coding_by_year)

# =============================================================================
# 2. EXAMINE VALUE DISTRIBUTIONS
# =============================================================================

message("\n2. VALUE DISTRIBUTION BY YEAR:")
value_dist <- df %>%
  filter(!is.na(legalization_support)) %>%
  count(survey_year, legalization_support) %>%
  group_by(survey_year) %>%
  mutate(
    prop = n / sum(n),
    prop_pct = round(prop * 100, 1)
  ) %>%
  arrange(survey_year, legalization_support)

print(value_dist)

# =============================================================================
# 3. CHECK STANDARDIZED VALUES
# =============================================================================

message("\n3. STANDARDIZED VALUES CHECK:")
std_check <- df %>%
  filter(!is.na(legalization_support), !is.na(legalization_support_std)) %>%
  group_by(survey_year) %>%
  summarise(
    raw_mean = mean(legalization_support),
    std_mean = mean(legalization_support_std),
    raw_sd = sd(legalization_support),
    std_sd = sd(legalization_support_std),
    correlation = cor(legalization_support, legalization_support_std),
    .groups = "drop"
  )

print(std_check)

# =============================================================================
# 4. DIAGNOSE THE ISSUE
# =============================================================================

message("\n4. DIAGNOSIS:")

# Check if it's a simple recoding
early_years <- df %>% filter(survey_year %in% c(2002, 2004, 2010))
late_years <- df %>% filter(survey_year %in% c(2021, 2022))

message("\nEarly years (2002-2010) coding:")
message("Value 1: Likely means SUPPORT (", 
        round(mean(early_years$legalization_support == 1, na.rm = TRUE) * 100, 1), 
        "% of responses)")
message("Value 2: Likely means OPPOSE (", 
        round(mean(early_years$legalization_support == 2, na.rm = TRUE) * 100, 1), 
        "% of responses)")

message("\nLate years (2021-2022) coding:")
unique_late <- sort(unique(late_years$legalization_support[!is.na(late_years$legalization_support)]))
message("Unique values: ", paste(unique_late, collapse = ", "))

# Check if negative values might be a scale
if (all(unique_late < 0)) {
  message("\nALL values are negative in 2021-2022!")
  message("This suggests either:")
  message("1. A coding error (values incorrectly transformed)")
  message("2. A completely different scale was used")
  message("3. Missing data was coded as negative values")
}

# =============================================================================
# 5. CALCULATE CORRECTED SUPPORT RATES
# =============================================================================

message("\n5. SUPPORT RATES BY GENERATION (assuming value 1 = support):")

support_rates <- df %>%
  filter(!is.na(legalization_support), !is.na(immigrant_generation)) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation",
      immigrant_generation >= 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    ),
    # For early years, assume 1 = support
    support = case_when(
      survey_year <= 2010 ~ as.numeric(legalization_support == 1),
      TRUE ~ NA_real_  # Can't interpret 2021-2022 values
    )
  ) %>%
  filter(!is.na(generation_label)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    n = n(),
    support_rate = mean(support, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(!is.na(support_rate))

print(support_rates)

# =============================================================================
# 6. RECOMMENDATION
# =============================================================================

message("\n=== RECOMMENDATION ===")
message("The 2021-2022 legalization_support values are clearly miscoded.")
message("Options:")
message("1. Exclude 2021-2022 from legalization support analysis")
message("2. Investigate original survey questions and recode properly")
message("3. Use only standardized values if they're correctly calculated")
message("\nThe '0% support' finding is definitely an ARTIFACT of this coding error!")

# Save diagnostic output
output_dir <- "current/outputs"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

write_csv(coding_by_year, file.path(output_dir, "CURRENT_2025_08_09_legalization_coding_by_year.csv"))
write_csv(value_dist, file.path(output_dir, "CURRENT_2025_08_09_legalization_value_distribution.csv"))
write_csv(support_rates, file.path(output_dir, "CURRENT_2025_08_09_legalization_support_rates_corrected.csv"))

message("\n=== INVESTIGATION COMPLETE ===")
message("Diagnostic files saved to: ", output_dir)
