# =============================================================================
# ADVANCED VISUALIZATIONS v4.0 - PUBLICATION-QUALITY GRAPHICS
# =============================================================================
# Purpose: Create sophisticated visualizations for academic publications
#          Including innovative approaches and journal-ready formatting
# Version: 4.0
# Date: January 2025
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(ggridges)
library(ggalluvial)
library(gganimate)
library(patchwork)
library(viridis)
library(RColorBrewer)
library(scales)
library(grid)
library(gridExtra)
library(cowplot)

cat("=============================================================\n")
cat("ADVANCED VISUALIZATIONS v4.0\n")
cat("=============================================================\n")

# =============================================================================
# 1. LOAD PREPARED DATA
# =============================================================================

cat("\n1. LOADING ANALYSIS OUTPUTS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load saved analysis outputs
overall_trends <- read_csv("outputs/overall_trends_v4_0.csv", show_col_types = FALSE)
generation_trends <- read_csv("outputs/generation_year_trends_v4_0.csv", show_col_types = FALSE)
period_effects <- read_csv("outputs/period_effects_v4_0.csv", show_col_types = FALSE)
regression_results <- read_csv("outputs/regression_results_v4_0.csv", show_col_types = FALSE)

# Load original data for additional analyses
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", show_col_types = FALSE)

# =============================================================================
# 2. THEME AND COLOR SETUP
# =============================================================================

# Enhanced publication theme
theme_publication_enhanced <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
  theme(
    # Title elements
    plot.title = element_text(size = rel(1.4), face = "bold", 
                             margin = margin(b = 10), hjust = 0),
    plot.subtitle = element_text(size = rel(1.1), color = "gray30", 
                                margin = margin(b = 10), hjust = 0),
    plot.caption = element_text(size = rel(0.8), color = "gray50", 
                               hjust = 0, margin = margin(t = 10)),
    
    # Axis elements
    axis.title = element_text(size = rel(1), face = "bold"),
    axis.text = element_text(size = rel(0.9)),
    axis.line = element_line(color = "gray70", size = 0.5),
    
    # Legend elements
    legend.title = element_text(size = rel(1), face = "bold"),
    legend.text = element_text(size = rel(0.9)),
    legend.key.size = unit(1.2, "lines"),
    
    # Panel elements
    panel.grid.major = element_line(color = "gray90", size = 0.5),
    panel.grid.minor = element_blank(),
    panel.background = element_rect(fill = "white", color = NA),
    panel.border = element_rect(fill = NA, color = "gray70", size = 0.5),
    
    # Strip elements (for facets)
    strip.text = element_text(size = rel(1.1), face = "bold"),
    strip.background = element_rect(fill = "gray95", color = "gray70"),
    
    # Overall plot
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(20, 20, 20, 20)
  )
}

# Color schemes
generation_palette <- c(
  "1st Generation" = "#D73027",    # Red
  "2nd Generation" = "#4575B4",    # Blue  
  "3rd+ Generation" = "#91BFDB"    # Light blue
)

attitude_palette <- c(
  "Liberalism" = "#1B7837",        # Green
  "Restrictionism" = "#762A83",    # Purple
  "Net Liberalism" = "#5AAE61",    # Light green
  "Concern" = "#FEE08B"            # Yellow
)

period_palette <- c(
  "Early Bush Era" = "#E66101",
  "Immigration Debates" = "#FDB863",
  "Economic Crisis" = "#B2ABD2",
  "Obama Era" = "#5E3C99",
  "Trump Era" = "#E7298A",
  "COVID & Biden Era" = "#66C2A5"
)

# =============================================================================
# 3. ADVANCED VISUALIZATION 1: RIDGE PLOT
# =============================================================================

cat("\n3. CREATING RIDGE PLOT VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for ridge plot
ridge_data <- data %>%
  filter(!is.na(immigrant_generation), !is.na(liberalism_index)) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation"
    ),
    generation_label = factor(generation_label, 
                             levels = c("3rd+ Generation", "2nd Generation", "1st Generation")),
    year_factor = factor(survey_year)
  )

