# =============================================================================
# PUBLICATION VISUALIZATION v3.0 - MAXIMUM DATA UTILIZATION FIX
# =============================================================================
# Purpose: Create publication-quality visualization using v3.0 corrected dataset
#          with fixed file paths restoring missing generation data
# Version: 3.0 (January 2025) - MAJOR UPDATE  
# Previous: v2.9 used data with file path issues, v3.0 uses corrected full dataset
# Key Focus: Maximum data utilization + publication-quality visualization
# =============================================================================

library(dplyr)
library(ggplot2)
library(readr)
library(tidyr)
library(RColorBrewer)

cat("=================================================================\n")
cat("PUBLICATION VISUALIZATION v3.0 - MAXIMUM DATA UTILIZATION\n") 
cat("=================================================================\n")

# =============================================================================
# 1. LOAD WEIGHTED DATA & STATISTICAL RESULTS
# =============================================================================

cat("\n1. LOADING PRE-CALCULATED WEIGHTED DATA...\n")

# Load the generation trend data from v3.0 analysis
generation_trends_path <- "outputs/generation_trends_v2_7.csv"
if (!file.exists(generation_trends_path)) {
  stop("ERROR: Generation trends data file not found. Please run the v3.0 analysis first.")
}
generation_means <- read_csv(generation_trends_path, show_col_types = FALSE)
cat("Loaded generation trends:", nrow(generation_means), "rows\n")

# Load the statistical trend results for annotations  
trend_results_path <- "outputs/generation_trends_results_v2_7.csv"
if (!file.exists(trend_results_path)) {
  stop("ERROR: Trend results file not found. Please run the v3.0 analysis first.")
}
trend_results <- read_csv(trend_results_path, show_col_types = FALSE)
cat("Loaded trend results:", nrow(trend_results), "rows\n")

# =============================================================================
# 2. DATA PREPARATION FOR VISUALIZATION
# =============================================================================

cat("\n2. PREPARING DATA FOR VISUALIZATION...\n")

# Clean and prepare data - reshape to long format for both indices
liberalism_data <- generation_means %>%
  filter(!is.na(liberalism_mean), liberalism_n >= 30) %>%
  select(survey_year, generation_label, liberalism_mean) %>%
  mutate(index_label = "Immigration Policy Liberalism", weighted_mean = liberalism_mean)

restrictionism_data <- generation_means %>%
  filter(!is.na(restrictionism_mean), restrictionism_n >= 30) %>%
  select(survey_year, generation_label, restrictionism_mean) %>%
  mutate(index_label = "Immigration Policy Restrictionism", weighted_mean = restrictionism_mean)

# Combine the data
viz_data <- bind_rows(liberalism_data, restrictionism_data) %>%
  mutate(
    # Ensure generation is a factor with a logical order
    generation = factor(generation_label, levels = c("First Generation", "Second Generation", "Third+ Generation"))
  ) %>%
  select(-generation_label, -liberalism_mean, -restrictionism_mean)

# Prepare annotation data
annotation_data <- trend_results %>%
  filter(index %in% c("Immigration Policy Liberalism", "Immigration Policy Restrictionism")) %>%
  mutate(
    # Create a label with slope and significance
    annotation_label = paste0(
      "Slope = ", round(slope, 3), 
      " (p = ", round(p_value, 3), significance, ")"
    ),
    # Use index as is since it already has the right labels
    index_label = index,
    generation = factor(scope, levels = c("First Generation", "Second Generation", "Third+ Generation"))
  ) %>%
  # Position annotations at the end of the trend line
  group_by(generation, index_label) %>%
  summarise(
    survey_year = max(as.numeric(strsplit(years, ", ")[[1]])),
    annotation_label = first(annotation_label),
    .groups = 'drop'
  ) %>%
  left_join(viz_data, by = c("survey_year", "generation", "index_label"))


# =============================================================================
# 3. CREATE PUBLICATION-QUALITY VISUALIZATION
# =============================================================================

cat("\n3. GENERATING PUBLICATION-QUALITY PLOT...\n")

# Define a professional color palette
color_palette <- brewer.pal(3, "Set2")

# Create the plot
p <- ggplot(viz_data, aes(x = survey_year, y = weighted_mean, color = generation, group = generation)) +
  
  # Main plot layers
  geom_line(linewidth = 1.2, alpha = 0.8) +
  geom_point(size = 2.5) +
  
  # Facet by the two main immigration indices
  facet_wrap(~index_label) +
  
  # Add smooth trend lines (linear model)
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed", linewidth = 0.8, alpha = 0.7) +
  
  # Add annotations for the trend lines
  geom_text(
    data = annotation_data,
    aes(label = annotation_label),
    nudge_y = 0.05,
    size = 3.5,
    fontface = "italic",
    hjust = 0.6
  ) +
  
  # Aesthetics and labels
  scale_color_manual(values = color_palette, name = "Immigrant Generation") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 4)) +
  
  labs(
    title = "Generational Trends in U.S. Hispanic Immigration Attitudes (2002-2023)",
    subtitle = "Survey-weighted estimates show a pattern of generational convergence and polarization.",
    x = "Survey Year",
    y = "Standardized Index Score (Weighted Mean)",
    caption = "Source: Analysis of Pew Research Center National Survey of Latinos data (v2.8). Slopes and p-values from linear regression."
  ) +
  
  # Theme and styling
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(size = 18, face = "bold", margin = margin(b = 5)),
    plot.subtitle = element_text(size = 12, margin = margin(b = 15)),
    plot.caption = element_text(size = 9, color = "grey40", hjust = 0),
    strip.text = element_text(size = 12, face = "bold"),
    axis.title = element_text(size = 11, face = "bold"),
    legend.position = "bottom",
    legend.title = element_text(size = 10, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "#f7f7f7", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

# Export the plot
output_path <- "outputs/figure_v3_0_publication_maximum_data_trends.png"
ggsave(output_path, p, width = 14, height = 8, dpi = 300)

cat("\n=================================================================\n")
cat("SUCCESS: v3.0 Publication-quality visualization exported to:\n")
cat(output_path, "\n")
cat("=================================================================\n") 