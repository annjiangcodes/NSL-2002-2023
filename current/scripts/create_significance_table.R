## CREATE SIGNIFICANCE TABLE (NOFE) ##
#
# Reads the trend data from the NOFE analysis, combines them, 
# and creates a compact significance table in both CSV and PNG format.
#
# Inputs:
# - current/data/CURRENT_2025_08_08_DATA_weighted_trends_NOFE.csv
# - current/data/CURRENT_2025_08_08_DATA_generation_trends_NOFE.csv
#
# Outputs:
# - current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/3_significance_table_NOFE.csv
# - current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE/3_significance_table_NOFE.png

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(gridExtra)
  library(grid)
})

message("=== CREATE SIGNIFICANCE TABLE (NOFE) START ===")

# ----------------------------------------------------------------------------
# Load data
# ----------------------------------------------------------------------------
overall_trends_file <- "current/data/CURRENT_2025_08_08_DATA_weighted_trends_NOFE.csv"
generation_trends_file <- "current/data/CURRENT_2025_08_08_DATA_generation_trends_NOFE.csv"
output_dir <- "current/outputs/CURRENT_2025_08_08_FIGURES_trends_NOFE"

if (!file.exists(overall_trends_file)) stop("Input file not found: ", overall_trends_file)
if (!file.exists(generation_trends_file)) stop("Input file not found: ", generation_trends_file)
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

overall_trends_df <- read_csv(overall_trends_file, show_col_types = FALSE)
generation_trends_df <- read_csv(generation_trends_file, show_col_types = FALSE)

# ----------------------------------------------------------------------------
# Combine and format data
# ----------------------------------------------------------------------------
combined_trends <- bind_rows(overall_trends_df, generation_trends_df) %>%
  select(variable, scope, slope, p_value, significance) %>%
  mutate(
    trend_summary = sprintf("%.3f %s", slope, significance)
  ) %>%
  select(variable, scope, trend_summary) %>%
  pivot_wider(names_from = scope, values_from = trend_summary)

# Reorder columns for clarity
ordered_cols <- c(
    "variable", "Overall Population", "1st Generation", 
    "2nd Generation", "3rd+ Generation"
)
final_table <- combined_trends %>%
    select(any_of(ordered_cols))

# ----------------------------------------------------------------------------
# Save CSV
# ----------------------------------------------------------------------------
csv_output_path <- file.path(output_dir, "3_significance_table_NOFE.csv")
write_csv(final_table, csv_output_path)
message("Saved CSV: ", csv_output_path)

# ----------------------------------------------------------------------------
# Save PNG
# ----------------------------------------------------------------------------
png_output_path <- file.path(output_dir, "3_significance_table_NOFE.png")

# Create a plot from the table
p <- tableGrob(final_table, rows = NULL)

# Add title
title <- textGrob("Significance of Attitude Trends (NOFE)", gp = gpar(fontsize = 15, fontface = "bold"))
p_with_title <- grid.arrange(title, p, ncol = 1, as.table = TRUE, heights = unit.c(unit(2, "line"), grobHeight(p)))


ggsave(
    png_output_path,
    plot = p_with_title,
    width = 10,
    height = 5,
    dpi = 300,
    bg = "white"
)
message("Saved PNG: ", png_output_path)


message("=== CREATE SIGNIFICANCE TABLE (NOFE) COMPLETE ===")


