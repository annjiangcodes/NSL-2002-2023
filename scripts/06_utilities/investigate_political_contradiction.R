# ============================================================================
# INVESTIGATING THE CONTRADICTION: Immigration Attitudes vs Political Movement
# ============================================================================
# 
# PUZZLE: Our data shows Latinos becoming LESS restrictive on immigration (2002-2023)
# BUT: Media reports suggest Latinos moving toward Trump/right-wing politics (2016-2024)
# 
# Let's investigate this contradiction by examining:
# 1. Political party identification trends
# 2. Vote intention patterns 
# 3. Trump support vs immigration attitudes
# 4. Potential explanations for the discrepancy
#
# ============================================================================

library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)

cat("=== INVESTIGATING THE POLITICAL CONTRADICTION ===\n")
cat("Immigration Attitudes vs Political Movement Among Latinos\n\n")

# Read data
data <- read_csv("data/final/longitudinal_survey_data_2002_2023_COMPREHENSIVE.csv", show_col_types = FALSE)

# Clean generation variable
data <- data %>%
  mutate(
    generation = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation", 
      immigrant_generation == 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    ),
    generation = factor(generation, levels = c("First Generation", "Second Generation", "Third+ Generation"))
  )

cat("Dataset size:", nrow(data), "observations\n")
cat("Years available:", paste(sort(unique(data$survey_year)), collapse = ", "), "\n\n")

# ============================================================================
# ANALYSIS 1: POLITICAL PARTY IDENTIFICATION TRENDS
# ============================================================================

cat("=== ANALYSIS 1: POLITICAL PARTY TRENDS ===\n")

if ("political_party" %in% names(data)) {
  
  # Check what values political_party takes
  cat("Political party variable distribution:\n")
  party_dist <- table(data$political_party, useNA = "ifany")
  print(party_dist)
  
  # Look at trends over time
  party_trends <- data %>%
    filter(!is.na(political_party), !is.na(generation)) %>%
    group_by(survey_year, generation, political_party) %>%
    summarise(n = n(), .groups = "drop") %>%
    group_by(survey_year, generation) %>%
    mutate(
      total = sum(n),
      pct = round(100 * n / total, 1)
    ) %>%
    ungroup()
  
  cat("\nPolitical party percentages by year and generation:\n")
  print(party_trends)
  
  # Focus on recent years (2016+) for Republican trends
  recent_party <- party_trends %>%
    filter(survey_year >= 2016) %>%
    select(survey_year, generation, political_party, pct) %>%
    pivot_wider(names_from = political_party, values_from = pct, values_fill = 0)
  
  cat("\nRecent political party trends (2016+):\n")
  print(recent_party)
  
} else {
  cat("Political party variable not available\n")
}

# ============================================================================
# ANALYSIS 2: PARTY IDENTIFICATION VARIABLE
# ============================================================================

cat("\n\n=== ANALYSIS 2: PARTY IDENTIFICATION TRENDS ===\n")

if ("party_identification" %in% names(data)) {
  
  party_id_dist <- table(data$party_identification, useNA = "ifany")
  cat("Party identification distribution:\n")
  print(party_id_dist)
  
  # Trends over time
  party_id_trends <- data %>%
    filter(!is.na(party_identification), !is.na(generation)) %>%
    group_by(survey_year, generation) %>%
    summarise(
      n = n(),
      mean_party_id = round(mean(party_identification, na.rm = TRUE), 3),
      .groups = "drop"
    ) %>%
    filter(n >= 50)  # Minimum sample size
  
  cat("\nParty identification trends (higher = more Republican):\n")
  print(party_id_trends)
  
  # Calculate change over time
  if (nrow(party_id_trends) > 0) {
    party_change <- party_id_trends %>%
      group_by(generation) %>%
      summarise(
        first_year = min(survey_year),
        last_year = max(survey_year),
        first_party = mean_party_id[survey_year == min(survey_year)],
        last_party = mean_party_id[survey_year == max(survey_year)],
        change = last_party - first_party,
        direction = case_when(
          change > 0.1 ~ "More Republican",
          change < -0.1 ~ "More Democratic", 
          TRUE ~ "Stable"
        ),
        .groups = "drop"
      )
    
    cat("\nOverall party identification change:\n")
    print(party_change)
  }
  
} else {
  cat("Party identification variable not available\n")
}

# ============================================================================
# ANALYSIS 3: TRUMP SUPPORT vs IMMIGRATION ATTITUDES
# ============================================================================

cat("\n\n=== ANALYSIS 3: TRUMP SUPPORT vs IMMIGRATION ATTITUDES ===\n")

