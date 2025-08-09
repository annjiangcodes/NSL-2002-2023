# =============================================================================
# GOLD STANDARD VISUALIZATION UPDATE
# =============================================================================
# Purpose: Update all current visualizations to match the gold standard
# shown in the three-indices plot with proper colors, labels, and formatting
# Date: 2025-08-09
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(stringr)
  library(ggrepel)
  library(survey)
  library(scales)
  library(gridExtra)
  library(grid)
})

message("=== GOLD STANDARD VISUALIZATION UPDATE START ===")

# =============================================================================
# GOLD STANDARD THEME AND COLORS
# =============================================================================

# Gold standard publication theme (matching the reference image exactly)
gold_standard_theme <- theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Arial"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0, margin = margin(b = 5)),
    plot.subtitle = element_text(size = 13, color = "gray40", hjust = 0, margin = margin(b = 15)),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0, margin = margin(t = 10)),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# Gold standard color palette (matching the reference image)
gold_generation_colors <- c(
  "First Generation" = "#2166ac",   # Blue
  "Second Generation" = "#762a83",  # Purple  
  "Third+ Generation" = "#5aae61"   # Green
)

# Standard source attribution
standard_caption <- "Source: National Survey of Latinos, 2002-2022. 95% confidence intervals shown."

# =============================================================================
# LOAD AND PREPARE DATA
# =============================================================================

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

# Prepare data with gold standard generation labels
df_processed <- df %>%
  filter(survey_year >= 2002 & survey_year <= 2022) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation",
      immigrant_generation >= 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(generation_label))

# Available measures
candidate_measures <- c(
  "liberalism_index", "restrictionism_index", "concern_index",
  "legalization_support", "daca_support", "border_wall_support",
  "deportation_policy_support", "border_security_support",
  "deportation_concern"
)
present_measures <- candidate_measures[candidate_measures %in% names(df_processed)]

# Output directory
output_dir <- "current/outputs/CURRENT_2025_08_09_FIGURES_gold_standard"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Function to compute yearly weighted means with confidence intervals
compute_yearly_weighted_with_ci <- function(data, var_name, wcol, by_generation = TRUE) {
  grouped <- if (by_generation) c("survey_year", "generation_label") else c("survey_year")
  data %>%
    filter(!is.na(.data[[var_name]]), !is.na(.data[[wcol]])) %>%
    group_by(across(all_of(grouped))) %>%
    summarise(
      W = sum(.data[[wcol]], na.rm = TRUE),
      weighted_mean = ifelse(W > 0, sum(.data[[var_name]] * .data[[wcol]], na.rm = TRUE) / W, NA_real_),
      # FIXED: Proper weighted variance and SE calculation
      weighted_var = ifelse(n() > 1 & W > 0, 
                           sum(.data[[wcol]] * (.data[[var_name]] - weighted_mean)^2, na.rm = TRUE) / W,
                           0),
      se = ifelse(n() > 1 & W > 0,
                  sqrt(weighted_var / n()),  # Simple approach avoiding division by zero
                  0),  # For single observations, SE = 0
      n = dplyr::n(),
      .groups = "drop"
    ) %>%
    filter(!is.na(weighted_mean)) %>%
    mutate(
      variable = var_name,
      # FIXED: Handle cases where SE is 0 or very small
      ci_lower = ifelse(se > 0, weighted_mean - 1.96 * se, weighted_mean),
      ci_upper = ifelse(se > 0, weighted_mean + 1.96 * se, weighted_mean)
    )
}

# =============================================================================
# 1. THREE INDICES PLOT (GOLD STANDARD RECREATION)
# =============================================================================

message("1. Creating three indices plot (gold standard recreation)...")

three_indices <- c("liberalism_index", "restrictionism_index", "concern_index")
trend_data_three <- bind_rows(lapply(three_indices, function(v) {
  compute_yearly_weighted_with_ci(df_processed, v, weight_col, by_generation = TRUE)
})) %>%
  mutate(
    index_name = case_when(
      variable == "liberalism_index" ~ "Immigration Policy Liberalism",
      variable == "restrictionism_index" ~ "Immigration Policy Restrictionism", 
      variable == "concern_index" ~ "Deportation Concern"
    )
  )

