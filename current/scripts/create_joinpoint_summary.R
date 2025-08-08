## CREATE JOINPOINT SUMMARY PLOT (NOFE) ##
#
# Description:
# This script reads the v2.9w joinpoint results and creates a compact 
# graphical table summarizing any single-break improvements (ΔBIC).
#
# Input:
# - outputs/v2_9w_joinpoint_results.csv (Expected)
#
# Output:
# - current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/6_joinpoint_summary_NOFE.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(gridExtra)
  library(grid)
})

message("=== CREATE JOINPOINT SUMMARY PLOT (NOFE) START ===")

# ----------------------------------------------------------------------------
# Load data
# ----------------------------------------------------------------------------
input_path <- "outputs/v2_9w_joinpoint_results.csv"
output_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"

if (!file.exists(input_path)) {
  warning("Input file not found: ", input_path, ". Creating an empty placeholder plot.")
  
  # Create a placeholder message
  error_message <- "Joinpoint results not found.\nPlease run the v2.9w joinpoint analysis."
  
  # Create an empty plot with the message
  p_placeholder <- ggplot() + 
    annotate("text", x = 4, y = 25, size=8, label = error_message) + 
    theme_void() +
    labs(title = "Joinpoint Summary (NOFE)") +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"))
  
  # Save the placeholder
  if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
  output_path <- file.path(output_dir, "6_joinpoint_summary_NOFE.png")
  ggsave(
    output_path,
    plot = p_placeholder,
    width = 10,
    height = 5,
    dpi = 300,
    bg = "white"
  )
  
  stop("Execution halted: Joinpoint results file is missing.")
}

joinpoint_df <- read_csv(input_path, show_col_types = FALSE)

# ----------------------------------------------------------------------------
# Process data and create table
# ----------------------------------------------------------------------------
summary_table <- joinpoint_df %>%
  select(variable, best_break_year, bic_single_line, bic_two_lines, delta_bic) %>%
  rename(
    Measure = variable,
    `Best Break Year` = best_break_year,
    `BIC (Linear)` = bic_single_line,
    `BIC (1-break)` = bic_two_lines,
    `ΔBIC` = delta_bic
  ) %>%
  arrange(Measure)

# ----------------------------------------------------------------------------
# Create plot
# ----------------------------------------------------------------------------
p <- tableGrob(summary_table, rows = NULL)
title <- textGrob("Joinpoint Model Comparison (Single-Break vs. Linear)", gp = gpar(fontsize = 14, fontface = "bold"))
p_with_title <- grid.arrange(title, p, ncol = 1, as.table = TRUE, heights = unit.c(unit(2, "line"), grobHeight(p)))

# ----------------------------------------------------------------------------
# Save plot
# ----------------------------------------------------------------------------
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
output_path <- file.path(output_dir, "6_joinpoint_summary_NOFE.png")
ggsave(
  output_path,
  plot = p_with_title,
  width = 10,
  height = 6,
  dpi = 300,
  bg = "white"
)
message("Saved plot: ", output_path)

message("=== CREATE JOINPOINT SUMMARY PLOT (NOFE) COMPLETE ===")

