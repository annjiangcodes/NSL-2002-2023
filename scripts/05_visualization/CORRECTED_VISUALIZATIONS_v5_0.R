# =============================================================================
# CORRECTED VISUALIZATIONS v5.0 - ACCURATE GENERATIONAL PATTERNS
# =============================================================================
# Purpose: Create publication-quality visualizations with corrected interpretations
# Version: 5.0 - VERIFIED AND CORRECTED
# Key Changes: 
#   - 1st Generation: Liberal + VOLATILE (RED)
#   - 2nd Generation: Moderate + STABLE (BLUE)  
#   - 3rd+ Generation: Conservative + Moderate volatility (GREEN)
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(scales)
library(patchwork)
library(viridis)
library(stringr)

cat("=============================================================\n")
cat("CORRECTED VISUALIZATIONS v5.0\n")
cat("ACCURATE GENERATIONAL PATTERNS\n")
cat("=============================================================\n")

# =============================================================================
# 1. LOAD CORRECTED DATA
# =============================================================================

cat("\n1. LOADING CORRECTED v5.0 DATA\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load the corrected results
generation_trends <- read_csv("outputs/generation_trends_CORRECTED_v5_0.csv", show_col_types = FALSE)
variance_analysis <- read_csv("outputs/variance_analysis_CORRECTED_v5_0.csv", show_col_types = FALSE)
corrected_patterns <- read_csv("outputs/corrected_patterns_summary_v5_0.csv", show_col_types = FALSE)

cat("Data loaded successfully:\n")
cat("- Generation trends:", nrow(generation_trends), "rows\n")
cat("- Variance analysis:", nrow(variance_analysis), "generations\n")

# =============================================================================
# 2. CORRECTED COLOR PALETTE AND THEME
# =============================================================================

# Corrected color palette - consistent with accurate interpretations
generation_colors_v5 <- c(
  "1st Generation" = "#E41A1C",    # RED - Liberal but VOLATILE
  "2nd Generation" = "#377EB8",    # BLUE - Moderate and STABLE  
  "3rd+ Generation" = "#4DAF4A"    # GREEN - Conservative with moderate volatility
)

# Publication theme
theme_corrected_v5 <- function() {
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 12, color = "gray40"),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10),
    legend.title = element_text(size = 11, face = "bold"),
    legend.text = element_text(size = 10),
    strip.text = element_text(size = 11, face = "bold"),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 9, color = "gray50", hjust = 0)
  )
}

# =============================================================================
# 3. VISUALIZATION 1: CORRECTED VOLATILITY COMPARISON
# =============================================================================

cat("\n3. CREATING CORRECTED VOLATILITY VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare volatility data for visualization
volatility_viz_data <- variance_analysis %>%
  select(generation_label, lib_variance, res_variance, lib_sd, res_sd) %>%
  pivot_longer(
    cols = c(lib_variance, res_variance),
    names_to = "measure_type",
    values_to = "variance_value"
  ) %>%
  mutate(
    measure_label = case_when(
      measure_type == "lib_variance" ~ "Liberalism",
      measure_type == "res_variance" ~ "Restrictionism"
    ),
    generation_ordered = factor(generation_label, 
                               levels = c("1st Generation", "2nd Generation", "3rd+ Generation"))
  )

# Create corrected volatility plot
p_volatility_v5 <- ggplot(volatility_viz_data, 
                          aes(x = generation_ordered, y = variance_value, fill = generation_ordered)) +
  
  geom_col(alpha = 0.8, width = 0.7) +
  
  # Add text annotations showing rankings
  geom_text(aes(label = sprintf("%.3f", variance_value)), 
            vjust = -0.5, size = 3.5, fontface = "bold") +
  
  facet_wrap(~measure_label, scales = "free_y") +
  
  scale_fill_manual(values = generation_colors_v5, guide = "none") +
  
  labs(
    title = "CORRECTED: Temporal Volatility by Generation",
    subtitle = "1st Gen = MOST VOLATILE | 2nd Gen = MOST STABLE | 3rd+ Gen = MODERATE",
    x = "Immigrant Generation",
    y = "Variance in Attitudes Over Time",
    caption = "Higher values = more volatile attitudes across survey years\nCorrected interpretation: 2nd generation is the MOST STABLE, not volatile"
  ) +
  
  theme_corrected_v5() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/figure_v5_0_corrected_volatility.png", p_volatility_v5, 
       width = 10, height = 6, dpi = 300)

cat("Corrected volatility visualization saved.\n")