p_ridge <- ggplot(ridge_data, 
                 aes(x = liberalism_index, y = year_factor, fill = generation_label)) +
  
  geom_density_ridges(
    alpha = 0.7,
    scale = 3,
    rel_min_height = 0.01,
    panel_scaling = TRUE,
    quantile_lines = TRUE,
    quantiles = 2
  ) +
  
  scale_fill_manual(values = generation_palette, name = "Immigrant Generation") +
  scale_x_continuous(limits = c(-2, 2)) +
  
  labs(
    title = "Distribution of Immigration Policy Liberalism Over Time",
    subtitle = "Density ridges show changing distributions by generation with median lines",
    x = "Immigration Policy Liberalism Score",
    y = "Survey Year",
    caption = "Source: NSL 2002-2023. Higher values indicate more pro-immigration attitudes."
  ) +
  
  theme_publication_enhanced() +
  theme(legend.position = "bottom")

ggsave("outputs/figure_v4_0_ridge_distributions.png", 
       p_ridge, width = 10, height = 12, dpi = 300)

# =============================================================================
# 4. ADVANCED VISUALIZATION 2: ALLUVIAL/FLOW DIAGRAM
# =============================================================================

cat("\n4. CREATING ALLUVIAL FLOW DIAGRAM\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for alluvial plot - tracking attitude categories over time
alluvial_data <- data %>%
  filter(!is.na(immigrant_generation), 
         !is.na(liberalism_index),
         survey_year %in% c(2002, 2012, 2022)) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Gen",
      immigrant_generation == 2 ~ "2nd Gen",
      immigrant_generation == 3 ~ "3rd+ Gen"
    ),
    attitude_category = case_when(
      liberalism_index > 0.5 ~ "Strongly Liberal",
      liberalism_index > 0 ~ "Moderately Liberal",
      liberalism_index > -0.5 ~ "Neutral",
      liberalism_index > -1 ~ "Moderately Restrictive",
      TRUE ~ "Strongly Restrictive"
    ),
    attitude_category = factor(attitude_category,
                              levels = c("Strongly Liberal", "Moderately Liberal",
                                       "Neutral", "Moderately Restrictive",
                                       "Strongly Restrictive"))
  ) %>%
  group_by(survey_year, generation_label, attitude_category) %>%
  summarise(freq = n(), .groups = "drop") %>%
  mutate(year_label = paste0("Year ", survey_year))

p_alluvial <- ggplot(alluvial_data,
                    aes(x = year_label, y = freq, stratum = attitude_category,
                        alluvium = attitude_category, fill = attitude_category)) +
  
  geom_flow(alpha = 0.7) +
  geom_stratum(width = 0.3, alpha = 0.9) +
  
  facet_wrap(~generation_label, scales = "free_y", ncol = 1) +
  
  scale_fill_manual(
    values = c("Strongly Liberal" = "#1B7837",
               "Moderately Liberal" = "#5AAE61",
               "Neutral" = "#FFFFBF",
               "Moderately Restrictive" = "#DFC27D",
               "Strongly Restrictive" = "#A6611A"),
    name = "Attitude Category"
  ) +
  
  labs(
    title = "Flow of Immigration Attitudes Across Two Decades",
    subtitle = "Tracking attitude category changes from 2002 to 2022 by generation",
    x = "Time Period",
    y = "Number of Respondents",
    caption = "Source: NSL data. Flow width represents number of respondents in each category."
  ) +
  
  theme_publication_enhanced() +
  theme(legend.position = "bottom")

ggsave("outputs/figure_v4_0_alluvial_flow.png", 
       p_alluvial, width = 12, height = 10, dpi = 300)

# =============================================================================
# 5. ADVANCED VISUALIZATION 3: ANIMATED TRENDS
# =============================================================================

