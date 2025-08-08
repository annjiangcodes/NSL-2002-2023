# MIGRATION TO DATE-BASED NAMING CONVENTION
# Purpose: Systematically rename files to new date-based convention
# Run date: 2025-01-15

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

message("=== MIGRATION TO DATE-BASED NAMING CONVENTION ===")
today <- "2025_01_15"

# =============================================================================
# 1. IDENTIFY CURRENT BEST VERSIONS
# =============================================================================

current_best <- list(
  # Data files (most authoritative versions)
  data = list(
    master_dataset = "data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv",
    trend_results = "outputs/v2_9w_plus_trend_results.csv", 
    yearly_means = "outputs/v2_9w_plus_yearly_with_ci.csv",
    volatility_analysis = "outputs/v2_9w_volatility_comparison.csv",
    coverage_summary = "outputs/v2_9c_coverage_summary.csv"
  ),
  
  # Analysis scripts (most current)
  analysis = list(
    master_analysis = "scripts/03_analysis/ENHANCED_WEIGHTED_ANALYSIS_v2_9w_PLUS.R",
    coverage_analysis = "scripts/03_analysis/CORRECTED_MAXIMUM_COVERAGE_v2_9c.R",
    trend_analysis = "scripts/03_analysis/ANALYSIS_v2_9w_WEIGHTED.R"
  ),
  
  # Visualization scripts
  visualization = list(
    comprehensive_suite = "scripts/05_visualization/COMPREHENSIVE_VISUALIZATION_SUITE_v5_0.R",
    innovative_viz = "scripts/05_visualization/INNOVATIVE_VISUALIZATIONS_v5_0.R"
  ),
  
  # Reports (most current documentation)
  reports = list(
    bug_fix_summary = "docs/reports/BUG_FIX_AND_MAXIMUM_COVERAGE_SUMMARY_v2_9c.md",
    analysis_summary = "docs/reports/CORRECTED_ANALYSIS_SUMMARY_v5_0.md",
    methodology = "docs/methodology/INTERPRETATION_ERROR_CORRECTION_ANALYSIS_v5_0.md"
  )
)

# =============================================================================
# 2. DEFINE NEW NAMING MAPPINGS
# =============================================================================

new_names <- list(
  data = list(
    master_dataset = paste0("DATA_", today, "_comprehensive_immigration_attitudes.csv"),
    trend_results = paste0("DATA_", today, "_generational_trends_enhanced.csv"),
    yearly_means = paste0("DATA_", today, "_yearly_means_with_ci.csv"), 
    volatility_analysis = paste0("DATA_", today, "_volatility_comparison.csv"),
    coverage_summary = paste0("DATA_", today, "_coverage_summary.csv")
  ),
  
  analysis = list(
    master_analysis = paste0("ANALYSIS_", today, "_enhanced_weighted_master.R"),
    coverage_analysis = paste0("ANALYSIS_", today, "_maximum_coverage.R"),
    trend_analysis = paste0("ANALYSIS_", today, "_weighted_trends.R")
  ),
  
  visualization = list(
    comprehensive_suite = paste0("VIZ_", today, "_comprehensive_suite.R"),
    innovative_viz = paste0("VIZ_", today, "_innovative_approaches.R")
  ),
  
  reports = list(
    bug_fix_summary = paste0("REPORT_", today, "_bug_fixes_and_coverage.md"),
    analysis_summary = paste0("REPORT_", today, "_analysis_summary.md"),
    methodology = paste0("REPORT_", today, "_methodology_notes.md")
  )
)

# =============================================================================
# 3. CREATE DIRECTORY STRUCTURE
# =============================================================================

dirs_to_create <- c(
  "data/latest", "data/archive",
  "scripts/latest", "scripts/archive", 
  "docs/latest", "docs/archive",
  "outputs/latest", paste0("outputs/", today)
)

for (dir in dirs_to_create) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    message("Created directory: ", dir)
  }
}

# =============================================================================
# 4. MIGRATION FUNCTION
# =============================================================================

migrate_file <- function(old_path, new_name, type) {
  if (!file.exists(old_path)) {
    message("SKIP: ", old_path, " (not found)")
    return(FALSE)
  }
  
  # Determine destination based on type
  if (type == "data") {
    archive_path <- file.path("data/archive", new_name)
    latest_path <- file.path("data/latest", str_remove(new_name, paste0("DATA_", today, "_")))
  } else if (type == "analysis" || type == "visualization") {
    archive_path <- file.path("scripts/archive", new_name) 
    latest_path <- file.path("scripts/latest", str_remove(new_name, paste0("^(ANALYSIS|VIZ)_", today, "_")))
  } else if (type == "reports") {
    archive_path <- file.path("docs/archive", new_name)
    latest_path <- file.path("docs/latest", str_remove(new_name, paste0("REPORT_", today, "_")))
  } else {
    message("ERROR: Unknown type ", type)
    return(FALSE)
  }
  
  # Copy to archive with new name
  if (file.copy(old_path, archive_path)) {
    message("COPIED: ", old_path, " -> ", archive_path)
    
    # Create symlink in latest/
    if (file.exists(latest_path)) file.remove(latest_path)
    
    # Create relative path for symlink
    rel_path <- file.path("..", "archive", new_name)
    
    # Try to create symlink (may fail on some systems, fall back to copy)
    link_success <- tryCatch({
      file.symlink(rel_path, latest_path)
      TRUE
    }, error = function(e) {
      # Fallback: copy instead of symlink
      file.copy(archive_path, latest_path)
      TRUE
    })
    
    if (link_success) {
      message("LINKED: ", latest_path, " -> ", rel_path)
    }
    
    return(TRUE)
  } else {
    message("ERROR: Failed to copy ", old_path)
    return(FALSE)
  }
}

