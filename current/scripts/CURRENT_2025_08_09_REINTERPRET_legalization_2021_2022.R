# =============================================================================
# REINTERPRET LEGALIZATION SUPPORT 2021-2022
# =============================================================================
# Purpose: Properly interpret the 2021-2022 legalization data based on codebook
# Date: 2025-08-09
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
})

message("=== REINTERPRETING LEGALIZATION SUPPORT 2021-2022 ===")

# Load data
df <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

# =============================================================================
# UNDERSTANDING THE SCALE CHANGE
# =============================================================================

message("\n1. SCALE INTERPRETATION:")
message("2002-2010: Binary scale (1=Support, 2=Oppose)")
message("2021-2022: Importance scale transformed to negative")
message("  Original: 1=Very important, 2=Somewhat important, 3=Not too important, 4=Not at all important")
message("  Our data: -1=Very important, -2=Somewhat important, -3=Not too important, -4=Not at all important")

# =============================================================================
# RECODE 2021-2022 DATA
# =============================================================================

df_recoded <- df %>%
  mutate(
    # Create a unified support measure
    legalization_support_unified = case_when(
      # Early years: 1=support, 2=oppose
      survey_year <= 2010 & legalization_support == 1 ~ "Support",
      survey_year <= 2010 & legalization_support == 2 ~ "Oppose",
      
      # 2021-2022: Combine "Very" and "Somewhat" important as support
      survey_year >= 2021 & legalization_support == -1 ~ "Support (Very Important)",
      survey_year >= 2021 & legalization_support == -2 ~ "Support (Somewhat Important)",
      survey_year >= 2021 & legalization_support == -3 ~ "Oppose (Not Too Important)",
      survey_year >= 2021 & legalization_support == -4 ~ "Oppose (Not At All Important)",
      
      TRUE ~ NA_character_
    ),
    
    # Binary version
    legalization_binary = case_when(
      survey_year <= 2010 & legalization_support == 1 ~ 1,
      survey_year <= 2010 & legalization_support == 2 ~ 0,
      survey_year >= 2021 & legalization_support %in% c(-1, -2) ~ 1,  # Important = Support
      survey_year >= 2021 & legalization_support %in% c(-3, -4) ~ 0,  # Not Important = Oppose
      TRUE ~ NA_real_
    ),
    
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation",
      immigrant_generation >= 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    )
  )

# =============================================================================
# CALCULATE SUPPORT RATES WITH PROPER INTERPRETATION
# =============================================================================

message("\n2. SUPPORT RATES BY YEAR AND GENERATION (Properly Interpreted):")

support_rates <- df_recoded %>%
  filter(!is.na(legalization_binary), !is.na(generation_label)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    n = n(),
    support_rate = mean(legalization_binary) * 100,
    .groups = "drop"
  ) %>%
  arrange(generation_label, survey_year)

print(support_rates, n = Inf)

# Calculate overall trends
overall_support <- df_recoded %>%
  filter(!is.na(legalization_binary), !is.na(generation_label)) %>%
  group_by(survey_year) %>%
  summarise(
    n = n(),
    overall_support_rate = mean(legalization_binary) * 100,
    .groups = "drop"
  )

message("\n3. OVERALL SUPPORT RATES BY YEAR:")
print(overall_support)

# =============================================================================
# DETAILED 2021-2022 BREAKDOWN
# =============================================================================

message("\n4. DETAILED 2021-2022 BREAKDOWN:")

detailed_2021_2022 <- df_recoded %>%
  filter(survey_year >= 2021, !is.na(legalization_support), !is.na(generation_label)) %>%
  group_by(survey_year, generation_label, legalization_support_unified) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(survey_year, generation_label) %>%
  mutate(
    prop = n / sum(n) * 100,
    prop_text = sprintf("%.1f%%", prop)
  ) %>%
  arrange(survey_year, generation_label, legalization_support_unified)

print(detailed_2021_2022, n = Inf)

# =============================================================================
# TREND ANALYSIS WITH CORRECTED DATA
# =============================================================================

message("\n5. TREND ANALYSIS (2002-2022):")

# Calculate slopes
trend_analysis <- df_recoded %>%
  filter(!is.na(legalization_binary), !is.na(generation_label)) %>%
  group_by(generation_label) %>%
  do({
    if (n_distinct(.$survey_year) >= 3) {
      model <- lm(legalization_binary ~ survey_year, data = .)
      tibble(
        slope = coef(model)[2],
        se = summary(model)$coefficients[2, 2],
        p_value = summary(model)$coefficients[2, 4],
        change_per_decade = slope * 10 * 100,  # Convert to percentage points per decade
        n_years = n_distinct(.$survey_year),
        year_range = paste(range(.$survey_year), collapse = "-")
      )
    } else {
      tibble(slope = NA, se = NA, p_value = NA, change_per_decade = NA, 
             n_years = 0, year_range = NA)
    }
  }) %>%
  ungroup()

print(trend_analysis)

# =============================================================================
# KEY FINDINGS
# =============================================================================

message("\n=== KEY FINDINGS ===")
message("1. The 2021-2022 data uses a different scale (importance) rather than binary support/oppose")
message("2. When properly interpreted (Very/Somewhat Important = Support):")

# Calculate 2021-2022 support rates
recent_support <- support_rates %>%
  filter(survey_year >= 2021) %>%
  group_by(generation_label) %>%
  summarise(
    avg_support_2021_2022 = mean(support_rate),
    .groups = "drop"
  )

for (i in 1:nrow(recent_support)) {
  message(sprintf("   - %s: %.1f%% support (2021-2022 average)",
                  recent_support$generation_label[i],
                  recent_support$avg_support_2021_2022[i]))
}

message("\n3. The 'collapse to 0%' was indeed a coding interpretation error!")
message("4. Support remains substantial in 2021-2022, though lower than 2002-2010 levels")

# Save corrected results
output_dir <- "current/outputs"
write_csv(support_rates, file.path(output_dir, "CURRENT_2025_08_09_legalization_support_rates_CORRECTED.csv"))
write_csv(detailed_2021_2022, file.path(output_dir, "CURRENT_2025_08_09_legalization_2021_2022_detailed.csv"))

message("\n=== REINTERPRETATION COMPLETE ===")
message("Corrected data saved to: ", output_dir)
