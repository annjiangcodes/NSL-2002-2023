# ANALYSIS v2.9 RE-EVALUATION SCRIPT
# Purpose: Recompute generational trends, verify v2.8 claims, and surface analyses likely to be significant
# Inputs: data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
# Outputs (CSV):
#   outputs/v2_9_trend_results.csv
#   outputs/v2_9_interaction_test.csv
#   outputs/v2_9_period_effects.csv
#   outputs/v2_9_component_trends.csv
#   outputs/v2_9_cross_sectional_diffs.csv
#   outputs/v2_9_volatility_comparison.csv

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

message("=== ANALYSIS v2.9 RE-EVALUATION START ===")

# -----------------------------------------------------------------------------
# Load data
# -----------------------------------------------------------------------------
input_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
if (!file.exists(input_path)) {
  stop("Input file not found: ", input_path)
}

df <- read_csv(input_path, show_col_types = FALSE)

# Minimal required columns
required_cols <- c("survey_year", "immigrant_generation")
missing_required <- setdiff(required_cols, names(df))
if (length(missing_required) > 0) stop("Missing required columns: ", paste(missing_required, collapse = ", "))

# Create generation label
label_df <- df %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation >= 3 ~ "3rd+ Generation",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(generation_label))

# Identify attitude variables present
candidate_measures <- c(
  liberal = "liberalism_index",
  restrict = "restrictionism_index",
  legal = "legalization_support",
  daca = "daca_support",
  wall = "border_wall_support",
  deport = "deportation_policy_support",
  bordersec = "border_security_support",
  concern = "deportation_concern"
)

present_measures <- candidate_measures[candidate_measures %in% names(label_df)]
if (length(present_measures) == 0) stop("No attitude measures found in dataset.")

# Helper to compute yearly means by generation for one variable
compute_yearly_means <- function(data, var_name) {
  data %>%
    filter(!is.na(.data[[var_name]])) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      mean_value = mean(.data[[var_name]], na.rm = TRUE),
      n = dplyr::n(),
      .groups = "drop"
    ) %>%
    mutate(variable = var_name)
}

# -----------------------------------------------------------------------------
# 1) Trend tests by generation (yearly means ~ year)
# -----------------------------------------------------------------------------
trend_results <- list()
for (var in present_measures) {
  yearly <- compute_yearly_means(label_df, var)
  for (gen in unique(yearly$generation_label)) {
    sub <- yearly %>% filter(generation_label == gen) %>% arrange(survey_year)
    if (nrow(sub) >= 3) {
      fit <- lm(mean_value ~ survey_year, data = sub)
      sm <- summary(fit)
      slope <- unname(coef(fit)["survey_year"])
      pval <- sm$coefficients["survey_year", 4]
      trend_results[[length(trend_results) + 1]] <- data.frame(
        generation = gen,
        variable = var,
        slope = slope,
        p_value = pval,
        n_years = nrow(sub),
        significance = ifelse(pval < 0.001, "***", ifelse(pval < 0.01, "**", ifelse(pval < 0.05, "*", "ns"))),
        stringsAsFactors = FALSE
      )
    }
  }
}

trend_results_df <- dplyr::bind_rows(trend_results)

# -----------------------------------------------------------------------------
# 2) Generation x Year interaction (aggregated, weighted by n of yearly cell)
# -----------------------------------------------------------------------------
interaction_tests <- list()
for (var in present_measures) {
  yearly <- compute_yearly_means(label_df, var)
  if (nrow(yearly) >= 9) {
    # Center year for stability
    yearly <- yearly %>% mutate(year_c = as.numeric(survey_year) - mean(as.numeric(survey_year), na.rm = TRUE))
    # Use weights = n (approximate)
    fit <- lm(mean_value ~ year_c * generation_label, data = yearly, weights = n)
    an <- anova(fit)
    # Extract interaction row
    row_ix <- which(rownames(an) == "year_c:generation_label")
    if (length(row_ix) == 1) {
      interaction_tests[[length(interaction_tests) + 1]] <- data.frame(
        variable = var,
        df_interaction = an$Df[row_ix],
        F_value = an$`F value`[row_ix],
        p_value = an$`Pr(>F)`[row_ix],
        significance = ifelse(an$`Pr(>F)`[row_ix] < 0.001, "***", ifelse(an$`Pr(>F)`[row_ix] < 0.01, "**", ifelse(an$`Pr(>F)`[row_ix] < 0.05, "*", "ns"))),
        stringsAsFactors = FALSE
      )
    }
  }
}

interaction_tests_df <- dplyr::bind_rows(interaction_tests)

