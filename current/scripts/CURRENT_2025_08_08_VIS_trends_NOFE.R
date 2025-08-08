## VISUALIZATIONS: NO FIXED EFFECTS Trend Plots — v2.9w NOFE
## Reads the comprehensive dataset, computes yearly weighted means (pooled and
## by generation), and outputs two PNG figures.
## Inputs:  data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
## Outputs: current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/
##            - overall_trends_NOFE.png
##            - generation_trends_NOFE.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
})

message("=== VIS: NO FE TREND PLOTS START ===")

# ----------------------------------------------------------------------------
# Load data
# ----------------------------------------------------------------------------
input_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
if (!file.exists(input_path)) stop("Input file not found: ", input_path)
df <- read_csv(input_path, show_col_types = FALSE)

# Weight detection
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

# Generation labels
df <- df %>% mutate(
  generation_label = case_when(
    immigrant_generation == 1 ~ "1st Generation",
    immigrant_generation == 2 ~ "2nd Generation",
    immigrant_generation >= 3 ~ "3rd+ Generation",
    TRUE ~ NA_character_
  )
) %>% filter(!is.na(generation_label))

if (!"survey_year" %in% names(df)) stop("Missing 'survey_year' in dataset")

# Measures to visualize (subset of those present)
candidate_measures <- c(
  "liberalism_index", "restrictionism_index",
  "legalization_support", "daca_support", "border_wall_support",
  "deportation_policy_support", "border_security_support",
  "deportation_concern"
)
present_measures <- candidate_measures[candidate_measures %in% names(df)]
if (length(present_measures) == 0) stop("No attitude measures available for visualization")

# Helper: yearly weighted means
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

# Output directory
fig_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

# ----------------------------------------------------------------------------
# Overall trends plot (pooled)
# ----------------------------------------------------------------------------
pooled_list <- lapply(present_measures, function(v) compute_yearly_weighted(df, v, weight_col, by_generation = FALSE))
pooled_df <- bind_rows(pooled_list)

if (nrow(pooled_df) > 0) {
  p_overall <- ggplot(pooled_df, aes(x = as.numeric(survey_year), y = weighted_mean)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray70") +
    geom_line(color = "#333333", linewidth = 0.8) +
    geom_point(color = "#333333", size = 1.8) +
    geom_smooth(method = "lm", se = FALSE, linetype = "dotted", color = "#1f78b4", linewidth = 0.7) +
    facet_wrap(~ variable, scales = "free_y") +
    labs(title = "Overall Trends (NO FE, Weighted Means)", x = "Year", y = "Weighted Mean") +
    theme_minimal()
  ggsave(file.path(fig_dir, "overall_trends_NOFE.png"), p_overall, width = 12, height = 8, dpi = 300)
  message("Saved: ", file.path(fig_dir, "overall_trends_NOFE.png"))
} else {
  message("[WARN] No pooled yearly means available; skipping overall plot")
}

# ----------------------------------------------------------------------------
# Generation-stratified trends plot
# ----------------------------------------------------------------------------
gen_list <- lapply(present_measures, function(v) compute_yearly_weighted(df, v, weight_col, by_generation = TRUE))
gen_df <- bind_rows(gen_list)

if (nrow(gen_df) > 0) {
  p_gen <- ggplot(gen_df, aes(x = as.numeric(survey_year), y = weighted_mean, color = generation_label)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray80") +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.7) +
    geom_smooth(method = "lm", se = FALSE, linetype = "dotted", linewidth = 0.6) +
    scale_color_manual(values = c("1st Generation" = "#E41A1C", "2nd Generation" = "#377EB8", "3rd+ Generation" = "#4DAF4A")) +
    facet_wrap(~ variable, scales = "free_y") +
    labs(title = "Generation Trends (NO FE, Weighted Means)", x = "Year", y = "Weighted Mean", color = "Generation") +
    theme_minimal()
  ggsave(file.path(fig_dir, "generation_trends_NOFE.png"), p_gen, width = 12, height = 8, dpi = 300)
  message("Saved: ", file.path(fig_dir, "generation_trends_NOFE.png"))
} else {
  message("[WARN] No generation yearly means available; skipping generation plot")
}

message("=== VIS: NO FE TREND PLOTS COMPLETE ===")


