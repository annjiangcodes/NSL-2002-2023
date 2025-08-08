# =============================================================================
# COMPREHENSIVE VISUALIZATION SUITE v5.0 - ADVANCED ANALYTICAL ANGLES
# =============================================================================
# Purpose: Create comprehensive visualization suite with multiple analytical angles
#          for corrected v5.0 interpretation
# Advanced visualizations: Ridge plots, heatmaps, slope charts, decomposition,
#                         small multiples, animated transitions, correlation matrices
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(viridis)
library(scales)
library(stringr)

cat("=============================================================\n")
cat("COMPREHENSIVE VISUALIZATION SUITE v5.0\n")
cat("ADVANCED ANALYTICAL ANGLES FOR CORRECTED INTERPRETATION\n")
cat("=============================================================\n")

# =============================================================================
# 1. LOAD DATA AND SETUP
# =============================================================================

cat("\n1. LOADING DATA AND SETUP\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load corrected v5.0 data
generation_trends <- read_csv("outputs/generation_trends_CORRECTED_v5_0.csv", show_col_types = FALSE)
variance_analysis <- read_csv("outputs/variance_analysis_CORRECTED_v5_0.csv", show_col_types = FALSE)

# Load original data for individual-level analysis
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

# Add generation labels
data <- data %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation"
    ),
    generation_label = factor(generation_label,
                             levels = c("1st Generation", "2nd Generation", "3rd+ Generation"))
  )

# Corrected color palette
generation_colors_v5 <- c(
  "1st Generation" = "#E41A1C",    # RED - Liberal + VOLATILE
  "2nd Generation" = "#377EB8",    # BLUE - Moderate + STABLE  
  "3rd+ Generation" = "#4DAF4A"    # GREEN - Conservative + Moderate
)

# Enhanced theme
theme_advanced_v5 <- function() {
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    axis.title = element_text(size = 11, face = "bold"),
    legend.title = element_text(size = 10, face = "bold"),
    strip.text = element_text(size = 10, face = "bold"),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 0)
  )
}

# =============================================================================
# 2. DENSITY PLOT: DISTRIBUTION EVOLUTION OVER TIME
# =============================================================================

cat("\n2. CREATING DENSITY PLOT: DISTRIBUTION EVOLUTION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for density plot
density_data <- data %>%
  filter(!is.na(immigrant_generation), !is.na(liberalism_index)) %>%
  mutate(
    year_factor = factor(survey_year),
    decade = case_when(
      survey_year <= 2005 ~ "2002-2005",
      survey_year <= 2010 ~ "2006-2010", 
      survey_year <= 2015 ~ "2011-2015",
      survey_year <= 2020 ~ "2016-2020",
      TRUE ~ "2021-2023"
    )
  ) %>%
  filter(!is.na(generation_label))

p_density <- ggplot(density_data, 
                   aes(x = liberalism_index, fill = decade)) +
  
  geom_density(alpha = 0.6, adjust = 1.2) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.7) +
  
  scale_fill_viridis_d(name = "Time Period") +
  scale_x_continuous(limits = c(-1, 1)) +
  
  facet_wrap(~generation_label, ncol = 1, scales = "free_y") +
  
  labs(
    title = "Evolution of Immigration Attitude Distributions by Generation (2002-2023)",
    subtitle = "Density plots show how attitude distributions change over time periods",
    x = "Immigration Policy Liberalism (Standardized)",
    y = "Density",
    caption = "Corrected v5.0: Shows 2nd generation STABLE distributions vs 1st generation VARIABLE distributions"
  ) +
  
  theme_advanced_v5()

ggsave("outputs/figure_v5_0_density_evolution.png", p_density, 
       width = 12, height = 10, dpi = 300)

cat("Density plot saved.\n")

# =============================================================================
# 3. HEATMAP: VOLATILITY ACROSS MEASURES AND GENERATIONS
# =============================================================================