# -----------------------------------------------------------------------------
# 3) Period effects (Bush, Obama, Trump, Biden) by generation
# -----------------------------------------------------------------------------
assign_era <- function(y) {
  if (is.na(y)) return(NA_character_)
  if (y <= 2008) return("Bush")
  if (y <= 2016) return("Obama")
  if (y <= 2020) return("Trump")
  return("Biden")
}

period_effects <- list()
for (var in present_measures) {
  tmp <- label_df %>%
    filter(!is.na(.data[[var]])) %>%
    mutate(era = vapply(survey_year, assign_era, character(1))) %>%
    group_by(era, generation_label) %>%
    summarise(mean_value = mean(.data[[var]], na.rm = TRUE), n = dplyr::n(), .groups = "drop") %>%
    mutate(variable = var)
  period_effects[[length(period_effects) + 1]] <- tmp
}
period_effects_df <- dplyr::bind_rows(period_effects)

# -----------------------------------------------------------------------------
# 4) Component-level trends (per variable, by generation)
#    This is covered by trend_results_df; filter to component variables only
# -----------------------------------------------------------------------------
component_vars <- intersect(present_measures, c("legalization_support", "daca_support", "border_wall_support", "deportation_policy_support", "border_security_support"))
component_trends_df <- trend_results_df %>% filter(variable %in% component_vars)

# -----------------------------------------------------------------------------
# 5) Cross-sectional differences (overall means by generation, t-tests)
# -----------------------------------------------------------------------------
xsumm_list <- list()
for (var in present_measures) {
  # Overall means by generation
  means <- label_df %>%
    filter(!is.na(.data[[var]])) %>%
    group_by(generation_label) %>%
    summarise(mean_value = mean(.data[[var]], na.rm = TRUE), n = dplyr::n(), .groups = "drop") %>%
    mutate(variable = var)
  xsumm_list[[length(xsumm_list) + 1]] <- means
}
xsumm_df <- dplyr::bind_rows(xsumm_list)

# -----------------------------------------------------------------------------
# 6) Volatility comparisons (variance of yearly means by generation)
# -----------------------------------------------------------------------------
vol_list <- list()
for (var in present_measures) {
  yearly <- compute_yearly_means(label_df, var)
  vol <- yearly %>%
    group_by(generation_label) %>%
    summarise(
      n_years = n(),
      variance = var(mean_value, na.rm = TRUE),
      sd = sd(mean_value, na.rm = TRUE),
      range = max(mean_value, na.rm = TRUE) - min(mean_value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(variable = var)
  vol_list[[length(vol_list) + 1]] <- vol
}
volatility_df <- dplyr::bind_rows(vol_list)

# -----------------------------------------------------------------------------
# Write outputs
# -----------------------------------------------------------------------------
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)

write_csv(trend_results_df, "outputs/v2_9_trend_results.csv")
write_csv(interaction_tests_df, "outputs/v2_9_interaction_test.csv")
write_csv(period_effects_df, "outputs/v2_9_period_effects.csv")
write_csv(component_trends_df, "outputs/v2_9_component_trends.csv")
write_csv(xsumm_df, "outputs/v2_9_cross_sectional_diffs.csv")
write_csv(volatility_df, "outputs/v2_9_volatility_comparison.csv")

# -----------------------------------------------------------------------------
# Brief console summary of statistically significant findings
# -----------------------------------------------------------------------------
message("\n--- SUMMARY OF LIKELY SIGNIFICANT FINDINGS (UNWEIGHTED) ---")
# Significant component trends
sig_components <- component_trends_df %>% filter(significance %in% c("*", "**", "***"))
if (nrow(sig_components) > 0) {
  message("Component trends (significant): ")
  print(sig_components %>% arrange(variable, generation))
} else {
  message("No significant component trends (at p<0.05) in aggregated yearly means.")
}

# Significant gen x year interaction
sig_inter <- interaction_tests_df %>% filter(significance %in% c("*", "**", "***"))
if (nrow(sig_inter) > 0) {
  message("\nGeneration x Year interaction significant for:")
  print(sig_inter %>% arrange(variable))
} else {
  message("\nGeneration x Year interaction not significant (aggregated test).")
}

# Cross-sectional differences: just report ordering
message("\nCross-sectional generation ordering by measure (overall means):")
xsumm_df %>% group_by(variable) %>% arrange(desc(mean_value), .by_group = TRUE) %>%
  summarise(ordering = paste(generation_label, collapse = ">"), .groups = "drop") %>% print(n = Inf)

message("\nVolatility (variance of yearly means) – lower = more stable:")
volatility_df %>% group_by(variable) %>% arrange(variance, .by_group = TRUE) %>%
  summarise(ordering = paste0(generation_label, " (", sprintf("%.3f", variance), ")", collapse = ", "), .groups = "drop") %>% print(n = Inf)

message("\n=== ANALYSIS v2.9 RE-EVALUATION COMPLETE ===")
