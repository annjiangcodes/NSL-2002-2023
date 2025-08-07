# =============================================================================
# CORRECTED PERIOD EFFECTS VISUALIZATION v4.4
# =============================================================================
# Purpose: Fix the period effects visualization color coding
# Issue: Colors should reflect direction of change, not just attitude type
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(scales)

# Define publication theme
theme_publication <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
  theme(
    plot.title = element_text(size = rel(1.4), face = "bold", 
                             color = "black", margin = margin(b = 10)),
    plot.subtitle = element_text(size = rel(1.1), color = "#4A4A4A", 
                                margin = margin(b = 10)),
    plot.caption = element_text(size = rel(0.8), color = "#6A6A6A", 
                               hjust = 0, margin = margin(t = 10)),
    axis.title = element_text(size = rel(1), face = "bold", color = "black"),
    axis.text = element_text(size = rel(0.9), color = "black"),
    axis.line = element_line(color = "#333333", size = 0.5),
    axis.ticks = element_line(color = "#333333", size = 0.5),
    legend.title = element_text(size = rel(1), face = "bold", color = "black"),
    legend.text = element_text(size = rel(0.9), color = "black"),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key = element_rect(fill = "white", color = NA),
    legend.position = "bottom",
    panel.background = element_rect(fill = "white", color = NA),
    panel.grid.major = element_line(color = "#E0E0E0", size = 0.5),
    panel.grid.minor = element_line(color = "#F0F0F0", size = 0.25),
    panel.border = element_rect(fill = NA, color = "#CCCCCC", size = 0.5),
    strip.background = element_rect(fill = "#F5F5F5", color = "#CCCCCC"),
    strip.text = element_text(size = rel(1), face = "bold", color = "black"),
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin = margin(20, 20, 20, 20)
  )
}

cat("=============================================================\n")
cat("CORRECTED PERIOD EFFECTS VISUALIZATION v4.4\n")
cat("Fixing color coding to reflect direction of change\n")
cat("=============================================================\n")

# Load data
period_effects <- read_csv("outputs/period_effects_v4_0.csv", show_col_types = FALSE)

# Prepare corrected period data
period_data <- period_effects %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  pivot_longer(
    cols = c(liberalism_mean, restrictionism_mean),
    names_to = "index_type",
    values_to = "value"
  ) %>%
  mutate(
    index_label = ifelse(index_type == "liberalism_mean",
                        "Liberalism", "Restrictionism"),
    se = ifelse(index_type == "liberalism_mean",
               liberalism_se, restrictionism_se),
    period_short = case_when(
      period == "Early Bush Era" ~ "Early Bush\n(2002-04)",
      period == "Immigration Debates" ~ "Immigration\nDebates\n(2006-07)",
      period == "Economic Crisis" ~ "Economic\nCrisis\n(2008-10)",
      period == "Obama Era" ~ "Obama Era\n(2011-15)",
      period == "Trump Era" ~ "Trump Era\n(2016-18)",
      period == "COVID & Biden Era" ~ "COVID &\nBiden Era\n(2021-23)"
    ),
    # NEW: Determine color based on direction AND magnitude
    value_direction = case_when(
      value > 0.005 ~ "Increase",
      value < -0.005 ~ "Decrease", 
      TRUE ~ "No Change"
    ),
    # NEW: Create combined label for color mapping
    color_category = paste(index_label, value_direction, sep = " - ")
  )

# Print diagnostic information
cat("\nPeriod Effects Data Summary:\n")
print(period_data %>% 
  select(period, index_label, value, value_direction, color_category) %>%
  arrange(period, index_label))

# Create corrected visualization
p_period_corrected <- period_data %>%
  ggplot(aes(x = period_short, y = value, fill = color_category)) +
  
  # Bars with dodging
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), 
           width = 0.7, color = "white", size = 0.5) +
  
  # Error bars
  geom_errorbar(aes(ymin = value - se, ymax = value + se),
                position = position_dodge(width = 0.8),
                width = 0.3, size = 0.8, color = "#333333") +
  
  # Zero line
  geom_hline(yintercept = 0, linetype = "solid", color = "#333333", size = 0.5) +
  
  # NEW: Corrected color scale based on direction
  scale_fill_manual(
    values = c(
      "Liberalism - Increase" = "#2E7D32",      # Green for liberalism increase
      "Liberalism - Decrease" = "#81C784",      # Light green for liberalism decrease
      "Liberalism - No Change" = "#E8F5E8",     # Very light green for no change
      "Restrictionism - Increase" = "#C62828",  # Red for restrictionism increase  
      "Restrictionism - Decrease" = "#EF5350",  # Light red for restrictionism decrease
      "Restrictionism - No Change" = "#FFEBEE"  # Very light red for no change
    ),
    name = "Attitude Direction",
    labels = function(x) {
      case_when(
        x == "Liberalism - Increase" ~ "Liberalism ↑",
        x == "Liberalism - Decrease" ~ "Liberalism ↓", 
        x == "Liberalism - No Change" ~ "Liberalism ≈",
        x == "Restrictionism - Increase" ~ "Restrictionism ↑",
        x == "Restrictionism - Decrease" ~ "Restrictionism ↓",
        x == "Restrictionism - No Change" ~ "Restrictionism ≈",
        TRUE ~ x
      )
    }
  ) +
  
  # Labels
  labs(
    title = "Immigration Attitudes by Historical Period (CORRECTED)",
    subtitle = "Colors now correctly reflect direction of change: Green↑=Pro-Immigration increase, Red↑=Anti-Immigration increase",
    x = "Historical Period",
    y = "Mean Standardized Score",
    caption = "Source: NSL data pooled by period. Error bars show ±1 standard error.\nCorrected visualization: Colors indicate direction and magnitude of change."
  ) +
  
  theme_publication() +
  theme(
    axis.text.x = element_text(size = 10),
    legend.text = element_text(size = 9)
  )