cat("\n5. CREATING ANIMATED VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for animation
anim_data <- generation_trends %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  mutate(
    generation_label = factor(generation_label,
                             levels = c("1st Generation", "2nd Generation", "3rd+ Generation"))
  )

p_anim <- ggplot(anim_data, 
                aes(x = liberalism_mean, y = restrictionism_mean, 
                    color = generation_label, size = n)) +
  
  geom_point(alpha = 0.7) +
  
  # Add reference lines
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  
  # Add quadrant labels
  annotate("text", x = -0.5, y = 0.5, label = "Liberal &\nRestrictive", 
           size = 4, color = "gray40", fontface = "italic") +
  annotate("text", x = 0.5, y = 0.5, label = "Conservative &\nRestrictive", 
           size = 4, color = "gray40", fontface = "italic") +
  annotate("text", x = -0.5, y = -0.5, label = "Liberal &\nPermissive", 
           size = 4, color = "gray40", fontface = "italic") +
  annotate("text", x = 0.5, y = -0.5, label = "Conservative &\nPermissive", 
           size = 4, color = "gray40", fontface = "italic") +
  
  scale_color_manual(values = generation_palette, name = "Generation") +
  scale_size_continuous(range = c(3, 10), name = "Sample Size") +
  
  labs(
    title = "Immigration Attitude Space by Generation: {closest_state}",
    subtitle = "Position shows combination of liberalism and restrictionism scores",
    x = "Immigration Policy Liberalism →",
    y = "Immigration Policy Restrictionism →",
    caption = "Source: NSL 2002-2023. Point size reflects sample size."
  ) +
  
  theme_publication_enhanced() +
  theme(legend.position = "bottom") +
  
  # Animation
  transition_states(survey_year, transition_length = 2, state_length = 1) +
  ease_aes('cubic-in-out')

# Save animation
anim_save("outputs/figure_v4_0_attitude_space_animation.gif", 
          p_anim, width = 800, height = 600, fps = 10, duration = 20)

# =============================================================================
# 6. ADVANCED VISUALIZATION 4: SMALL MULTIPLES WITH TRENDS
# =============================================================================

cat("\n6. CREATING SMALL MULTIPLES VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create a comprehensive small multiples plot
# Prepare data in long format
small_mult_data <- generation_trends %>%
  select(survey_year, generation_label, 
         liberalism_mean, liberalism_ci_lower, liberalism_ci_upper,
         restrictionism_mean, restrictionism_ci_lower, restrictionism_ci_upper) %>%
  pivot_longer(
    cols = c(liberalism_mean, restrictionism_mean),
    names_to = "index_type",
    values_to = "value"
  ) %>%
  mutate(
    index_label = ifelse(index_type == "liberalism_mean", 
                        "Liberalism", "Restrictionism"),
    ci_lower = ifelse(index_type == "liberalism_mean",
                     liberalism_ci_lower, restrictionism_ci_lower),
    ci_upper = ifelse(index_type == "liberalism_mean",
                     liberalism_ci_upper, restrictionism_ci_upper)
  )

# Add regression lines data
reg_data <- regression_results %>%
  filter(group != "Overall") %>%
  mutate(
    index_label = case_when(
      grepl("liberalism", outcome) ~ "Liberalism",
      grepl("restrictionism", outcome) ~ "Restrictionism",
      TRUE ~ "Other"
    )
  )

p_small <- ggplot(small_mult_data, 
                 aes(x = survey_year, y = value)) +
  
  # Confidence ribbons
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper, fill = generation_label),
              alpha = 0.3) +
  
  # Points and lines
  geom_line(aes(color = generation_label), size = 1.2) +
  geom_point(aes(color = generation_label), size = 2) +
  
  # Facet by index and generation
  facet_grid(index_label ~ generation_label, scales = "free_y") +
  
  # Add trend significance annotations
  geom_text(data = reg_data,
            aes(x = 2012, y = -0.5, 
                label = paste0("p = ", round(p.value, 3), significance)),
            size = 3, fontface = "italic") +
  
  scale_color_manual(values = generation_palette, guide = "none") +
  scale_fill_manual(values = generation_palette, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 5)) +
  
  labs(
    title = "Immigration Attitudes by Generation and Index Type",
    subtitle = "Small multiples show trends with 95% confidence intervals and significance tests",
    x = "Survey Year",
    y = "Standardized Score",
    caption = "Source: NSL 2002-2023. P-values from linear trend tests."
  ) +
  
  theme_publication_enhanced(base_size = 10) +
  theme(strip.text = element_text(size = 9))

ggsave("outputs/figure_v4_0_small_multiples.png", 
       p_small, width = 12, height = 8, dpi = 300)

# =============================================================================
# 7. ADVANCED VISUALIZATION 5: DIVERGENCE PLOT
# =============================================================================

