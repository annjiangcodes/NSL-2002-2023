# Quick Trend Visualization
library(dplyr)
library(readr)
library(ggplot2)

# Read data
data <- read_csv("data/final/longitudinal_survey_data_2002_2023_COMPREHENSIVE.csv", show_col_types = FALSE)

# Clean generation variable
data <- data %>%
  mutate(
    generation = case_when(
      immigrant_generation == 1 ~ "First Generation",
      immigrant_generation == 2 ~ "Second Generation", 
      immigrant_generation == 3 ~ "Third+ Generation",
      TRUE ~ NA_character_
    ),
    generation = factor(generation, levels = c("First Generation", "Second Generation", "Third+ Generation"))
  )

# Create trend data for immigration attitude
trend_data <- data %>%
  filter(!is.na(immigration_attitude), !is.na(generation)) %>%
  group_by(survey_year, generation) %>%
  summarise(
    n = n(),
    mean_attitude = mean(immigration_attitude, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n >= 100)  # Only include cells with substantial sample size

# Create plot
p1 <- ggplot(trend_data, aes(x = survey_year, y = mean_attitude, color = generation)) +
  geom_line(size = 1.2) +
  geom_point(size = 3) +
  labs(
    title = "Latino Immigration Attitudes by Generation: 2002-2023",
    subtitle = "Higher values = More restrictive attitudes",
    x = "Survey Year",
    y = "Mean Immigration Attitude",
    color = "Generation",
    caption = "Note: Preliminary analysis - not adjusted for covariates"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12),
    legend.title = element_text(face = "bold")
  ) +
  scale_color_manual(values = c("First Generation" = "#e31a1c", 
                                "Second Generation" = "#1f78b4", 
                                "Third+ Generation" = "#33a02c"))

ggsave("immigration_attitudes_by_generation_trend.png", p1, width = 12, height = 8, dpi = 300)

# Create summary table
summary_table <- trend_data %>%
  group_by(generation) %>%
  summarise(
    first_year = min(survey_year),
    last_year = max(survey_year),
    first_attitude = mean_attitude[survey_year == min(survey_year)],
    last_attitude = mean_attitude[survey_year == max(survey_year)],
    total_change = last_attitude - first_attitude,
    direction = ifelse(total_change < -0.1, "LESS Restrictive", 
                      ifelse(total_change > 0.1, "MORE Restrictive", "Stable"))
  )

cat("\n=== SUMMARY OF DIRECTIONAL TRENDS ===\n")
print(summary_table)

cat("\n✅ Visualization saved as: immigration_attitudes_by_generation_trend.png\n") 