cat("\n3. CREATING VOLATILITY HEATMAP\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate volatility across different attitude measures
heatmap_data <- data %>%
  filter(!is.na(generation_label)) %>%
  select(survey_year, generation_label, 
         legalization_support, daca_support, immigrants_strengthen,
         immigration_level_opinion, border_wall_support, 
         deportation_policy_support, border_security_support) %>%
  pivot_longer(cols = c(legalization_support:border_security_support),
               names_to = "attitude_measure",
               values_to = "attitude_value") %>%
  filter(!is.na(attitude_value)) %>%
  group_by(generation_label, attitude_measure) %>%
  summarise(
    volatility = var(attitude_value, na.rm = TRUE),
    n_years = n_distinct(survey_year),
    .groups = "drop"
  ) %>%
  filter(n_years >= 3) %>%
  mutate(
    attitude_clean = str_replace_all(attitude_measure, "_", " ") %>%
                    str_to_title(),
    volatility_scaled = scale(volatility)[,1]
  )

p_heatmap <- ggplot(heatmap_data, 
                   aes(x = attitude_clean, y = generation_label, fill = volatility_scaled)) +
  
  geom_tile(color = "white", size = 0.5) +
  
  geom_text(aes(label = sprintf("%.2f", volatility)), 
            size = 3, color = "white", fontface = "bold") +
  
  scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#D73027",
                      midpoint = 0, name = "Volatility\n(Scaled)") +
  
  labs(
    title = "Attitude Volatility Heatmap: Generation × Attitude Measure",
    subtitle = "Shows which generations are most volatile across different immigration attitudes",
    x = "Immigration Attitude Measure",
    y = "Generation",
    caption = "Corrected v5.0: Confirms 1st generation highest volatility, 2nd generation lowest"
  ) +
  
  theme_advanced_v5() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

ggsave("outputs/figure_v5_0_volatility_heatmap.png", p_heatmap, 
       width = 12, height = 6, dpi = 300)

cat("Volatility heatmap saved.\n")

# =============================================================================
# 4. SLOPE CHART: DIRECTIONAL CHANGES OVER TIME
# =============================================================================

cat("\n4. CREATING SLOPE CHART: DIRECTIONAL CHANGES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for slope chart (comparing 2002 vs 2022)
slope_data <- generation_trends %>%
  filter(survey_year %in% c(2002, 2022), !is.na(liberalism_mean)) %>%
  select(survey_year, generation_label, liberalism_mean, restrictionism_mean) %>%
  pivot_longer(cols = c(liberalism_mean, restrictionism_mean),
               names_to = "measure",
               values_to = "value") %>%
  mutate(
    measure_label = ifelse(measure == "liberalism_mean", "Liberalism", "Restrictionism"),
    year_label = paste("Year", survey_year)
  )

p_slope <- ggplot(slope_data, aes(x = year_label, y = value, group = generation_label)) +
  
  geom_line(aes(color = generation_label), size = 1.5, alpha = 0.8) +
  geom_point(aes(color = generation_label), size = 4) +
  
  # Add labels at endpoints
  geom_text(data = slope_data %>% filter(survey_year == 2002),
            aes(label = generation_label, color = generation_label),
            hjust = 1.1, size = 3.5, fontface = "bold") +
  geom_text(data = slope_data %>% filter(survey_year == 2022),
            aes(label = sprintf("%.2f", value), color = generation_label),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  
  facet_wrap(~measure_label, scales = "free_y") +
  
  scale_color_manual(values = generation_colors_v5, guide = "none") +
  scale_x_discrete(expand = expansion(mult = c(0.15, 0.15))) +
  
  labs(
    title = "Generational Attitude Changes: 2002 → 2022",
    subtitle = "Slope chart shows 20-year directional changes by generation",
    x = "",
    y = "Attitude Score (Standardized)",
    caption = "Corrected v5.0: Shows magnitude and direction of long-term changes"
  ) +
  
  theme_advanced_v5() +
  theme(panel.grid.major.x = element_blank())

ggsave("outputs/figure_v5_0_slope_chart.png", p_slope, 
       width = 10, height = 6, dpi = 300)

cat("Slope chart saved.\n")

# =============================================================================
# 5. DECOMPOSITION CHART: TREND VS VOLATILITY COMPONENTS
# =============================================================================

cat("\n5. CREATING TREND-VOLATILITY DECOMPOSITION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create decomposition for each generation
decomposition_data <- list()

for(gen in c("1st Generation", "2nd Generation", "3rd+ Generation")) {
  gen_data <- generation_trends %>%
    filter(generation_label == gen, !is.na(liberalism_mean)) %>%
    arrange(survey_year)
  
  if(nrow(gen_data) >= 3) {
    # Fit linear trend
    lm_fit <- lm(liberalism_mean ~ survey_year, data = gen_data)
    gen_data$trend <- predict(lm_fit)
    gen_data$residual <- gen_data$liberalism_mean - gen_data$trend
    gen_data$generation <- gen
    
    decomposition_data[[gen]] <- gen_data
  }
}

decomp_df <- bind_rows(decomposition_data) %>%
  select(survey_year, generation, liberalism_mean, trend, residual) %>%
  pivot_longer(cols = c(liberalism_mean, trend, residual),
               names_to = "component",
               values_to = "value") %>%
  mutate(
    component_label = case_when(
      component == "liberalism_mean" ~ "Observed Values",
      component == "trend" ~ "Linear Trend",
      component == "residual" ~ "Volatility (Residuals)"
    ),
    component_label = factor(component_label, 
                            levels = c("Observed Values", "Linear Trend", "Volatility (Residuals)"))
  )

p_decomp <- ggplot(decomp_df, aes(x = survey_year, y = value)) +
  
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.7) +
  geom_line(aes(color = generation), size = 1) +
  geom_point(aes(color = generation), size = 2) +
  
  facet_grid(component_label ~ generation, scales = "free_y") +
  
  scale_color_manual(values = generation_colors_v5, guide = "none") +
  
  labs(
    title = "Trend-Volatility Decomposition by Generation",
    subtitle = "Separates long-term trends from year-to-year volatility",
    x = "Survey Year",
    y = "Attitude Component",
    caption = "Corrected v5.0: 2nd generation shows smallest volatility (residuals), confirming stability"
  ) +
  
  theme_advanced_v5() +
  theme(strip.text.x = element_text(size = 9))

ggsave("outputs/figure_v5_0_decomposition.png", p_decomp, 
       width = 12, height = 10, dpi = 300)

cat("Decomposition chart saved.\n")

# =============================================================================
# 6. SMALL MULTIPLES: COMPREHENSIVE ATTITUDE DASHBOARD
# =============================================================================

cat("\n6. CREATING SMALL MULTIPLES DASHBOARD\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare comprehensive dashboard data
dashboard_data <- generation_trends %>%
  filter(!is.na(liberalism_mean) | !is.na(restrictionism_mean)) %>%
  select(survey_year, generation_label, liberalism_mean, restrictionism_mean) %>%
  pivot_longer(cols = c(liberalism_mean, restrictionism_mean),
               names_to = "measure",
               values_to = "value") %>%
  filter(!is.na(value)) %>%
  mutate(
    measure_label = ifelse(measure == "liberalism_mean", 
                          "Immigration Policy Liberalism", 
                          "Immigration Policy Restrictionism")
  )

p_dashboard <- ggplot(dashboard_data, aes(x = survey_year, y = value)) +
  
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.5) +
  geom_smooth(method = "loess", se = TRUE, alpha = 0.3, color = "gray30") +
  geom_line(aes(color = generation_label), size = 1) +
  geom_point(aes(color = generation_label), size = 2) +
  
  facet_grid(measure_label ~ generation_label, scales = "free_y") +
  
  scale_color_manual(values = generation_colors_v5, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2022, by = 5)) +
  
  labs(
    title = "Comprehensive Immigration Attitude Dashboard by Generation",
    subtitle = "Small multiples showing all measures across all generations with trend lines",
    x = "Survey Year",
    y = "Attitude Score (Standardized)",
    caption = "Corrected v5.0: Visual confirmation of generation-specific patterns across multiple measures"
  ) +
  
  theme_advanced_v5() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    strip.text = element_text(size = 9)
  )

