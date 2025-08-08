## CREATE GENERATION COMPOSITION PLOT ##
#
# Description:
# This script creates a 100% stacked bar chart to visualize the 
# proportional composition of immigrant generations for each survey year.
#
# Input:
# - data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
#
# Output:
# - current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/8_generation_composition_by_year.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(ggplot2)
  library(scales)
})

message("=== CREATE GENERATION COMPOSITION PLOT START ===")

# ----------------------------------------------------------------------------
# Load data
# ----------------------------------------------------------------------------
input_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
if (!file.exists(input_path)) stop("Input file not found: ", input_path)
df <- read_csv(input_path, show_col_types = FALSE)

# Generation labels and filtering
df <- df %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation >= 3 ~ "3rd+ Generation",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(generation_label), survey_year >= 2002 & survey_year <= 2022)

# ----------------------------------------------------------------------------
# Calculate proportions
# ----------------------------------------------------------------------------
generation_proportions <- df %>%
  count(survey_year, generation_label) %>%
  group_by(survey_year) %>%
  mutate(proportion = n / sum(n)) %>%
  ungroup()

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
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold"),
    plot.background = element_rect(fill = "white", color = NA)
  )

# ... (rest of the script)

p <- ggplot(generation_proportions, aes(x = factor(survey_year), y = proportion, fill = generation_label)) +
  geom_col(position = "fill") +
  geom_text(
    aes(label = scales::percent(proportion, accuracy = 1)),
    position = position_fill(vjust = 0.5),
    size = 3,
    color = "white"
  ) +
  scale_y_continuous(labels = scales::percent) +
  scale_fill_manual(values = c("1st Generation" = "#E41A1C", "2nd Generation" = "#377EB8", "3rd+ Generation" = "#4DAF4A")) +
  labs(
    title = "Generational Composition by Year (2002-2022)",
    subtitle = "Proportional breakdown of generational status for each survey year.",
    x = "Survey Year",
    y = "Proportion",
    fill = "Generation",
    caption = "Source: National Survey of Latinos, 2002-2022"
  ) +
  publication_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# ----------------------------------------------------------------------------
# Save plot
# ----------------------------------------------------------------------------
output_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

output_path <- file.path(output_dir, "8_generation_composition_by_year.png")
ggsave(
  output_path,
  plot = p,
  width = 12,
  height = 8,
  dpi = 300,
  bg = "white"
)
message("Saved plot: ", output_path)

message("=== CREATE GENERATION COMPOSITION PLOT COMPLETE ===")

