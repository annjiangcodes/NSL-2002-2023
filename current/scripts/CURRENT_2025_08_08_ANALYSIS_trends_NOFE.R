## TREND ANALYSIS (NO FIXED EFFECTS) — v2.9w NOFE
## Purpose: Replicate older v3-style trend analysis using simple weighted OLS
##          on yearly weighted means, without any fixed/mixed effects.
## Input:  data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
## Output: current/data/CURRENT_2025_08_08_DATA_weighted_trends_NOFE.csv
##         current/data/CURRENT_2025_08_08_DATA_generation_trends_NOFE.csv

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
})

# For R CMD check / lintr non-standard evaluation notes
utils::globalVariables(c("W", "weighted_mean", "generation_label", "survey_year"))

message("=== TREND ANALYSIS (NO FE) START ===")

# -----------------------------------------------------------------------------
# 1) Load data
# -----------------------------------------------------------------------------
input_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
if (!file.exists(input_path)) stop("Input file not found: ", input_path)

df <- read_csv(input_path, show_col_types = FALSE)
message("Loaded ", nrow(df), " observations; variables: ", ncol(df))

# Detect a weight column (fallback to uniform weights)
candidate_weights <- c(
  "survey_weight", "weight", "weights", "wgt", "wt", "newwght",
  "final_weight", "finalwgt", "FINALWGT", "WEIGHT"
)
weight_var <- candidate_weights[candidate_weights %in% names(df)]
if (length(weight_var) == 0) {
  message("[WARN] No weight column found. Using uniform weights (1.0)")
  df$.__w__ <- 1.0
  weight_col <- ".__w__"
} else {
  weight_col <- weight_var[1]
  message("[INFO] Using weight column: ", weight_col)
}

# Generation labeling (Portes framework)
df <- df %>% mutate(
  generation_label = case_when(
    immigrant_generation == 1 ~ "1st Generation",
    immigrant_generation == 2 ~ "2nd Generation",
    immigrant_generation >= 3 ~ "3rd+ Generation",
    TRUE ~ NA_character_
  )
) %>% filter(!is.na(generation_label))

if (!"survey_year" %in% names(df)) stop("Missing 'survey_year' variable in dataset")

# Measures to evaluate (use those available)
candidate_measures <- c(
  "liberalism_index", "restrictionism_index",
  "legalization_support", "daca_support", "border_wall_support",
  "deportation_policy_support", "border_security_support",
  "deportation_concern"
)
present_measures <- candidate_measures[candidate_measures %in% names(df)]
if (length(present_measures) == 0) stop("No attitude measures found in dataset")
message("Measures detected (", length(present_measures), "): ", paste(present_measures, collapse = ", "))

# -----------------------------------------------------------------------------
# 2) Helper: compute yearly weighted means
# -----------------------------------------------------------------------------
compute_yearly_weighted <- function(data, var_name, wcol, by_generation = TRUE) {
  grouped <- if (by_generation) c("survey_year", "generation_label") else c("survey_year")
  data %>%
    filter(!is.na(.data[[var_name]]), !is.na(.data[[wcol]])) %>%
    group_by(across(all_of(grouped))) %>%
    summarise(
      W = sum(.data[[wcol]], na.rm = TRUE),
      weighted_mean = ifelse(W > 0, sum(.data[[var_name]] * .data[[wcol]], na.rm = TRUE) / W, NA_real_),
      n = dplyr::n(),
      .groups = "drop"
    ) %>%
    filter(!is.na(weighted_mean)) %>%
    mutate(variable = var_name)
}

# -----------------------------------------------------------------------------
# 3) Overall trends (pooled across generations) — simple weighted OLS
# -----------------------------------------------------------------------------
overall_rows <- list()
for (var in present_measures) {
  yearly <- compute_yearly_weighted(df, var, weight_col, by_generation = FALSE) %>%
    arrange(survey_year)
  if (nrow(yearly) >= 3) {
    fit <- try(lm(weighted_mean ~ survey_year, data = yearly, weights = W), silent = TRUE)
    if (!inherits(fit, "try-error")) {
      sm <- summary(fit)
      if (nrow(sm$coefficients) >= 2 && "survey_year" %in% rownames(sm$coefficients)) {
        slope <- unname(coef(fit)["survey_year"]) 
        se    <- sm$coefficients["survey_year", 2]
        pval  <- sm$coefficients["survey_year", 4]
        overall_rows[[length(overall_rows) + 1]] <- data.frame(
          variable = var,
          scope = "Overall Population",
          slope = slope,
          se = se,
          p_value = pval,
          significance = ifelse(pval < 0.001, "***", ifelse(pval < 0.01, "**", ifelse(pval < 0.05, "*", "ns"))),
          direction = ifelse(slope > 0, "INCREASING", "DECREASING"),
          n_years = nrow(yearly),
          years = paste(yearly$survey_year, collapse = ", ")
        )
      }
    }
  }
}
overall_trends_df <- dplyr::bind_rows(overall_rows)

# -----------------------------------------------------------------------------
# 4) Generation-stratified trends — simple weighted OLS
# -----------------------------------------------------------------------------
gen_rows <- list()
for (var in present_measures) {
  yearly <- compute_yearly_weighted(df, var, weight_col, by_generation = TRUE)
  for (gen in unique(yearly$generation_label)) {
    sub <- yearly %>% filter(generation_label == gen) %>% arrange(survey_year)
    if (nrow(sub) >= 3) {
      fit <- try(lm(weighted_mean ~ survey_year, data = sub, weights = W), silent = TRUE)
      if (!inherits(fit, "try-error")) {
        sm <- summary(fit)
        if (nrow(sm$coefficients) >= 2 && "survey_year" %in% rownames(sm$coefficients)) {
          slope <- unname(coef(fit)["survey_year"]) 
          se    <- sm$coefficients["survey_year", 2]
          pval  <- sm$coefficients["survey_year", 4]
          gen_rows[[length(gen_rows) + 1]] <- data.frame(
            variable = var,
            scope = gen,
            slope = slope,
            se = se,
            p_value = pval,
            significance = ifelse(pval < 0.001, "***", ifelse(pval < 0.01, "**", ifelse(pval < 0.05, "*", ""))),
            direction = ifelse(slope > 0, "INCREASING", "DECREASING"),
            n_years = nrow(sub),
            years = paste(sub$survey_year, collapse = ", ")
          )
        }
      }
    }
  }
}
generation_trends_df <- dplyr::bind_rows(gen_rows)

# -----------------------------------------------------------------------------
# 5) Write outputs
# -----------------------------------------------------------------------------
out_dir <- "current/data"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

overall_out <- file.path(out_dir, "CURRENT_2025_08_08_DATA_weighted_trends_NOFE.csv")
gen_out     <- file.path(out_dir, "CURRENT_2025_08_08_DATA_generation_trends_NOFE.csv")

if (nrow(overall_trends_df) > 0) {
  write_csv(overall_trends_df, overall_out)
  message("Wrote overall trends: ", overall_out)
} else {
  message("[WARN] No overall trends produced (insufficient data)")
}

if (nrow(generation_trends_df) > 0) {
  write_csv(generation_trends_df, gen_out)
  message("Wrote generation trends: ", gen_out)
} else {
  message("[WARN] No generation trends produced (insufficient data)")
}

message("=== TREND ANALYSIS (NO FE) COMPLETE ===")