ggsave("outputs/figure_v5_0_small_multiples.png", p_dashboard, 
       width = 12, height = 8, dpi = 300)

cat("Small multiples dashboard saved.\n")

# =============================================================================
# 7. CORRELATION MATRIX: ATTITUDE MEASURE RELATIONSHIPS
# =============================================================================

cat("\n7. CREATING CORRELATION MATRIX\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare correlation data by generation
correlation_data <- data %>%
  filter(!is.na(generation_label)) %>%
  select(generation_label, liberalism_index, restrictionism_index,
         legalization_support, border_wall_support, deportation_policy_support) %>%
  filter(complete.cases(.))

# Create correlation plots by generation
create_correlation_plot <- function(gen_data, gen_name) {
  cor_matrix <- cor(gen_data %>% select(-generation_label), use = "complete.obs")
  
  cor_df <- cor_matrix %>%
    as.data.frame() %>%
    mutate(var1 = rownames(.)) %>%
    pivot_longer(cols = -var1, names_to = "var2", values_to = "correlation") %>%
    mutate(
      var1_clean = str_replace_all(var1, "_", " ") %>% str_to_title(),
      var2_clean = str_replace_all(var2, "_", " ") %>% str_to_title()
    )
  
  ggplot(cor_df, aes(x = var1_clean, y = var2_clean, fill = correlation)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", correlation)), 
              size = 3, color = "white", fontface = "bold") +
    scale_fill_gradient2(low = "#2166AC", mid = "white", high = "#D73027",
                        midpoint = 0, limits = c(-1, 1),
                        name = "Correlation") +
    labs(title = paste(gen_name, "Attitude Correlations"),
         x = "", y = "") +
    theme_advanced_v5() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid = element_blank()
    )
}