p_three_indices <- ggplot(trend_data_three, aes(x = survey_year, y = weighted_mean, color = generation_label)) +
  geom_ribbon(
    aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
    alpha = 0.2, color = NA
  ) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 3, alpha = 0.9) +
  facet_wrap(~ index_name, scales = "free_y", ncol = 1) +
  scale_color_manual(values = gold_generation_colors) +
  scale_fill_manual(values = gold_generation_colors) +
  scale_x_continuous(breaks = seq(2002, 2022, 2)) +
  labs(
    title = "Immigration Attitudes by Generation: Three Key Indices (2002-2022)",
    subtitle = "Longitudinal trends for Liberalism, Restrictionism, and Deportation Concern.",
    x = "Survey Year",
    y = "Index Value (Standardized)",
    color = "Generational Status",
    fill = "Generational Status",
    caption = standard_caption
  ) +
  gold_standard_theme

ggsave(
  file.path(output_dir, "three_indices_by_generation_2002_2022.png"),
  p_three_indices,
  width = 12, height = 14, dpi = 300, bg = "white"
)

# =============================================================================
# 2. OVERALL TRENDS PLOT
# =============================================================================

message("2. Creating overall trends plot...")

pooled_data <- bind_rows(lapply(present_measures, function(v) {
  compute_yearly_weighted_with_ci(df_processed, v, weight_col, by_generation = FALSE)
}))

# Calculate trend statistics
trend_stats <- pooled_data %>%
  group_by(variable) %>%
  do({
    if (nrow(.) >= 3) {
      fit <- lm(weighted_mean ~ survey_year, data = ., weights = W)
      sm <- summary(fit)
      data.frame(
        slope = coef(fit)["survey_year"],
        p_value = sm$coefficients["survey_year", 4],
        annotation = sprintf("Slope: %.3f\np = %.3f", coef(fit)["survey_year"], sm$coefficients["survey_year", 4])
      )
    } else {
      data.frame(slope = NA, p_value = NA, annotation = "")
    }
  })

p_overall <- ggplot(pooled_data, aes(x = survey_year, y = weighted_mean)) +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper), alpha = 0.2, fill = "gray70") +
  geom_line(color = "#333333", linewidth = 1.2) +
  geom_point(color = "#333333", size = 3) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", color = "#1f78b4", linewidth = 0.8) +
  facet_wrap(~ variable, scales = "free_y") +
  labs(
    title = "Overall Immigration Attitude Trends (2002-2022)",
    subtitle = "Pooled trends across all generations with linear trend lines.",
    x = "Survey Year",
    y = "Weighted Mean Attitude",
    caption = standard_caption
  ) +
  gold_standard_theme

ggsave(
  file.path(output_dir, "overall_trends_2002_2022.png"),
  p_overall,
  width = 12, height = 8, dpi = 300, bg = "white"
)

# =============================================================================
# 3. GENERATION-STRATIFIED TRENDS
# =============================================================================

message("3. Creating generation-stratified trends plot...")

gen_data <- bind_rows(lapply(present_measures, function(v) {
  compute_yearly_weighted_with_ci(df_processed, v, weight_col, by_generation = TRUE)
}))

p_generation <- ggplot(gen_data, aes(x = survey_year, y = weighted_mean, color = generation_label)) +
  geom_ribbon(
    aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
    alpha = 0.2, color = NA
  ) +
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 3, alpha = 0.9) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.8) +
  facet_wrap(~ variable, scales = "free_y") +
  scale_color_manual(values = gold_generation_colors) +
  scale_fill_manual(values = gold_generation_colors) +
  labs(
    title = "Immigration Attitude Trends by Generation (2002-2022)",
    subtitle = "Generational differences in attitude trajectories with linear trend lines.",
    x = "Survey Year",
    y = "Weighted Mean Attitude",
    color = "Generational Status",
    fill = "Generational Status",
    caption = standard_caption
  ) +
  gold_standard_theme

ggsave(
  file.path(output_dir, "generation_trends_2002_2022.png"),
  p_generation,
  width = 12, height = 10, dpi = 300, bg = "white"
)

# =============================================================================
# 4. CROSS-SECTIONAL MEANS
# =============================================================================

message("4. Creating cross-sectional means plot...")

survey_design <- svydesign(ids = ~1, data = df_processed, weights = as.formula(paste0("~", weight_col)))