# =============================================================================
# 5. PERFORM MIGRATION
# =============================================================================

migration_log <- list()

for (type in names(current_best)) {
  message("\n--- MIGRATING ", toupper(type), " FILES ---")
  
  for (item in names(current_best[[type]])) {
    old_path <- current_best[[type]][[item]]
    new_name <- new_names[[type]][[item]]
    
    success <- migrate_file(old_path, new_name, type)
    migration_log[[paste(type, item, sep = "_")]] <- list(
      old_path = old_path,
      new_name = new_name, 
      success = success
    )
  }
}

# =============================================================================
# 6. CREATE METADATA FILES
# =============================================================================

# LATEST_VERSION.txt
writeLines(
  c(paste("LATEST VERSION:", today),
    paste("MIGRATION DATE:", Sys.Date()),
    "",
    "This project now uses date-based naming convention.",
    "See VERSION_HISTORY.md for details.",
    "",
    "Latest files are symlinked in:",
    "- data/latest/",
    "- scripts/latest/", 
    "- docs/latest/",
    "",
    "All dated versions archived in respective archive/ folders."),
  "LATEST_VERSION.txt"
)

# VERSION_HISTORY.md
version_history <- paste0(
  "# VERSION HISTORY\n\n",
  "## ", today, " - Migration to Date-Based Naming\n",
  "- Implemented new naming convention: TYPE_YYYY_MM_DD_description\n",
  "- Migrated all current best versions to new system\n", 
  "- Created latest/ symlinks for easy access\n",
  "- Archived all files with proper dates\n\n",
  "### Files Migrated:\n"
)

for (log_entry in names(migration_log)) {
  entry <- migration_log[[log_entry]]
  status <- if (entry$success) "✅" else "❌"
  version_history <- paste0(version_history, 
    "- ", status, " ", entry$old_path, " → ", entry$new_name, "\n")
}

version_history <- paste0(version_history, 
  "\n## Previous Versions (Pre-", today, ")\n",
  "- v2.7: COMPREHENSIVE_IMMIGRATION_DATASET\n",
  "- v2.8: First weighted analysis\n", 
  "- v2.9: Unweighted re-evaluation\n",
  "- v2.9w: Weighted analysis with interaction tests\n",
  "- v2.9c: Bug fixes and maximum coverage\n",
  "- v2.9w+: Enhanced with mixed-effects and confidence intervals\n",
  "- v5.0: Corrected volatility interpretation (later superseded)\n"
)

writeLines(strsplit(version_history, "\n")[[1]], "VERSION_HISTORY.md")

# Update README
readme_update <- paste0(
  "# NSL Immigration Attitudes Project - Updated Naming Convention\n\n",
  "**Latest Version: ", today, "**\n\n",
  "## Quick Start (Use Latest Files)\n",
  "- **Data**: `data/latest/comprehensive_immigration_attitudes.csv`\n",
  "- **Main Analysis**: `scripts/latest/enhanced_weighted_master.R`\n", 
  "- **Documentation**: `docs/latest/analysis_summary.md`\n\n",
  "## New Naming Convention\n",
  "All files now use: `TYPE_YYYY_MM_DD_description`\n",
  "- Latest versions symlinked in `*/latest/` folders\n",
  "- All dated versions archived in `*/archive/` folders\n",
  "- See `VERSION_HISTORY.md` for migration details\n\n",
  "## Current Status\n",
  "- **Generation Recovery**: 95.7% (35,871 observations)\n",
  "- **Best Coverage**: Restrictionism Index (62.7%, 9 years)\n",
  "- **Key Finding**: 1st gen volatile, 2nd gen stable, 3rd+ conservative\n",
  "- **Statistical**: Mixed-effects models with confidence intervals\n"
)

writeLines(strsplit(readme_update, "\n")[[1]], "README_CURRENT.md")

# =============================================================================
# 7. MIGRATION SUMMARY
# =============================================================================

message("\n=== MIGRATION SUMMARY ===")
successful <- sum(sapply(migration_log, function(x) x$success))
total <- length(migration_log)

message("Files migrated: ", successful, "/", total)
message("Created directories: ", length(dirs_to_create))
message("Metadata files created: LATEST_VERSION.txt, VERSION_HISTORY.md, README_CURRENT.md")

message("\n=== USAGE INSTRUCTIONS ===")
message("1. Use files in */latest/ folders for current work")
message("2. All analysis scripts should reference latest/ paths")
message("3. New files should follow DATE_TYPE_description naming")
message("4. Update VERSION_HISTORY.md when creating new versions")

message("\n=== MIGRATION TO DATE-BASED NAMING COMPLETE ===")

# Show current latest structure
message("\nCURRENT LATEST STRUCTURE:")
if (dir.exists("data/latest")) {
  message("data/latest/:")
  files <- list.files("data/latest")
  for (f in files) message("  ", f)
}
if (dir.exists("scripts/latest")) {
  message("scripts/latest/:")
  files <- list.files("scripts/latest") 
  for (f in files) message("  ", f)
}
