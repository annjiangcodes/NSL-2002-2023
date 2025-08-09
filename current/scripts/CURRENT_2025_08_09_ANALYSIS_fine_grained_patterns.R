# =============================================================================
# FINE-GRAINED PATTERN ANALYSIS
# =============================================================================
# Purpose: Deep dive into specific temporal, generational, and policy mechanisms
# Date: 2025-08-09
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(stringr)
  library(purrr)
  library(broom)
})

message("=== FINE-GRAINED PATTERN ANALYSIS START ===")

# =============================================================================
# LOAD AND PREPARE DATA
# =============================================================================

data_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
df <- read_csv(data_path, show_col_types = FALSE)

# Clean and prepare data
df_processed <- df %>%
  filter(!is.na(immigrant_generation), 
         survey_year >= 2002, 
         survey_year <= 2022) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation", 
      immigrant_generation >= 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    ),
    # Create policy period indicators
    period = case_when(
      survey_year <= 2008 ~ "Pre-Recession (2002-2008)",
      survey_year <= 2016 ~ "Obama Era (2009-2016)", 
      survey_year <= 2020 ~ "Trump Era (2017-2020)",
      TRUE ~ "Post-Trump (2021-2022)"
    ),
    pre_post_2016 = ifelse(survey_year <= 2016, "Pre-2016", "Post-2016"),
    trump_era = ifelse(survey_year %in% 2017:2020, "Trump Era", "Other Periods")
  ) %>%
  filter(!is.na(generation_label))

message("Data prepared: ", nrow(df_processed), " observations")
message("Years available: ", paste(sort(unique(df_processed$survey_year)), collapse = ", "))

# =============================================================================
# 1. FINE-GRAINED LIBERALISM INDEX ANALYSIS
# =============================================================================

message("\n=== 1. LIBERALISM INDEX FINE-GRAINED ANALYSIS ===")