# Save corrected visualization
ggsave("outputs/figure_v4_4_period_effects_CORRECTED.png", 
       p_period_corrected, width = 12, height = 8, dpi = 300, bg = "white")

cat("Created CORRECTED period effects visualization\n")

# =============================================================================
# ALTERNATIVE VERSION: Show change from baseline
# =============================================================================

cat("\nCreating alternative version showing change from baseline...\n")

# Calculate baseline (Early Bush Era) and changes
baseline_data <- period_effects %>%
  filter(period == "Early Bush Era") %>%
  select(liberalism_baseline = liberalism_mean, 
         restrictionism_baseline = restrictionism_mean)

period_change_data <- period_effects %>%
  filter(!is.na(liberalism_mean), !is.na(restrictionism_mean)) %>%
  cross_join(baseline_data) %>%
  mutate(
    liberalism_change = liberalism_mean - liberalism_baseline,
    restrictionism_change = restrictionism_mean - restrictionism_baseline
  ) %>%
  pivot_longer(
    cols = c(liberalism_change, restrictionism_change),
    names_to = "index_type",
    values_to = "change_value"
  ) %>%
  mutate(
    index_label = ifelse(index_type == "liberalism_change",
                        "Liberalism", "Restrictionism"),
    period_short = case_when(
      period == "Early Bush Era" ~ "Early Bush\n(2002-04)",
      period == "Immigration Debates" ~ "Immigration\nDebates\n(2006-07)",
      period == "Economic Crisis" ~ "Economic\nCrisis\n(2008-10)",
      period == "Obama Era" ~ "Obama Era\n(2011-15)",
      period == "Trump Era" ~ "Trump Era\n(2016-18)",
      period == "COVID & Biden Era" ~ "COVID &\nBiden Era\n(2021-23)"
    ),
    change_direction = case_when(
      change_value > 0.002 ~ "Increased",
      change_value < -0.002 ~ "Decreased",
      TRUE ~ "Unchanged"
    )
  )

p_period_change <- period_change_data %>%
  ggplot(aes(x = period_short, y = change_value, fill = interaction(index_label, change_direction))) +
  
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), 
           width = 0.7, color = "white", size = 0.5) +
  
  geom_hline(yintercept = 0, linetype = "solid", color = "#333333", size = 0.8) +
  
  scale_fill_manual(
    values = c(
      "Liberalism.Increased" = "#1B5E20",     # Dark green
      "Liberalism.Decreased" = "#C8E6C9",     # Light green  
      "Liberalism.Unchanged" = "#E8F5E8",     # Very light green
      "Restrictionism.Increased" = "#B71C1C", # Dark red
      "Restrictionism.Decreased" = "#FFCDD2", # Light red
      "Restrictionism.Unchanged" = "#FFEBEE"  # Very light red
    ),
    name = "Change from Baseline",
    labels = c(
      "Liberalism.Increased" = "Liberalism ↑",
      "Liberalism.Decreased" = "Liberalism ↓",
      "Liberalism.Unchanged" = "Liberalism ≈",
      "Restrictionism.Increased" = "Restrictionism ↑", 
      "Restrictionism.Decreased" = "Restrictionism ↓",
      "Restrictionism.Unchanged" = "Restrictionism ≈"
    )
  ) +
  
  labs(
    title = "Change in Immigration Attitudes Relative to Early Bush Era",
    subtitle = "Shows how attitudes shifted from the 2002-2004 baseline period",
    x = "Historical Period",
    y = "Change from Baseline",
    caption = "Source: NSL data. Baseline = Early Bush Era (2002-2004). Positive = more liberal/restrictive than baseline."
  ) +
  
  theme_publication() +
  theme(axis.text.x = element_text(size = 10))

ggsave("outputs/figure_v4_4_period_effects_CHANGE_FROM_BASELINE.png", 
       p_period_change, width = 12, height = 8, dpi = 300, bg = "white")

cat("Created change from baseline visualization\n")

cat("\n=============================================================\n")
cat("CORRECTION COMPLETE\n")
cat("Files created:\n")
cat("- figure_v4_4_period_effects_CORRECTED.png\n")
cat("- figure_v4_4_period_effects_CHANGE_FROM_BASELINE.png\n")
cat("=============================================================\n")