cross_sectional_data <- bind_rows(lapply(present_measures, function(measure) {
  formula <- as.formula(paste0("~", measure))
  
  # FIXED: Calculate mean and SE by generation with explicit vartype
  result <- svyby(formula, by = ~generation_label, design = survey_design, svymean, 
                  na.rm = TRUE, vartype = "se")
  
  # FIXED: Robust column handling - check actual structure
  result_df <- as.data.frame(result)
  
  # Extract generation labels (always first column)
  generation_labels <- result_df[, 1]
  
  # Find mean and SE columns (could be named se.measure or just se)
  mean_col <- which(grepl(paste0("^", measure, "$"), names(result_df)))
  se_col <- which(grepl(paste0("^se(\\.", measure, ")?$"), names(result_df)))
  
  if (length(mean_col) != 1 || length(se_col) != 1) {
    stop("Could not identify mean and SE columns for ", measure, 
         ". Available columns: ", paste(names(result_df), collapse = ", "))
  }
  
  # Create clean output
  data.frame(
    generation_label = generation_labels,
    mean = result_df[, mean_col],
    se = result_df[, se_col],
    variable = measure,
    stringsAsFactors = FALSE
  )
})) %>%
  mutate(
    ci_lower = mean - 1.96 * se,
    ci_upper = mean + 1.96 * se
  )

p_cross_sectional <- ggplot(cross_sectional_data, aes(x = generation_label, y = mean, fill = generation_label)) +
  geom_col(alpha = 0.8) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    width = 0.2, linewidth = 1
  ) +
  facet_wrap(~ variable, scales = "free_y") +
  scale_fill_manual(values = gold_generation_colors) +
  labs(
    title = "Cross-Sectional Immigration Attitudes by Generation",
    subtitle = "Mean attitudes with 95% confidence intervals across all survey years.",
    x = "Generational Status",
    y = "Weighted Mean Attitude",
    caption = standard_caption
  ) +
  gold_standard_theme +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(
  file.path(output_dir, "cross_sectional_means.png"),
  p_cross_sectional,
  width = 12, height = 8, dpi = 300, bg = "white"
)

# =============================================================================
# 5. SAMPLE SIZES PLOT
# =============================================================================

message("5. Creating sample sizes plot...")

sample_sizes <- df_processed %>%
  group_by(survey_year, generation_label) %>%
  summarise(n = n(), .groups = "drop")

p_sample_sizes <- ggplot(sample_sizes, aes(x = factor(survey_year), y = n, fill = generation_label)) +
  geom_col() +
  geom_text(aes(label = n), position = position_stack(vjust = 0.5), size = 3, color = "white", fontface = "bold") +
  scale_fill_manual(values = gold_generation_colors) +
  labs(
    title = "Sample Sizes by Survey Year and Generation",
    subtitle = "Number of respondents per generational group for each survey wave.",
    x = "Survey Year",
    y = "Number of Respondents",
    fill = "Generational Status",
    caption = "Source: National Survey of Latinos, 2002-2022"
  ) +
  gold_standard_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(
  file.path(output_dir, "sample_sizes_by_year.png"),
  p_sample_sizes,
  width = 12, height = 8, dpi = 300, bg = "white"
)

# =============================================================================
# 6. GENERATION COMPOSITION
# =============================================================================

message("6. Creating generation composition plot...")

generation_proportions <- df_processed %>%
  count(survey_year, generation_label) %>%
  group_by(survey_year) %>%
  mutate(proportion = n / sum(n)) %>%
  ungroup()

p_composition <- ggplot(generation_proportions, aes(x = factor(survey_year), y = proportion, fill = generation_label)) +
  geom_col(position = "fill") +
  geom_text(
    aes(label = scales::percent(proportion, accuracy = 1)),
    position = position_fill(vjust = 0.5),
    size = 3, color = "white", fontface = "bold"
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = gold_generation_colors) +
  labs(
    title = "Generational Composition by Survey Year",
    subtitle = "Proportional representation of each generation across survey waves.",
    x = "Survey Year",
    y = "Proportion of Sample",
    fill = "Generational Status",
    caption = "Source: National Survey of Latinos, 2002-2022"
  ) +
  gold_standard_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(
  file.path(output_dir, "generation_composition_by_year.png"),
  p_composition,
  width = 12, height = 8, dpi = 300, bg = "white"
)

message("=== GOLD STANDARD VISUALIZATION UPDATE COMPLETE ===")
message("All plots updated and saved to: ", output_dir)