cat("\n7. CREATING DIVERGENCE PLOT\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate divergence from overall Hispanic mean
divergence_data <- generation_trends %>%
  left_join(
    overall_trends %>% 
      select(survey_year, 
             overall_lib = liberalism_mean,
             overall_res = restrictionism_mean),
    by = "survey_year"
  ) %>%
  mutate(
    lib_divergence = liberalism_mean - overall_lib,
    res_divergence = restrictionism_mean - overall_res
  ) %>%
  select(survey_year, generation_label, lib_divergence, res_divergence) %>%
  pivot_longer(
    cols = c(lib_divergence, res_divergence),
    names_to = "measure",
    values_to = "divergence"
  ) %>%
  mutate(
    measure_label = ifelse(measure == "lib_divergence",
                          "Liberalism", "Restrictionism")
  )

p_diverge <- ggplot(divergence_data,
                   aes(x = survey_year, y = divergence, fill = generation_label)) +
  
  geom_hline(yintercept = 0, linetype = "solid", color = "gray30") +
  
  geom_area(position = "identity", alpha = 0.7) +
  
  facet_wrap(~measure_label, ncol = 1) +
  
  scale_fill_manual(values = generation_palette, name = "Generation") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 3)) +
  
  labs(
    title = "Generational Divergence from Overall Hispanic Mean",
    subtitle = "Positive values indicate more liberal/restrictive than average Hispanic respondent",
    x = "Survey Year",
    y = "Divergence from Hispanic Mean",
    caption = "Source: NSL 2002-2023. Zero line represents overall Hispanic population mean."
  ) +
  
  theme_publication_enhanced() +
  theme(legend.position = "bottom")

ggsave("outputs/figure_v4_0_divergence_plot.png", 
       p_diverge, width = 10, height = 8, dpi = 300)

# =============================================================================
# 8. PUBLICATION-READY COMPOSITE FIGURE
# =============================================================================

cat("\n8. CREATING COMPOSITE PUBLICATION FIGURE\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create multiple panels for a comprehensive figure

# Panel A: Main trends
panel_a <- generation_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, 
             color = generation_label, group = generation_label)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  geom_ribbon(aes(ymin = liberalism_ci_lower, ymax = liberalism_ci_upper,
                  fill = generation_label), alpha = 0.2, linetype = 0) +
  scale_color_manual(values = generation_palette, name = "") +
  scale_fill_manual(values = generation_palette, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2023, by = 4)) +
  labs(title = "A. Immigration Policy Liberalism",
       x = "", y = "Standardized Score") +
  theme_publication_enhanced(base_size = 10) +
  theme(legend.position = "none")

# Panel B: Period effects
panel_b <- period_effects %>%
  mutate(period_short = str_wrap(period, width = 10)) %>%
  ggplot(aes(x = period_short, y = liberalism_mean, fill = period)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin = liberalism_mean - liberalism_se, 
                    ymax = liberalism_mean + liberalism_se),
                width = 0.3) +
  scale_fill_manual(values = period_palette, guide = "none") +
  labs(title = "B. Period Effects",
       x = "", y = "Mean Liberalism") +
  theme_publication_enhanced(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

# Panel C: Generation comparison
panel_c <- generation_trends %>%
  filter(survey_year %in% c(2002, 2012, 2022), !is.na(liberalism_mean)) %>%
  ggplot(aes(x = as.factor(survey_year), y = liberalism_mean, 
             fill = generation_label)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_errorbar(aes(ymin = liberalism_mean - liberalism_se,
                    ymax = liberalism_mean + liberalism_se),
                position = position_dodge(width = 0.9),
                width = 0.25) +
  scale_fill_manual(values = generation_palette, name = "Generation") +
  labs(title = "C. Generational Comparison",
       subtitle = "Three time points",
       x = "Survey Year", y = "Mean Liberalism") +
  theme_publication_enhanced(base_size = 10) +
  theme(legend.position = "bottom")

# Combine panels
composite <- (panel_a | panel_b) / panel_c +
  plot_annotation(
    title = "Hispanic Immigration Attitudes: Trends, Periods, and Generations",
    subtitle = "Analysis of National Survey of Latinos 2002-2023",
    caption = "Source: Pew Research Center NSL. Error bars show ±1 SE.",
    theme = theme(
      plot.title = element_text(size = 16, face = "bold"),
      plot.subtitle = element_text(size = 12, color = "gray40")
    )
  )

ggsave("outputs/figure_v4_0_composite_publication.png",
       composite, width = 12, height = 10, dpi = 300)

# =============================================================================
# 9. SUMMARY OUTPUT
# =============================================================================

cat("\n9. VISUALIZATION SUMMARY\n")
cat(paste(rep("-", 60), collapse = ""), "\n")
cat("Advanced visualizations created:\n")
cat("1. Ridge distributions plot\n")
cat("2. Alluvial flow diagram\n")
cat("3. Animated attitude space (GIF)\n")
cat("4. Small multiples with trends\n")
cat("5. Divergence from mean plot\n")
cat("6. Composite publication figure\n")
cat("\nAll visualizations saved to outputs/ directory\n")

# =============================================================================
# END OF ADVANCED VISUALIZATIONS
# =============================================================================