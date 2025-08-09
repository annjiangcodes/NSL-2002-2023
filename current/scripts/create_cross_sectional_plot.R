## CREATE CROSS-SECTIONAL MEANS PLOT (NOFE) ##
#
# Description:
# This script generates a bar/point plot showing the weighted cross-sectional 
# means of attitude measures by generation, including 95% confidence intervals.
#
# Input:
# - data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
#
# Output:
# - current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/4_cross_sectional_means_NOFE.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(survey)
})

message("=== CREATE CROSS-SECTIONAL MEANS PLOT (NOFE) START ===")

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

# Measures to visualize
candidate_measures <- c(
  "liberalism_index", "restrictionism_index",
  "legalization_support", "daca_support", "border_wall_support",
  "deportation_policy_support", "border_security_support",
  "deportation_concern"
)
present_measures <- candidate_measures[candidate_measures %in% names(df)]
if (length(present_measures) == 0) stop("No attitude measures available for visualization")

# ----------------------------------------------------------------------------
# Calculate weighted means and CIs
# ----------------------------------------------------------------------------
survey_design <- svydesign(ids = ~1, data = df, weights = as.formula(paste0("~", weight_col)))

cross_sectional_data <- lapply(present_measures, function(measure) {
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
  clean_result <- data.frame(
    generation_label = generation_labels,
    mean = result_df[, mean_col],
    se = result_df[, se_col],
    variable = measure,
    stringsAsFactors = FALSE
  )
  
  clean_result
})

cross_sectional_df <- bind_rows(cross_sectional_data) %>%
  mutate(
    ci_lower = mean - 1.96 * se,
    ci_upper = mean + 1.96 * se
  )

# ----------------------------------------------------------------------------
# Create plot
# ----------------------------------------------------------------------------
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
    legend.position = "none",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold"),
    plot.background = element_rect(fill = "white", color = NA)
  )

# ... (rest of the script)

p <- ggplot(cross_sectional_df, aes(x = generation_label, y = mean, fill = generation_label)) +
  geom_col(position = "dodge") +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    width = 0.2,
    position = position_dodge(0.9)
  ) +
  facet_wrap(~ variable, scales = "free_y") +
  scale_fill_manual(values = c("1st Generation" = "#E41A1C", "2nd Generation" = "#377EB8", "3rd+ Generation" = "#4DAF4A")) +
  labs(
    title = "Cross-Sectional Weighted Means by Generation (NOFE)",
    subtitle = "Error bars represent 95% confidence intervals.",
    x = "Generation",
    y = "Weighted Mean Attitude",
    caption = "Source: National Survey of Latinos, 2002-2022"
  ) +
  publication_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ----------------------------------------------------------------------------
# Save plot
# ----------------------------------------------------------------------------
output_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_path <- file.path(output_dir, "4_cross_sectional_means_NOFE.png")
ggsave(
  output_path,
  plot = p,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)
message("Saved plot: ", output_path)

message("=== CREATE CROSS-SECTIONAL MEANS PLOT (NOFE) COMPLETE ===")