if ("trump_support" %in% names(data) && "immigration_attitude" %in% names(data)) {
  
  # Correlation analysis
  trump_immigration <- data %>%
    filter(!is.na(trump_support), !is.na(immigration_attitude), !is.na(generation))
  
  if (nrow(trump_immigration) > 0) {
    cat("Sample with both Trump support and immigration attitude data:", nrow(trump_immigration), "\n")
    cat("Years:", paste(sort(unique(trump_immigration$survey_year)), collapse = ", "), "\n\n")
    
    # Correlation by generation
    correlations <- trump_immigration %>%
      group_by(generation) %>%
      summarise(
        n = n(),
        correlation = round(cor(trump_support, immigration_attitude, use = "complete.obs"), 3),
        trump_mean = round(mean(trump_support, na.rm = TRUE), 3),
        immigration_mean = round(mean(immigration_attitude, na.rm = TRUE), 3),
        .groups = "drop"
      )
    
    cat("Correlation between Trump support and immigration restrictiveness:\n")
    print(correlations)
    
    # Are people who support Trump more restrictive on immigration?
    trump_by_attitude <- trump_immigration %>%
      mutate(
        trump_supporter = ifelse(trump_support > 0.5, "Trump Supporter", "Trump Non-Supporter"),
        restrictive_attitude = ifelse(immigration_attitude > median(immigration_attitude, na.rm = TRUE), 
                                    "More Restrictive", "Less Restrictive")
      ) %>%
      group_by(generation, trump_supporter, restrictive_attitude) %>%
      summarise(n = n(), .groups = "drop") %>%
      group_by(generation, trump_supporter) %>%
      mutate(pct = round(100 * n / sum(n), 1))
    
    cat("\nImmigration attitudes by Trump support:\n")
    print(trump_by_attitude)
  }
  
} else {
  cat("Trump support or immigration attitude variables not available for correlation\n")
}

# ============================================================================
# ANALYSIS 4: EXAMINING THE CONTRADICTION
# ============================================================================

cat("\n\n=== ANALYSIS 4: POTENTIAL EXPLANATIONS ===\n")

# Check recent vs earlier periods
recent_vs_early <- data %>%
  filter(!is.na(immigration_attitude), !is.na(generation)) %>%
  mutate(
    period = case_when(
      survey_year <= 2012 ~ "Early (2002-2012)",
      survey_year >= 2016 ~ "Recent (2016-2023)",
      TRUE ~ "Middle (2013-2015)"
    )
  ) %>%
  filter(period != "Middle (2013-2015)") %>%
  group_by(period, generation) %>%
  summarise(
    n = n(),
    mean_immigration_attitude = round(mean(immigration_attitude, na.rm = TRUE), 3),
    .groups = "drop"
  )

cat("Immigration attitudes: Early vs Recent periods\n")
print(recent_vs_early)

# Check if there are sample composition changes
sample_composition <- data %>%
  filter(!is.na(generation)) %>%
  group_by(survey_year) %>%
  summarise(
    total_n = n(),
    pct_first_gen = round(100 * sum(generation == "First Generation") / n(), 1),
    pct_second_gen = round(100 * sum(generation == "Second Generation") / n(), 1),
    pct_third_gen = round(100 * sum(generation == "Third+ Generation") / n(), 1),
    .groups = "drop"
  ) %>%
  filter(survey_year %in% c(2002, 2016, 2018, 2022))

cat("\nSample composition over time (key years):\n")
print(sample_composition)

# ============================================================================
# SUMMARY AND HYPOTHESES
# ============================================================================

cat("\n\n=== POTENTIAL EXPLANATIONS FOR THE CONTRADICTION ===\n")

cat("1. ISSUE-SPECIFIC vs GENERAL POLITICS:\n")
cat("   - Immigration attitudes may be distinct from general political alignment\n")
cat("   - Latinos may support liberal immigration policy while being conservative on other issues\n\n")

cat("2. SAMPLE vs POPULATION:\n")
cat("   - Survey respondents may differ from general Latino electorate\n")
cat("   - Non-response bias could affect results\n\n")

cat("3. GEOGRAPHIC VARIATION:\n")
cat("   - Media reports may focus on specific states/regions (TX, FL, NV)\n")
cat("   - National averages may mask important regional differences\n\n")

cat("4. VOTING vs ATTITUDES:\n")
cat("   - Voting behavior may not directly reflect immigration attitudes\n")
cat("   - Other issues (economy, religion, etc.) may drive vote choice\n\n")

cat("5. TIMING DIFFERENCES:\n")
cat("   - Our latest data is 2022-2023\n")
cat("   - Media reports may reflect very recent changes (2023-2024)\n\n")

cat("6. MEASUREMENT DIFFERENCES:\n")
cat("   - Academic surveys vs political polling may capture different aspects\n")
cat("   - Question wording and context effects\n\n")

cat("=== RECOMMENDED NEXT STEPS ===\n")
cat("1. Analyze geographic/state-level patterns\n")
cat("2. Examine other political attitudes (economy, social issues)\n")
cat("3. Compare with external polling data\n")
cat("4. Investigate demographic subgroups (age, education, religion)\n")
cat("5. Look for interaction effects between issues\n\n")

cat("Analysis completed:", Sys.time(), "\n") 