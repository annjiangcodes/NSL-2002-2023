# =============================================================================
# VERIFY GENERATION PATTERNS AND COLOR CODING
# =============================================================================
# Purpose: Check if generation labels and patterns match the claims
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)

cat("=============================================================\n")
cat("GENERATION PATTERN VERIFICATION\n")
cat("=============================================================\n")

# =============================================================================
# 1. LOAD AND EXAMINE RAW DATA
# =============================================================================

cat("\n1. LOADING AND EXAMINING RAW DATA\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load generation trends data
generation_trends <- read_csv("outputs/generation_year_trends_v4_0.csv", show_col_types = FALSE)

cat("\nColor coding used in visualizations:\n")
cat("1st Generation = RED (#E41A1C)\n")
cat("2nd Generation = BLUE (#377EB8)\n") 
cat("3rd+ Generation = GREEN (#4DAF4A)\n")

# =============================================================================
# 2. EXAMINE ACTUAL PATTERNS BY GENERATION
# =============================================================================

cat("\n2. EXAMINING ACTUAL PATTERNS BY GENERATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Check liberalism patterns
cat("\nLIBERALISM PATTERNS:\n")
cat("===================\n")

liberalism_summary <- generation_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  group_by(generation_label) %>%
  summarise(
    years_available = n(),
    mean_liberalism = mean(liberalism_mean, na.rm = TRUE),
    min_liberalism = min(liberalism_mean, na.rm = TRUE),
    max_liberalism = max(liberalism_mean, na.rm = TRUE),
    liberalism_range = max_liberalism - min_liberalism,
    liberalism_sd = sd(liberalism_mean, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(mean_liberalism)

print(liberalism_summary)

cat("\nRanking by mean liberalism (most liberal to most conservative):\n")
ranked_libs <- liberalism_summary %>%
  arrange(mean_liberalism) %>%
  mutate(rank = row_number()) %>%
  select(rank, generation_label, mean_liberalism)
print(ranked_libs)

# Check restrictionism patterns
cat("\nRESTRICTIONISM PATTERNS:\n")
cat("=======================\n")

restrictionism_summary <- generation_trends %>%
  filter(!is.na(restrictionism_mean)) %>%
  group_by(generation_label) %>%
  summarise(
    years_available = n(),
    mean_restrictionism = mean(restrictionism_mean, na.rm = TRUE),
    min_restrictionism = min(restrictionism_mean, na.rm = TRUE),
    max_restrictionism = max(restrictionism_mean, na.rm = TRUE),
    restrictionism_range = max_restrictionism - min_restrictionism,
    restrictionism_sd = sd(restrictionism_mean, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(mean_restrictionism))

print(restrictionism_summary)

cat("\nRanking by mean restrictionism (most restrictive to most liberal):\n")
ranked_res <- restrictionism_summary %>%
  arrange(desc(mean_restrictionism)) %>%
  mutate(rank = row_number()) %>%
  select(rank, generation_label, mean_restrictionism)
print(ranked_res)

# =============================================================================
# 3. VARIANCE ANALYSIS BY GENERATION
# =============================================================================

cat("\n3. VARIANCE ANALYSIS BY GENERATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

variance_analysis <- generation_trends %>%
  filter(!is.na(liberalism_mean) | !is.na(restrictionism_mean)) %>%
  group_by(generation_label) %>%
  summarise(
    # Liberalism variance metrics
    lib_variance = var(liberalism_mean, na.rm = TRUE),
    lib_sd = sd(liberalism_mean, na.rm = TRUE),
    lib_coefficient_of_variation = abs(lib_sd / mean(liberalism_mean, na.rm = TRUE)),
    
    # Restrictionism variance metrics  
    res_variance = var(restrictionism_mean, na.rm = TRUE),
    res_sd = sd(restrictionism_mean, na.rm = TRUE),
    res_coefficient_of_variation = abs(res_sd / mean(restrictionism_mean, na.rm = TRUE)),
    
    # Sample info
    n_years_lib = sum(!is.na(liberalism_mean)),
    n_years_res = sum(!is.na(restrictionism_mean)),
    .groups = "drop"
  )

cat("\nVARIANCE COMPARISON:\n")
print(variance_analysis)

cat("\nRanking by liberalism variance (most volatile to most stable):\n")
lib_variance_rank <- variance_analysis %>%
  arrange(desc(lib_variance)) %>%
  select(generation_label, lib_variance, lib_sd) %>%
  mutate(rank = row_number())
print(lib_variance_rank)

cat("\nRanking by restrictionism variance (most volatile to most stable):\n")
res_variance_rank <- variance_analysis %>%
  arrange(desc(res_variance)) %>%
  select(generation_label, res_variance, res_sd) %>%
  mutate(rank = row_number())
print(res_variance_rank)

# =============================================================================
# 4. TRAJECTORY ANALYSIS - DISTANCE FROM BASELINE
# =============================================================================

cat("\n4. TRAJECTORY ANALYSIS - DISTANCE FROM BASELINE\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate baseline (2002) values for each generation
baseline_2002 <- generation_trends %>%
  filter(survey_year == 2002) %>%
  select(generation_label, lib_baseline = liberalism_mean, res_baseline = restrictionism_mean)

# Calculate distance from baseline over time
trajectory_analysis <- generation_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  left_join(baseline_2002, by = "generation_label") %>%
  mutate(
    lib_distance_from_baseline = liberalism_mean - lib_baseline,
    abs_lib_distance = abs(lib_distance_from_baseline)
  ) %>%
  group_by(generation_label) %>%
  summarise(
    mean_abs_distance = mean(abs_lib_distance, na.rm = TRUE),
    max_distance = max(abs_lib_distance, na.rm = TRUE),
    total_movement = sum(abs(diff(liberalism_mean)), na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  )

cat("\nTRAJECTORY MOVEMENT FROM BASELINE:\n")
print(trajectory_analysis)

cat("\nRanking by movement/volatility:\n")
movement_rank <- trajectory_analysis %>%
  arrange(desc(total_movement)) %>%
  select(generation_label, total_movement, mean_abs_distance) %>%
  mutate(rank = row_number())
print(movement_rank)

# =============================================================================
# 5. CHECK SPECIFIC YEARS FOR VERIFICATION
# =============================================================================

cat("\n5. SPECIFIC YEAR COMPARISONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Key years comparison
key_years_data <- generation_trends %>%
  filter(survey_year %in% c(2002, 2012, 2022), !is.na(liberalism_mean)) %>%
  select(survey_year, generation_label, liberalism_mean, restrictionism_mean) %>%
  arrange(survey_year, liberalism_mean)

cat("\nKey years data (ordered by liberalism within each year):\n")
for(year in c(2002, 2012, 2022)) {
  cat(paste("\n", year, ":\n"))
  year_data <- key_years_data %>% filter(survey_year == year)
  if(nrow(year_data) > 0) {
    print(year_data)
  } else {
    cat("No data available\n")
  }
}

# =============================================================================
# 6. FINAL PATTERN VERIFICATION
# =============================================================================

cat("\n6. FINAL PATTERN VERIFICATION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nEXPECTED PATTERN (if correctly labeled):\n")
cat("1st Generation (RED): Most liberal, consistent\n")
cat("2nd Generation (BLUE): Middle, volatile\n") 
cat("3rd+ Generation (GREEN): Most conservative, stable\n")

cat("\nACTUAL PATTERN FROM DATA:\n")

# Most liberal to most conservative
actual_lib_pattern <- liberalism_summary %>%
  arrange(mean_liberalism) %>%
  mutate(pattern_description = case_when(
    row_number() == 1 ~ "MOST LIBERAL",
    row_number() == n() ~ "MOST CONSERVATIVE", 
    TRUE ~ "MIDDLE"
  )) %>%
  select(generation_label, mean_liberalism, pattern_description)

print(actual_lib_pattern)

# Most volatile to most stable (liberalism)
actual_volatility_pattern <- variance_analysis %>%
  arrange(desc(lib_variance)) %>%
  mutate(volatility_description = case_when(
    row_number() == 1 ~ "MOST VOLATILE",
    row_number() == n() ~ "MOST STABLE",
    TRUE ~ "MODERATE VOLATILITY"
  )) %>%
  select(generation_label, lib_variance, volatility_description)

cat("\nVolatility patterns:\n")
print(actual_volatility_pattern)

# =============================================================================
# 7. CONCLUSION
# =============================================================================

cat("\n7. CONCLUSION\n")
cat(paste(rep("=", 60), collapse = ""), "\n")

cat("\nCOLOR CODING VERIFICATION:\n")
cat("=========================\n")

# Create verification summary
verification_summary <- data.frame(
  Generation = c("1st Generation", "2nd Generation", "3rd+ Generation"),
  Color = c("RED", "BLUE", "GREEN"),
  Expected_Liberalism = c("Most Liberal", "Middle", "Most Conservative"),
  Expected_Volatility = c("Stable", "Volatile", "Stable"),
  stringsAsFactors = FALSE
)

# Add actual patterns
actual_lib_order <- actual_lib_pattern$generation_label
actual_vol_order <- actual_volatility_pattern$generation_label[1] # most volatile

verification_summary$Actual_Liberalism_Rank <- match(verification_summary$Generation, actual_lib_order)
verification_summary$Actual_Most_Volatile <- verification_summary$Generation == actual_vol_order

cat("Verification table:\n")
print(verification_summary)

# Check if patterns match expectations
lib_match <- identical(actual_lib_order, c("1st Generation", "2nd Generation", "3rd+ Generation"))
vol_match <- actual_vol_order == "2nd Generation"

cat("\nPATTERN VERIFICATION RESULTS:\n")
cat("============================\n")
cat(paste("Liberalism order matches expectation:", lib_match, "\n"))
cat(paste("2nd generation is most volatile:", vol_match, "\n"))

if (!lib_match) {
  cat("\nWARNING: Liberalism order does NOT match expected pattern!\n")
  cat("Expected: 1st (most liberal) -> 2nd (middle) -> 3rd+ (most conservative)\n")
  cat("Actual:  ", paste(actual_lib_order, collapse = " -> "), "\n")
}

if (!vol_match) {
  cat("\nWARNING: 2nd generation is NOT the most volatile!\n")
  cat("Most volatile generation:", actual_vol_order, "\n")
}

# Save results
write_csv(verification_summary, "outputs/generation_pattern_verification.csv")
write_csv(liberalism_summary, "outputs/liberalism_patterns_by_generation.csv")
write_csv(variance_analysis, "outputs/variance_analysis_by_generation.csv")

cat("\nVerification complete. Results saved to outputs/\n")
