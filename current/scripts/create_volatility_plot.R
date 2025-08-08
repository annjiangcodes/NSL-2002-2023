## CREATE VOLATILITY PLOT (NOFE) ##
#
# Description:
# This script calculates and visualizes the volatility (standard deviation 
# of yearly weighted means) of attitude measures by generation.
#
# Input:
# - data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
#
# Output:
# - current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/5_volatility_NOFE.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

message("=== CREATE VOLATILITY PLOT (NOFE) START ===")

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
# Calculate volatility
# ----------------------------------------------------------------------------
yearly_means <- bind_rows(lapply(present_measures, function(measure) {
    df %>%
        filter(!is.na(.data[[measure]]), !is.na(.data[[weight_col]])) %>%
        group_by(survey_year, generation_label) %>%
        summarise(
            weighted_mean = weighted.mean(.data[[measure]], .data[[weight_col]], na.rm = TRUE),
            .groups = "drop"
        ) %>%
        mutate(variable = measure)
}))

volatility_data <- yearly_means %>%
  group_by(variable, generation_label) %>%
  summarise(
    volatility = sd(weighted_mean, na.rm = TRUE),
    .groups = "drop"
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

# ... (rest of script)

p <- ggplot(volatility_data, aes(x = variable, y = volatility, fill = generation_label)) +
  geom_col(position = "dodge") +
  facet_wrap(~ generation_label, scales = "free_x") +
  scale_fill_manual(values = c("1st Generation" = "#E41A1C", "2nd Generation" = "#377EB8", "3rd+ Generation" = "#4DAF4A")) +
  labs(
    title = "Attitude Volatility by Generation (NOFE)",
    subtitle = "Volatility measured as the standard deviation of yearly weighted means.",
    x = "Attitude Measure",
    y = "Volatility (Standard Deviation)",
    caption = "Source: National Survey of Latinos, 2002-2022"
  ) +
  publication_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ----------------------------------------------------------------------------
# Save plot
# ----------------------------------------------------------------------------
output_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_path <- file.path(output_dir, "5_volatility_NOFE.png")
ggsave(
  output_path,
  plot = p,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)
message("Saved plot: ", output_path)

message("=== CREATE VOLATILITY PLOT (NOFE) COMPLETE ===")