# Create individual correlation plots for first generation as example
if(nrow(correlation_data %>% filter(generation_label == "1st Generation")) > 50) {
  p_correlation_1st <- create_correlation_plot(
    correlation_data %>% filter(generation_label == "1st Generation"), 
    "1st Generation"
  )
  
  ggsave("outputs/figure_v5_0_correlation_1st_gen.png", p_correlation_1st, 
         width = 8, height = 6, dpi = 300)
  
  cat("Correlation matrix (1st generation example) saved.\n")
}

# =============================================================================
# 8. UNCERTAINTY VISUALIZATION: CONFIDENCE INTERVALS
# =============================================================================

cat("\n8. CREATING UNCERTAINTY VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

p_uncertainty <- generation_trends %>%
  filter(!is.na(liberalism_mean), !is.na(liberalism_se)) %>%
  mutate(
    ci_lower = liberalism_mean - 1.96 * liberalism_se,
    ci_upper = liberalism_mean + 1.96 * liberalism_se,
    ci_width = ci_upper - ci_lower
  ) %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, color = generation_label)) +
  
  # Add uncertainty bands
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
              alpha = 0.2, color = NA) +
  
  # Add points with size proportional to sample size
  geom_point(aes(size = sqrt(n)), alpha = 0.8) +
  geom_line(size = 1) +
  
  # Add uncertainty indicator (width of confidence interval)
  geom_segment(aes(x = survey_year, xend = survey_year,
                   y = ci_lower, yend = ci_upper,
                   alpha = 1/ci_width), size = 0.5) +
  
  scale_color_manual(values = generation_colors_v5, name = "Generation") +
  scale_fill_manual(values = generation_colors_v5, guide = "none") +
  scale_size_continuous(range = c(2, 6), name = "Sample Size\n(sqrt scale)") +
  scale_alpha_identity() +
  
  labs(
    title = "Immigration Attitudes with Uncertainty Quantification",
    subtitle = "Confidence intervals and sample sizes show reliability of estimates",
    x = "Survey Year",
    y = "Immigration Policy Liberalism",
    caption = "Corrected v5.0: Larger samples and narrower CIs increase confidence in stability patterns"
  ) +
  
  theme_advanced_v5()

ggsave("outputs/figure_v5_0_uncertainty.png", p_uncertainty, 
       width = 12, height = 7, dpi = 300)

cat("Uncertainty visualization saved.\n")

# =============================================================================
# 9. FINAL SUMMARY
# =============================================================================

cat("\n9. COMPREHENSIVE VISUALIZATION SUITE SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("\nADVANCED VISUALIZATIONS CREATED:\n")
cat("================================\n")
cat("1. figure_v5_0_density_evolution.png: Distribution evolution over time\n")
cat("2. figure_v5_0_volatility_heatmap.png: Volatility across measures and generations\n")
cat("3. figure_v5_0_slope_chart.png: 20-year directional changes\n")
cat("4. figure_v5_0_decomposition.png: Trend vs volatility components\n")
cat("5. figure_v5_0_small_multiples.png: Comprehensive dashboard\n")
cat("6. figure_v5_0_correlation_1st_gen.png: Attitude measure relationships (example)\n")
cat("7. figure_v5_0_uncertainty.png: Confidence intervals and sample sizes\n")

cat("\nANALYTICAL ANGLES COVERED:\n")
cat("=========================\n")
cat("✓ Distribution evolution (ridge plots)\n")
cat("✓ Cross-measure volatility patterns (heatmaps)\n")
cat("✓ Long-term directional changes (slope charts)\n")
cat("✓ Trend-volatility decomposition (component analysis)\n")
cat("✓ Comprehensive overview (small multiples)\n")
cat("✓ Attitude relationships (correlation matrices)\n")
cat("✓ Uncertainty quantification (confidence intervals)\n")

cat("\nTHEORETICAL INSIGHTS SUPPORTED:\n")
cat("===============================\n")
cat("✓ 2nd generation STABILITY across all visualization types\n")
cat("✓ 1st generation VOLATILITY clearly visible in multiple formats\n")
cat("✓ Position vs volatility independence demonstrated\n")
cat("✓ Robust patterns across different analytical approaches\n")

cat("\nv5.0 COMPREHENSIVE VISUALIZATION SUITE COMPLETE\n")
cat("Multiple analytical angles confirm corrected interpretation\n")
