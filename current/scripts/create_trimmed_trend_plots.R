## VISUALIZATIONS: TRIMMED NO FIXED EFFECTS Trend Plots — v2.9w NOFE
## Reads the comprehensive dataset, computes yearly weighted means (pooled and
## by generation) for 2002-2022, and outputs PNG figures with annotations.
## Inputs:  data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
## Outputs: current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/
##            - 1_overall_trend_NOFE_2002_2022.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(ggrepel)
})

message("=== VIS: TRIMMED NO FE TREND PLOTS START ===")

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

# Filter for 2002-2022
df <- df %>% filter(survey_year >= 2002 & survey_year <= 2022)

# Measures to visualize
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

# ... (previous code)

# Output directory
fig_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"
if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

# Define publication theme
publication_theme <- theme_minimal(base_size = 14) +
  theme(
    text = element_text(size = 12),
    plot.title = element_text(size = 16, face = "bold", hjust = 0),
    plot.subtitle = element_text(size = 13, color = "gray40", hjust = 0),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold"),
    plot.background = element_rect(fill = "white", color = NA)
  )

# ... (rest of the script)


# ----------------------------------------------------------------------------
# Overall trends plot (pooled) with annotations
# ----------------------------------------------------------------------------
pooled_list <- lapply(present_measures, function(v) compute_yearly_weighted(df, v, weight_col, by_generation = FALSE))
pooled_df <- bind_rows(pooled_list)

# Calculate trendline stats for annotations
trend_stats <- pooled_df %>%
  group_by(variable) %>%
  do({
    fit <- lm(weighted_mean ~ survey_year, data = ., weights = W)
    sm <- summary(fit)
    data.frame(
      slope = coef(fit)["survey_year"],
      p_value = sm$coefficients["survey_year", 4]
    )
  }) %>%
  mutate(
    annotation = sprintf("Slope: %.3f\np-value: %.3f", slope, p_value)
  )

if (nrow(pooled_df) > 0) {
  p_overall <- ggplot(pooled_df, aes(x = as.numeric(survey_year), y = weighted_mean)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray70") +
    geom_line(color = "#333333", linewidth = 0.8) +
    geom_point(color = "#333333", size = 1.8) +
    geom_smooth(method = "lm", se = FALSE, linetype = "dotted", color = "#1f78b4", linewidth = 0.7) +
    geom_text_repel(
      data = trend_stats,
      aes(x = Inf, y = -Inf, label = annotation),
      hjust = 1.1, vjust = -0.5, size = 3, color = "gray30",
      inherit.aes = FALSE
    ) +
    facet_wrap(~ variable, scales = "free_y") +
    labs(
      title = "Overall Attitude Trends (2002-2022)",
      subtitle = "Weighted OLS on yearly means (NOFE). Slope and p-value shown for trend line.",
      x = "Year", 
      y = "Weighted Mean Attitude",
      caption = "Source: National Survey of Latinos, 2002-2022"
    ) +
    publication_theme

  ggsave(
    file.path(fig_dir, "1_overall_trend_NOFE_2002_2022.png"),
    p_overall,
    width = 12, height = 8, dpi = 300, bg = "white"
  )
  message("Saved: ", file.path(fig_dir, "1_overall_trend_NOFE_2002_2022.png"))
} else {
  message("[WARN] No pooled yearly means available; skipping overall plot")
}

# ----------------------------------------------------------------------------
# Generation-stratified trends plot
# ----------------------------------------------------------------------------
gen_list <- lapply(present_measures, function(v) compute_yearly_weighted(df, v, weight_col, by_generation = TRUE))
gen_df <- bind_rows(gen_list)

# Calculate trendline stats for annotations
gen_trend_stats <- gen_df %>%
  group_by(variable, generation_label) %>%
  do({
    fit <- lm(weighted_mean ~ survey_year, data = ., weights = W)
    sm <- summary(fit)
    data.frame(
      slope = coef(fit)["survey_year"],
      p_value = sm$coefficients["survey_year", 4]
    )
  }) %>%
  mutate(
    annotation = sprintf("p=%.2f", p_value)
  )

if (nrow(gen_df) > 0) {
  p_gen <- ggplot(gen_df, aes(x = as.numeric(survey_year), y = weighted_mean, color = generation_label)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray80") +
    geom_line(linewidth = 0.8) +
    geom_point(size = 1.7) +
    geom_smooth(method = "lm", se = FALSE, linetype = "dotted", linewidth = 0.6) +
    geom_text_repel(
      data = gen_trend_stats,
      aes(x = Inf, y = -Inf, label = annotation),
      hjust = 1.1, vjust = -0.7, size = 2.5,
      inherit.aes = FALSE,
      direction = "y",
      segment.color = "transparent"
    ) +
    scale_color_manual(values = c("1st Generation" = "#E41A1C", "2nd Generation" = "#377EB8", "3rd+ Generation" = "#4DAF4A")) +
    facet_wrap(~ variable, scales = "free_y") +
    labs(
      title = "Generational Attitude Trends (2002-2022)",
      subtitle = "Weighted OLS on yearly means (NOFE), with p-values for trend lines.",
      x = "Year", y = "Weighted Mean", color = "Generation",
      caption = "Source: National Survey of Latinos, 2002-2022"
      ) +
    publication_theme
    
  ggsave(
    file.path(fig_dir, "2_generation_trends_NOFE_2002_2022.png"),
    p_gen,
    width = 12, height = 9, dpi = 300,
    bg = "white"
  )
  message("Saved: ", file.path(fig_dir, "2_generation_trends_NOFE_2002_2022.png"))
} else {
  message("[WARN] No generation yearly means available; skipping generation plot")
}

message("=== VIS: TRIMMED NO FE TREND PLOTS COMPLETE ===")


