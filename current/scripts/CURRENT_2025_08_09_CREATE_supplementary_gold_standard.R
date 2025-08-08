# =============================================================================
# SUPPLEMENTARY GOLD STANDARD VISUALIZATIONS
# =============================================================================
# Purpose: Create additional visualizations (data coverage, volatility, 
# significance tables) that match the gold standard formatting
# Date: 2025-08-09
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(readr)
  library(tidyr)
  library(stringr)
  library(gridExtra)
  library(grid)
})

message("=== SUPPLEMENTARY GOLD STANDARD VISUALIZATIONS START ===")

# =============================================================================
# GOLD STANDARD THEME AND COLORS (CONSISTENT)
# =============================================================================

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

gold_generation_colors <- c(
  "First Generation" = "#2166ac",   # Blue
  "Second Generation" = "#762a83",  # Purple  
  "Third+ Generation" = "#5aae61"   # Green
)

output_dir <- "current/outputs/CURRENT_2025_08_09_FIGURES_gold_standard"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# =============================================================================
# 1. DATA COVERAGE MATRIX
# =============================================================================

message("1. Creating data coverage matrix...")

# Load coverage data
coverage_df <- read_csv("outputs/v2_9c_coverage_summary.csv", show_col_types = FALSE) %>%
  filter(year_range != "Inf--Inf")

# Process coverage matrix
coverage_matrix <- coverage_df %>%
  mutate(
    start_year = as.integer(str_extract(year_range, "^\\d{4}")),
    end_year = as.integer(str_extract(year_range, "\\d{4}$"))
  ) %>%
  rowwise() %>%
  mutate(survey_year = list(seq(from = start_year, to = end_year))) %>%
  unnest(survey_year) %>%
  select(variable, survey_year) %>%
  mutate(present = 1) %>%
  complete(variable, survey_year = 2002:2022, fill = list(present = 0))

p_coverage <- ggplot(coverage_matrix, aes(x = survey_year, y = variable, fill = factor(present))) +
  geom_tile(color = "white", linewidth = 1.5) +
  scale_fill_manual(
    values = c("0" = "gray90", "1" = "#2166ac"),
    name = "Data Availability",
    labels = c("Not Available", "Available")
  ) +
  scale_x_continuous(breaks = seq(2002, 2022, 2)) +
  labs(
    title = "Data Coverage Matrix by Measure and Survey Year",
    subtitle = "Availability of immigration attitude measures across the survey period.",
    x = "Survey Year",
    y = "Immigration Attitude Measure",
    caption = "Source: National Survey of Latinos, 2002-2022"
  ) +
  gold_standard_theme +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(
  file.path(output_dir, "data_coverage_matrix.png"),
  p_coverage,
  width = 12, height = 8, dpi = 300, bg = "white"
)

# =============================================================================
# 2. VOLATILITY ANALYSIS
# =============================================================================

message("2. Creating volatility analysis...")

# Load and prepare data
input_path <- "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv"
df <- read_csv(input_path, show_col_types = FALSE)

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

# Calculate yearly means for volatility
measures_for_volatility <- c("liberalism_index", "restrictionism_index", "concern_index")