# =============================================================================
# 4. VISUALIZATION 2: CORRECTED GENERATIONAL PATTERNS
# =============================================================================

cat("\n4. CREATING CORRECTED GENERATIONAL PATTERNS VISUALIZATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create trend visualization with corrected interpretation
p_trends_v5 <- generation_trends %>%
  filter(!is.na(liberalism_mean)) %>%
  ggplot(aes(x = survey_year, y = liberalism_mean, color = generation_label)) +
  
  # Add reference line at zero
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.7) +
  
  # Add confidence intervals
  geom_ribbon(aes(ymin = liberalism_mean - liberalism_se, 
                  ymax = liberalism_mean + liberalism_se,
                  fill = generation_label),
              alpha = 0.2, color = NA) +
  
  # Add trend lines and points
  geom_line(size = 1.2, alpha = 0.9) +
  geom_point(size = 3, alpha = 0.9) +
  
  # Add corrected annotations
  annotate("text", x = 2020, y = 0.4, 
           label = "1st Gen (RED):\nLiberal + VOLATILE", 
           hjust = 0, size = 3.5, color = "#E41A1C", fontface = "bold") +
  
  annotate("text", x = 2020, y = 0, 
           label = "2nd Gen (BLUE):\nModerate + STABLE", 
           hjust = 0, size = 3.5, color = "#377EB8", fontface = "bold") +
  
  annotate("text", x = 2020, y = -0.3, 
           label = "3rd+ Gen (GREEN):\nConservative + Moderate volatility", 
           hjust = 0, size = 3.5, color = "#4DAF4A", fontface = "bold") +
  
  scale_color_manual(values = generation_colors_v5, name = "Generation") +
  scale_fill_manual(values = generation_colors_v5, guide = "none") +
  scale_x_continuous(breaks = seq(2002, 2022, by = 4)) +
  
  labs(
    title = "CORRECTED: Immigration Attitude Patterns by Generation",
    subtitle = "Verified: 1st Gen = Volatile | 2nd Gen = Stable | 3rd+ Gen = Moderate volatility",
    x = "Survey Year",
    y = "Immigration Policy Liberalism (Standardized)",
    caption = "Corrected interpretation based on variance analysis\nNote: Position ≠ Volatility"
  ) +
  
  theme_corrected_v5()

ggsave("outputs/figure_v5_0_corrected_patterns.png", p_trends_v5, 
       width = 12, height = 8, dpi = 300)

cat("Corrected patterns visualization saved.\n")

# =============================================================================
# 5. VISUALIZATION 3: POSITION VS VOLATILITY CLARIFICATION
# =============================================================================

