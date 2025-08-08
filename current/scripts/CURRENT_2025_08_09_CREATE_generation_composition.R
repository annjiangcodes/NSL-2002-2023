# =============================================================================
# GENERATION COMPOSITION BY YEAR (GOLD STANDARD)
# =============================================================================
# Purpose: Create generation composition visualization matching gold standard
# Date: 2025-08-09
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(scales)
})

message("=== GENERATION COMPOSITION BY YEAR (GOLD STANDARD) START ===")

# =============================================================================
# GOLD STANDARD THEME AND COLORS
# =============================================================================

gold_standard_theme <- theme_minimal() +
  theme(
    text = element_text(size = 12, family = "Arial"),
    plot.title = element_text(size = 16, face = "bold", hjust = 0, margin = margin(b = 8)),
    plot.subtitle = element_text(size = 13, color = "gray40", hjust = 0, margin = margin(b = 12)),
    plot.caption = element_text(size = 10, color = "gray50", hjust = 0, margin = margin(t = 12)),
    axis.title = element_text(size = 12, face = "bold"),
    axis.text = element_text(size = 11),
    legend.title = element_text(size = 12, face = "bold"),
    legend.text = element_text(size = 11),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90", linewidth = 0.5),
    strip.text = element_text(size = 12, face = "bold"),
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    legend.background = element_rect(fill = "white", color = NA)
  )

# Gold standard colors for generations
generation_colors <- c(
  "First Generation" = "#2166ac",   # Blue
  "Second Generation" = "#762a83",  # Purple  
  "Third+ Generation" = "#5aae61"   # Green
)

# =============================================================================
# LOAD AND PREPARE DATA
# =============================================================================

# Load the comprehensive dataset
data_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"

if (!file.exists(data_path)) {
  stop("Data file not found: ", data_path)
}

df <- read_csv(data_path, show_col_types = FALSE)
message("Data loaded: ", nrow(df), " observations")

# Clean and prepare generation labels
df_clean <- df %>%
  filter(!is.na(immigrant_generation), 
         survey_year >= 2002, 
         survey_year <= 2022) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation", 
      immigrant_generation >= 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(generation_label))

message("Cleaned data: ", nrow(df_clean), " observations with valid generation labels")

# =============================================================================
# CALCULATE GENERATION COMPOSITION BY YEAR
# =============================================================================

composition_data <- df_clean %>%
  group_by(survey_year, generation_label) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(survey_year) %>%
  mutate(
    total = sum(count),
    percentage = (count / total) * 100,
    proportion = count / total
  ) %>%
  ungroup()

# Check data availability
message("Years with data: ", paste(sort(unique(composition_data$survey_year)), collapse = ", "))
message("Sample by generation overall:")
overall_composition <- df_clean %>%
  group_by(generation_label) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(percentage = (count / sum(count)) * 100)
print(overall_composition)

# =============================================================================
# CREATE VISUALIZATION
# =============================================================================

# Ensure generation factor levels match colors
composition_data$generation_label <- factor(
  composition_data$generation_label,
  levels = names(generation_colors)
)

# Create stacked percentage plot
p <- ggplot(composition_data, aes(x = survey_year, y = percentage, fill = generation_label)) +
  geom_area(alpha = 0.8, position = "stack") +
  geom_line(aes(color = generation_label), position = "identity", 
            data = composition_data, linewidth = 1.2, alpha = 0.9) +
  scale_fill_manual(values = generation_colors, name = "Generational Status") +
  scale_color_manual(values = generation_colors, name = "Generational Status") +
  scale_x_continuous(breaks = seq(2002, 2022, by = 2)) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), 
                     breaks = seq(0, 100, by = 20),
                     limits = c(0, 100)) +
  labs(
    title = "Generational Composition of Sample by Year (2002-2022)",
    subtitle = "Percentage distribution of Latino respondents by generational status over time.",
    x = "Survey Year",
    y = "Percentage of Sample",
    caption = "Source: National Survey of Latinos, 2002-2022. Shows proportion of each generation in yearly samples."
  ) +
  gold_standard_theme +
  guides(
    fill = guide_legend(override.aes = list(alpha = 0.8, color = NA)),
    color = "none"
  )

# =============================================================================
# SAVE VISUALIZATION
# =============================================================================

output_dir <- "current/outputs/CURRENT_2025_08_09_FIGURES_gold_standard"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

output_path <- file.path(output_dir, "generation_composition_by_year.png")

ggsave(
  output_path,
  plot = p,
  width = 12,
  height = 8,
  units = "in",
  dpi = 300,
  bg = "white"
)

message("Generation composition plot saved: ", output_path)

# =============================================================================
# SUMMARY STATISTICS
# =============================================================================

# Overall composition summary
message("\n=== GENERATION COMPOSITION SUMMARY ===")
summary_stats <- composition_data %>%
  group_by(generation_label) %>%
  summarise(
    avg_percentage = mean(percentage),
    min_percentage = min(percentage),
    max_percentage = max(percentage),
    years_present = n(),
    .groups = "drop"
  )

print(summary_stats)

# Year-by-year breakdown
message("\n=== YEAR-BY-YEAR BREAKDOWN ===")
yearly_breakdown <- composition_data %>%
  select(survey_year, generation_label, count, percentage) %>%
  pivot_wider(names_from = generation_label, 
              values_from = c(count, percentage),
              names_sep = "_")

print(yearly_breakdown)

message("=== GENERATION COMPOSITION BY YEAR (GOLD STANDARD) COMPLETE ===")