yearly_means <- bind_rows(lapply(measures_for_volatility, function(measure) {
  df_processed %>%
    filter(!is.na(.data[[measure]])) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      weighted_mean = mean(.data[[measure]], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(variable = measure)
}))

# Calculate volatility (standard deviation of yearly means)
volatility_data <- yearly_means %>%
  group_by(variable, generation_label) %>%
  summarise(
    volatility = sd(weighted_mean, na.rm = TRUE),
    n_years = n(),
    .groups = "drop"
  ) %>%
  mutate(
    variable_label = case_when(
      variable == "liberalism_index" ~ "Immigration Policy Liberalism",
      variable == "restrictionism_index" ~ "Immigration Policy Restrictionism", 
      variable == "concern_index" ~ "Deportation Concern"
    )
  )

p_volatility <- ggplot(volatility_data, aes(x = generation_label, y = volatility, fill = generation_label)) +
  geom_col(alpha = 0.8) +
  geom_text(aes(label = sprintf("%.3f", volatility)), vjust = -0.5, fontface = "bold") +
  facet_wrap(~ variable_label, scales = "free_y") +
  scale_fill_manual(values = gold_generation_colors) +
  labs(
    title = "Attitude Volatility by Generation (2002-2022)",
    subtitle = "Standard deviation of yearly attitude means, indicating stability over time.",
    x = "Generational Status",
    y = "Volatility (Standard Deviation)",
    caption = "Source: National Survey of Latinos, 2002-2022. Lower values indicate more stable attitudes."
  ) +
  gold_standard_theme +
  theme(
    legend.position = "none",
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(
  file.path(output_dir, "volatility_by_generation.png"),
  p_volatility,
  width = 12, height = 8, dpi = 300, bg = "white"
)

# =============================================================================
# 3. ENHANCED SIGNIFICANCE TABLE
# =============================================================================

message("3. Creating enhanced significance table...")

# Read and process significance data
sig_data <- read_csv("current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/3_significance_table_NOFE.csv", show_col_types = FALSE)

# Clean up the significance table for better presentation
sig_clean <- sig_data %>%
  rename(
    "Attitude Measure" = variable,
    "Overall" = `Overall Population`,
    "First Gen." = `1st Generation`,
    "Second Gen." = `2nd Generation`, 
    "Third+ Gen." = `3rd+ Generation`
  ) %>%
  mutate(
    `Attitude Measure` = case_when(
      `Attitude Measure` == "liberalism_index" ~ "Immigration Policy Liberalism",
      `Attitude Measure` == "restrictionism_index" ~ "Immigration Policy Restrictionism",
      `Attitude Measure` == "legalization_support" ~ "Legalization Support",
      `Attitude Measure` == "daca_support" ~ "DACA Support",
      `Attitude Measure` == "deportation_policy_support" ~ "Deportation Policy Support",
      `Attitude Measure` == "border_security_support" ~ "Border Security Support",
      TRUE ~ `Attitude Measure`
    )
  )

# Create table visualization
table_grob <- tableGrob(
  sig_clean, 
  rows = NULL,
  theme = ttheme_minimal(
    core = list(
      fg_params = list(fontsize = 10),
      bg_params = list(fill = c("white", "gray95"), alpha = 0.8)
    ),
    colhead = list(
      fg_params = list(fontsize = 11, fontface = "bold"),
      bg_params = list(fill = "#2166ac", alpha = 0.8, col = "white")
    )
  )
)

title_grob <- textGrob(
  "Statistical Significance of Attitude Trends by Generation",
  gp = gpar(fontsize = 16, fontface = "bold")
)

subtitle_grob <- textGrob(
  "Slope coefficients with significance levels: *** p<0.001, ** p<0.01, * p<0.05, ns = not significant",
  gp = gpar(fontsize = 13, col = "gray40")
)

caption_grob <- textGrob(
  "Source: National Survey of Latinos, 2002-2022. Linear regression on yearly weighted means.",
  gp = gpar(fontsize = 10, col = "gray50")
)

# Combine all elements
combined_table <- arrangeGrob(
  title_grob, subtitle_grob, table_grob, caption_grob,
  ncol = 1, 
  heights = unit.c(
    unit(2, "line"), 
    unit(2, "line"), 
    grobHeight(table_grob), 
    unit(2, "line")
  )
)

ggsave(
  file.path(output_dir, "significance_table.png"),
  combined_table,
  width = 14, height = 8, dpi = 300, bg = "white"
)

# =============================================================================
# 4. JOINPOINT ANALYSIS SUMMARY
# =============================================================================

message("4. Creating joinpoint analysis summary...")

if (file.exists("outputs/v2_9w_joinpoint_results.csv")) {
  joinpoint_df <- read_csv("outputs/v2_9w_joinpoint_results.csv", show_col_types = FALSE)
  
  summary_table <- joinpoint_df %>%
    select(variable, best_break_year, bic_single_line, bic_two_lines, delta_bic) %>%
    rename(
      "Attitude Measure" = variable,
      "Best Break Year" = best_break_year,
      "BIC (Linear)" = bic_single_line,
      "BIC (1-Break)" = bic_two_lines,
      "ΔBIC" = delta_bic
    ) %>%
    mutate(
      `Attitude Measure` = case_when(
        `Attitude Measure` == "liberalism_index" ~ "Immigration Policy Liberalism",
        `Attitude Measure` == "restrictionism_index" ~ "Immigration Policy Restrictionism",
        `Attitude Measure` == "legalization_support" ~ "Legalization Support",
        `Attitude Measure` == "daca_support" ~ "DACA Support",
        TRUE ~ `Attitude Measure`
      )
    ) %>%
    arrange(`Attitude Measure`)
  
  joinpoint_grob <- tableGrob(
    summary_table, 
    rows = NULL,
    theme = ttheme_minimal(
      core = list(
        fg_params = list(fontsize = 10),
        bg_params = list(fill = c("white", "gray95"), alpha = 0.8)
      ),
      colhead = list(
        fg_params = list(fontsize = 11, fontface = "bold"),
        bg_params = list(fill = "#762a83", alpha = 0.8, col = "white")
      )
    )
  )
  
  joinpoint_title <- textGrob(
    "Joinpoint Analysis: Linear vs. Single-Break Models",
    gp = gpar(fontsize = 16, fontface = "bold")
  )
  
  joinpoint_subtitle <- textGrob(
    "Comparison of model fit between linear trends and single breakpoint models. Negative ΔBIC favors breakpoint model.",
    gp = gpar(fontsize = 13, col = "gray40")
  )
  
  joinpoint_caption <- textGrob(
    "Source: National Survey of Latinos, 2002-2022. BIC = Bayesian Information Criterion.",
    gp = gpar(fontsize = 10, col = "gray50")
  )
  
  combined_joinpoint <- arrangeGrob(
    joinpoint_title, joinpoint_subtitle, joinpoint_grob, joinpoint_caption,
    ncol = 1,
    heights = unit.c(
      unit(2, "line"),
      unit(2.5, "line"), 
      grobHeight(joinpoint_grob),
      unit(2, "line")
    )
  )
  
  ggsave(
    file.path(output_dir, "joinpoint_analysis_summary.png"),
    combined_joinpoint,
    width = 12, height = 6, dpi = 300, bg = "white"
  )
}

message("=== SUPPLEMENTARY GOLD STANDARD VISUALIZATIONS COMPLETE ===")
message("All supplementary plots saved to: ", output_dir)