cat("\n5. CREATING POSITION VS VOLATILITY CLARIFICATION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create scatter plot showing position vs volatility
position_volatility_data <- variance_analysis %>%
  left_join(
    generation_trends %>%
      group_by(generation_label) %>%
      summarise(mean_liberalism = mean(liberalism_mean, na.rm = TRUE),
                mean_restrictionism = mean(restrictionism_mean, na.rm = TRUE),
                .groups = "drop"),
    by = "generation_label"
  )

p_position_volatility <- ggplot(position_volatility_data, 
                               aes(x = mean_liberalism, y = lib_variance)) +
  
  # Add quadrant lines
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", alpha = 0.7) +
  geom_hline(yintercept = median(position_volatility_data$lib_variance), 
             linetype = "dashed", color = "gray50", alpha = 0.7) +
  
  # Add points
  geom_point(aes(color = generation_label, size = lib_years), alpha = 0.8) +
  
  # Add labels
  geom_text(aes(label = str_remove(generation_label, " Generation"), 
                color = generation_label),
            vjust = -1.5, size = 4, fontface = "bold") +
  
  # Add quadrant labels
  annotate("text", x = -0.15, y = 0.035, label = "Liberal +\nVolatile", 
           hjust = 0.5, vjust = 0.5, size = 3.5, color = "gray40", fontface = "italic") +
  annotate("text", x = 0.15, y = 0.035, label = "Conservative +\nVolatile", 
           hjust = 0.5, vjust = 0.5, size = 3.5, color = "gray40", fontface = "italic") +
  annotate("text", x = -0.15, y = 0.005, label = "Liberal +\nStable", 
           hjust = 0.5, vjust = 0.5, size = 3.5, color = "gray40", fontface = "italic") +
  annotate("text", x = 0.15, y = 0.005, label = "Conservative +\nStable", 
           hjust = 0.5, vjust = 0.5, size = 3.5, color = "gray40", fontface = "italic") +
  
  scale_color_manual(values = generation_colors_v5, guide = "none") +
  scale_size_continuous(range = c(8, 12), guide = "none") +
  
  labs(
    title = "Position vs. Volatility: Why These Are Different Dimensions",
    subtitle = "X-axis = Political Position | Y-axis = Temporal Volatility",
    x = "Mean Liberalism Position (Liberal ← → Conservative)",
    y = "Temporal Volatility (Variance Over Time)",
    caption = "Key insight: 2nd generation has moderate position BUT low volatility\nPosition and volatility are independent dimensions"
  ) +
  
  theme_corrected_v5()

ggsave("outputs/figure_v5_0_position_vs_volatility.png", p_position_volatility, 
       width = 10, height = 8, dpi = 300)

cat("Position vs volatility clarification saved.\n")

# =============================================================================
# 6. VISUALIZATION 4: CORRECTED SUMMARY DASHBOARD
# =============================================================================

cat("\n6. CREATING CORRECTED SUMMARY DASHBOARD\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create summary statistics table for visualization
summary_stats <- variance_analysis %>%
  select(generation_label, lib_variance, lib_sd) %>%
  left_join(
    generation_trends %>%
      group_by(generation_label) %>%
      summarise(mean_position = mean(liberalism_mean, na.rm = TRUE),
                years_data = n(),
                .groups = "drop"),
    by = "generation_label"
  ) %>%
  mutate(
    volatility_rank = rank(desc(lib_variance)),
    position_rank = rank(mean_position),
    interpretation = case_when(
      generation_label == "1st Generation" ~ "Liberal + VOLATILE",
      generation_label == "2nd Generation" ~ "Moderate + STABLE", 
      generation_label == "3rd+ Generation" ~ "Conservative + Moderate"
    )
  )

# Create text-based summary
p_summary_text <- ggplot(summary_stats, aes(x = 1, y = as.numeric(as.factor(generation_label)))) +
  
  geom_text(aes(label = paste0(generation_label, "\n", interpretation, "\n",
                              "Position: ", sprintf("%.3f", mean_position), "\n",
                              "Volatility: ", sprintf("%.3f", lib_variance), "\n",
                              "Vol. Rank: #", volatility_rank),
                color = generation_label),
            size = 4, fontface = "bold", hjust = 0.5) +
  
  scale_color_manual(values = generation_colors_v5, guide = "none") +
  scale_y_reverse() +
  
  labs(
    title = "CORRECTED v5.0: Generational Immigration Attitude Patterns",
    subtitle = "Final verified interpretation with corrected volatility rankings",
    caption = "Correction: 2nd generation is STABLE (lowest volatility), not volatile"
  ) +
  
  theme_void() +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "gray40"),
    plot.caption = element_text(size = 10, hjust = 0.5, color = "red", face = "bold")
  )

ggsave("outputs/figure_v5_0_corrected_summary.png", p_summary_text, 
       width = 10, height = 6, dpi = 300)

cat("Corrected summary dashboard saved.\n")

# =============================================================================
# 7. FINAL SUMMARY
# =============================================================================

cat("\n7. v5.0 VISUALIZATION SUMMARY\n")
cat(paste(rep("=", 60), collapse = ""), "\n")
cat("\nCORRECTED VISUALIZATIONS CREATED:\n")
cat("=================================\n")
cat("1. figure_v5_0_corrected_volatility.png: Shows actual volatility rankings\n")
cat("2. figure_v5_0_corrected_patterns.png: Trends with accurate interpretations\n")
cat("3. figure_v5_0_position_vs_volatility.png: Clarifies position ≠ volatility\n")
cat("4. figure_v5_0_corrected_summary.png: Final verified patterns\n")

cat("\nKEY CORRECTIONS VISUALIZED:\n")
cat("===========================\n")
cat("✓ 1st Generation: Liberal position + HIGH volatility (REACTIVE)\n")
cat("✓ 2nd Generation: Moderate position + LOW volatility (STABLE)\n") 
cat("✓ 3rd+ Generation: Conservative position + MODERATE volatility\n")

cat("\nINTERPRETATION ERROR CORRECTED:\n")
cat("===============================\n")
cat("❌ OLD (v4.x): 2nd generation = volatile\n")
cat("✅ NEW (v5.0): 2nd generation = most STABLE\n")

cat("\nv5.0 CORRECTED VISUALIZATIONS COMPLETE\n")
cat("All outputs saved to outputs/ with v5_0 prefix\n")