# Calculate yearly means by generation for liberalism
lib_yearly <- df_processed %>%
  filter(!is.na(liberalism_index)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    mean_lib = mean(liberalism_index, na.rm = TRUE),
    se_lib = sd(liberalism_index, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  ) %>%
  mutate(
    ci_lower = mean_lib - 1.96 * se_lib,
    ci_upper = mean_lib + 1.96 * se_lib
  )

# Print detailed yearly patterns
message("\\nLiberalism Index by Year and Generation:")
lib_yearly %>%
  arrange(survey_year, generation_label) %>%
  print(n = Inf)

# Calculate period-specific trends
lib_period_trends <- df_processed %>%
  filter(!is.na(liberalism_index)) %>%
  group_by(period, generation_label) %>%
  summarise(
    mean_lib = mean(liberalism_index, na.rm = TRUE),
    se_lib = sd(liberalism_index, na.rm = TRUE) / sqrt(n()),
    n = n(),
    years = paste(sort(unique(survey_year)), collapse = ", "),
    .groups = "drop"
  )

message("\\nLiberalism by Policy Period:")
print(lib_period_trends)

# Examine specific year-to-year changes
lib_changes <- lib_yearly %>%
  arrange(generation_label, survey_year) %>%
  group_by(generation_label) %>%
  mutate(
    lib_change = mean_lib - lag(mean_lib),
    year_gap = survey_year - lag(survey_year)
  ) %>%
  filter(!is.na(lib_change)) %>%
  select(generation_label, survey_year, mean_lib, lib_change, year_gap)

message("\\nYear-to-Year Liberalism Changes:")
print(lib_changes)

# =============================================================================
# 2. RESTRICTIONISM INDEX PATTERNS
# =============================================================================

message("\\n=== 2. RESTRICTIONISM INDEX FINE-GRAINED ANALYSIS ===")

# Calculate yearly means by generation for restrictionism
rest_yearly <- df_processed %>%
  filter(!is.na(restrictionism_index)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    mean_rest = mean(restrictionism_index, na.rm = TRUE),
    se_rest = sd(restrictionism_index, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

message("\\nRestrictionism Index by Year and Generation:")
rest_yearly %>%
  arrange(survey_year, generation_label) %>%
  print(n = Inf)

# Calculate generational gaps (First - Second, First - Third+)
generational_gaps <- function(data, var_name) {
  data %>%
    select(survey_year, generation_label, all_of(var_name)) %>%
    pivot_wider(names_from = generation_label, values_from = all_of(var_name)) %>%
    mutate(
      First_vs_Second = `First Generation` - `Second Generation`,
      First_vs_Third = `First Generation` - `Third+ Generation`,
      Second_vs_Third = `Second Generation` - `Third+ Generation`
    ) %>%
    select(survey_year, contains("_vs_"))
}

lib_gaps <- generational_gaps(lib_yearly %>% select(survey_year, generation_label, mean_lib), "mean_lib")
rest_gaps <- generational_gaps(rest_yearly %>% select(survey_year, generation_label, mean_rest), "mean_rest")

message("\\nGenerational Gaps in Liberalism (First - Others):")
print(lib_gaps)

message("\\nGenerational Gaps in Restrictionism (First - Others):")
print(rest_gaps)

# =============================================================================
# 3. LEGALIZATION SUPPORT DECLINE MECHANISMS
# =============================================================================

message("\\n=== 3. LEGALIZATION SUPPORT DECLINE ANALYSIS ===")

# Examine legalization support patterns
leg_yearly <- df_processed %>%
  filter(!is.na(legalization_support)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    mean_leg = mean(legalization_support, na.rm = TRUE),
    prop_support = mean(legalization_support == 1, na.rm = TRUE),
    se_leg = sd(legalization_support, na.rm = TRUE) / sqrt(n()),
    n = n(),
    .groups = "drop"
  )

message("\\nLegalization Support by Year:")
print(leg_yearly)

# Calculate decline rates
leg_trends <- df_processed %>%
  filter(!is.na(legalization_support)) %>%
  group_by(generation_label) %>%
  do({
    if (n_distinct(.$survey_year) >= 3) {
      model <- lm(legalization_support ~ survey_year, data = .)
      tibble(
        slope = coef(model)[2],
        se = summary(model)$coefficients[2, 2],
        p_value = summary(model)$coefficients[2, 4],
        decline_per_decade = slope * 10,
        years_covered = n_distinct(.$survey_year)
      )
    } else {
      tibble(slope = NA, se = NA, p_value = NA, decline_per_decade = NA, years_covered = 0)
    }
  }) %>%
  ungroup()

message("\\nLegalization Support Decline Rates:")
print(leg_trends)

# =============================================================================
# 4. VOLATILITY AND STABILITY ANALYSIS
# =============================================================================

message("\\n=== 4. ATTITUDE STABILITY ANALYSIS ===")

# Calculate volatility (CV) for each generation
volatility_analysis <- function(data, var_name) {
  data %>%
    filter(!is.na(.data[[var_name]])) %>%
    group_by(generation_label) %>%
    summarise(
      mean_value = mean(.data[[var_name]], na.rm = TRUE),
      sd_value = sd(.data[[var_name]], na.rm = TRUE),
      cv = sd_value / abs(mean_value),
      n_years = n_distinct(survey_year),
      year_range = paste(range(survey_year), collapse = "-"),
      .groups = "drop"
    ) %>%
    mutate(variable = var_name)
}

# Calculate volatility for key measures
lib_volatility <- volatility_analysis(lib_yearly, "mean_lib")
rest_volatility <- volatility_analysis(rest_yearly, "mean_rest")

combined_volatility <- bind_rows(lib_volatility, rest_volatility)

message("\\nAttitude Volatility by Generation:")
print(combined_volatility)

# =============================================================================
# 5. POLICY PERIOD EFFECTS
# =============================================================================

message("\\n=== 5. POLICY PERIOD EFFECTS ===")

# Pre vs Post-2016 comparison
period_comparison <- df_processed %>%
  filter(!is.na(liberalism_index) | !is.na(restrictionism_index)) %>%
  group_by(pre_post_2016, generation_label) %>%
  summarise(
    mean_lib = mean(liberalism_index, na.rm = TRUE),
    mean_rest = mean(restrictionism_index, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = pre_post_2016, values_from = c(mean_lib, mean_rest, n)) %>%
  mutate(
    lib_change = `mean_lib_Post-2016` - `mean_lib_Pre-2016`,
    rest_change = `mean_rest_Post-2016` - `mean_rest_Pre-2016`
  )

message("\\nPre vs Post-2016 Changes:")
print(period_comparison)

# Trump era specific effects
trump_effects <- df_processed %>%
  filter(!is.na(liberalism_index), survey_year %in% c(2016, 2018, 2021, 2022)) %>%
  mutate(trump_period = ifelse(survey_year %in% c(2018), "Trump Era", "Other")) %>%
  group_by(trump_period, generation_label) %>%
  summarise(
    mean_lib = mean(liberalism_index, na.rm = TRUE),
    mean_rest = mean(restrictionism_index, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

message("\\nTrump Era Effects:")
print(trump_effects)

# =============================================================================
# 6. WITHIN-GENERATION HETEROGENEITY
# =============================================================================

message("\\n=== 6. WITHIN-GENERATION HETEROGENEITY ===")

# Examine distribution properties
within_gen_stats <- df_processed %>%
  filter(!is.na(liberalism_index)) %>%
  group_by(generation_label) %>%
  summarise(
    n = n(),
    mean_lib = mean(liberalism_index, na.rm = TRUE),
    median_lib = median(liberalism_index, na.rm = TRUE),
    sd_lib = sd(liberalism_index, na.rm = TRUE),
    q25 = quantile(liberalism_index, 0.25, na.rm = TRUE),
    q75 = quantile(liberalism_index, 0.75, na.rm = TRUE),
    iqr = q75 - q25,
    .groups = "drop"
  )

message("\\nWithin-Generation Liberalism Distribution:")
print(within_gen_stats)

# =============================================================================
# 7. SAVE ANALYSIS RESULTS
# =============================================================================

# Save detailed results
output_dir <- "current/outputs"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# Save key datasets
write_csv(lib_yearly, file.path(output_dir, "CURRENT_2025_08_09_liberalism_yearly_detailed.csv"))
write_csv(rest_yearly, file.path(output_dir, "CURRENT_2025_08_09_restrictionism_yearly_detailed.csv"))
write_csv(lib_gaps, file.path(output_dir, "CURRENT_2025_08_09_generational_gaps_detailed.csv"))
write_csv(combined_volatility, file.path(output_dir, "CURRENT_2025_08_09_volatility_analysis_detailed.csv"))
write_csv(period_comparison, file.path(output_dir, "CURRENT_2025_08_09_period_effects_detailed.csv"))

message("\\n=== FINE-GRAINED PATTERN ANALYSIS COMPLETE ===")
message("Detailed analysis files saved to: ", output_dir)
