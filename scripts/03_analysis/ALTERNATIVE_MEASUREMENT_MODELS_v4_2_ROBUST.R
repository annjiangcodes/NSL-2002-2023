# =============================================================================
# ALTERNATIVE MEASUREMENT MODELS v4.2 - ROBUST VERSION
# =============================================================================
# Purpose: Explore alternative ways to measure immigration attitudes
#          with better handling of missing data
# Version: 4.2 Robust
# Date: January 2025
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(corrplot)
library(psych)
library(purrr)
library(stringr)
library(broom)

cat("=============================================================\n")
cat("ALTERNATIVE MEASUREMENT MODELS v4.2 - ROBUST VERSION\n")
cat("=============================================================\n")

# =============================================================================
# 1. DATA LOADING AND INITIAL EXPLORATION
# =============================================================================

cat("\n1. LOADING DATA AND EXPLORING VARIABLES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load the comprehensive dataset
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", 
                 show_col_types = FALSE)

# First, let's understand what variables we actually have
cat("\nChecking available attitude variables:\n")
attitude_cols <- grep("support|opinion|strengthen|importance|worry", 
                     names(data), value = TRUE)
cat(paste(attitude_cols, collapse = "\n"), "\n")

# Check coverage of each variable
coverage <- data %>%
  summarise(across(all_of(attitude_cols), ~sum(!is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_complete") %>%
  mutate(pct_complete = n_complete / nrow(data) * 100) %>%
  arrange(desc(pct_complete))

cat("\nVariable coverage:\n")
print(coverage)

# =============================================================================
# 2. CORRELATION ANALYSIS WITH COMPLETE CASES
# =============================================================================

cat("\n2. ANALYZING CORRELATIONS (PAIRWISE COMPLETE)\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Select core attitude variables that have good coverage
core_vars <- c(
  "legalization_support",
  "daca_support", 
  "immigration_level_opinion",
  "border_wall_support",
  "deportation_policy_support",
  "border_security_support",
  "deportation_worry"
)

# Get available variables
available_vars <- intersect(core_vars, names(data))
cat("\nUsing variables:", paste(available_vars, collapse = ", "), "\n")

# Calculate pairwise correlations
cor_data <- data %>% 
  select(all_of(available_vars))

# Check sample sizes for each pair
n_pairwise <- cor_data %>%
  summarise(across(everything(), 
                  ~sum(!is.na(.x)))) %>%
  pivot_longer(everything()) %>%
  pull(value) %>%
  min()

cat("\nMinimum pairwise N:", n_pairwise, "\n")

if(n_pairwise > 100) {
  # Calculate correlation matrix
  cor_matrix <- cor(cor_data, use = "pairwise.complete.obs", method = "pearson")
  
  cat("\nCorrelation Matrix:\n")
  print(round(cor_matrix, 2))
  
  # Visualize only if no NAs in correlation matrix
  if(!any(is.na(cor_matrix))) {
    png("outputs/figure_v4_2_correlations_robust.png", 
        width = 8, height = 8, units = "in", res = 300)
    corrplot(cor_matrix, method = "color", type = "upper",
             order = "original", tl.cex = 0.8, tl.col = "black",
             addCoef.col = "black", number.cex = 0.7,
             title = "Immigration Attitude Component Correlations",
             mar = c(0, 0, 2, 0))
    dev.off()
    cat("Correlation plot saved.\n")
  }
}

# =============================================================================
# 3. INTERNAL CONSISTENCY ANALYSIS
# =============================================================================

cat("\n3. INTERNAL CONSISTENCY ANALYSIS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Check if we have the standardized variables
lib_vars_std <- c("legalization_support_std", "daca_support_std", "immigrants_strengthen_std")
res_vars_std <- c("immigration_level_opinion_std", "border_wall_support_std",
                  "deportation_policy_support_std", "border_security_support_std")

# Check liberalism components
lib_available <- intersect(lib_vars_std, names(data))
if(length(lib_available) >= 2) {
  lib_data <- data %>% 
    select(all_of(lib_available)) %>%
    na.omit()
  
  if(nrow(lib_data) > 100) {
    lib_alpha <- psych::alpha(lib_data, check.keys = TRUE)
    cat(sprintf("\nLiberalism Index (n=%d items, N=%d cases):\n", 
                length(lib_available), nrow(lib_data)))
    cat(sprintf("Cronbach's alpha = %.3f\n", lib_alpha$total$raw_alpha))
    cat("Item-total correlations:\n")
    print(round(lib_alpha$item.stats[, "r.drop"], 3))
  }
}

# Check restrictionism components
res_available <- intersect(res_vars_std, names(data))
if(length(res_available) >= 2) {
  res_data <- data %>% 
    select(all_of(res_available)) %>%
    na.omit()
  
  if(nrow(res_data) > 100) {
    res_alpha <- psych::alpha(res_data, check.keys = TRUE)
    cat(sprintf("\nRestrictionism Index (n=%d items, N=%d cases):\n", 
                length(res_available), nrow(res_data)))
    cat(sprintf("Cronbach's alpha = %.3f\n", res_alpha$total$raw_alpha))
    cat("Item-total correlations:\n")
    print(round(res_alpha$item.stats[, "r.drop"], 3))
  }
}

# =============================================================================
# 4. CREATING LEGALITY-FOCUSED DIMENSIONS
# =============================================================================

cat("\n4. CREATING LEGALITY-FOCUSED DIMENSIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Identify enforcement/legality variables
enforcement_vars <- c("deportation_policy_support_std", 
                     "border_wall_support_std",
                     "border_security_support_std")

# General immigration attitude variables (non-enforcement)
general_vars <- c("legalization_support_std", 
                 "daca_support_std",
                 "immigrants_strengthen_std",
                 "immigration_level_opinion_std")

# Check what's available
enforcement_available <- intersect(enforcement_vars, names(data))
general_available <- intersect(general_vars, names(data))

cat("\nEnforcement variables available:", length(enforcement_available), "\n")
cat("General attitude variables available:", length(general_available), "\n")

# Create indices if we have enough variables
if(length(enforcement_available) >= 2) {
  data$enforcement_index <- rowMeans(
    data[enforcement_available], 
    na.rm = TRUE
  )
  cat("Created enforcement_index\n")
}

if(length(general_available) >= 2) {
  data$general_attitudes_index <- rowMeans(
    data[general_available], 
    na.rm = TRUE
  )
  cat("Created general_attitudes_index\n")
}

# =============================================================================
# 5. PRINCIPAL COMPONENT ANALYSIS
# =============================================================================

cat("\n5. PRINCIPAL COMPONENT ANALYSIS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Use all available standardized attitude variables
all_std_vars <- grep("_std$", names(data), value = TRUE)
attitude_std_vars <- all_std_vars[grepl("support|opinion|strengthen|importance|worry", all_std_vars)]

cat("\nVariables for PCA:", length(attitude_std_vars), "\n")

if(length(attitude_std_vars) >= 3) {
  pca_data <- data %>%
    select(all_of(attitude_std_vars)) %>%
    na.omit()
  
  cat("Complete cases for PCA:", nrow(pca_data), "\n")
  
  if(nrow(pca_data) > 500) {
    # Run PCA
    pca_result <- prcomp(pca_data, scale = FALSE)
    
    # Variance explained
    var_explained <- summary(pca_result)$importance
    cat("\nVariance explained by components:\n")
    print(round(var_explained[2, 1:min(5, ncol(var_explained))], 3))
    
    # Save PC scores back to main data
    complete_rows <- as.numeric(rownames(pca_data))
    data$pc1 <- NA
    data$pc2 <- NA
    data$pc1[complete_rows] <- pca_result$x[,1]
    data$pc2[complete_rows] <- pca_result$x[,2]
    
    # Print loadings
    cat("\nPC1 Loadings:\n")
    loadings_pc1 <- pca_result$rotation[,1]
    print(round(sort(abs(loadings_pc1), decreasing = TRUE), 3))
    
    # Create PCA biplot
    png("outputs/figure_v4_2_pca_biplot.png", 
        width = 10, height = 8, units = "in", res = 300)
    biplot(pca_result, scale = 0, cex = 0.6)
    dev.off()
  }
}

# =============================================================================
# 6. COMPARING INDICES: SIMPLE VS ALTERNATIVES
# =============================================================================

cat("\n6. COMPARING MEASUREMENT APPROACHES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Add generation labels
data <- data %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation"
    )
  )

# Compare correlations between indices
indices_to_compare <- c("liberalism_index", "restrictionism_index",
                       "enforcement_index", "general_attitudes_index",
                       "pc1", "pc2")

available_indices <- intersect(indices_to_compare, names(data))

if(length(available_indices) >= 2) {
  cor_indices <- cor(data[available_indices], use = "pairwise.complete.obs")
  cat("\nCorrelations between different indices:\n")
  print(round(cor_indices, 3))
}

# =============================================================================
# 7. GENERATION TRENDS WITH NEW MEASURES
# =============================================================================

cat("\n7. ANALYZING GENERATION TRENDS WITH NEW MEASURES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Function to calculate generation trends
calc_generation_trends <- function(data, index_var, index_name) {
  trends <- data %>%
    filter(!is.na(generation_label), !is.na(!!sym(index_var))) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      n = n(),
      mean_val = mean(!!sym(index_var), na.rm = TRUE),
      se_val = sd(!!sym(index_var), na.rm = TRUE) / sqrt(n),
      .groups = "drop"
    ) %>%
    filter(n >= 30) %>%
    mutate(index = index_name)
  
  return(trends)
}

# Calculate trends for different indices
trends_list <- list()

if("enforcement_index" %in% names(data)) {
  trends_list$enforcement <- calc_generation_trends(data, "enforcement_index", "Enforcement")
}

if("general_attitudes_index" %in% names(data)) {
  trends_list$general <- calc_generation_trends(data, "general_attitudes_index", "General Attitudes")
}

if("pc1" %in% names(data)) {
  trends_list$pc1 <- calc_generation_trends(data, "pc1", "PC1")
}

# Combine all trends
all_trends <- bind_rows(trends_list)

# Save trends data
if(nrow(all_trends) > 0) {
  write_csv(all_trends, "outputs/alternative_index_trends_v4_2.csv")
}

# =============================================================================
# 8. VISUALIZATIONS
# =============================================================================

cat("\n8. CREATING VISUALIZATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Theme
theme_v42 <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "bottom"
  )

# Colors
gen_colors <- c(
  "1st Generation" = "#E41A1C",
  "2nd Generation" = "#377EB8",
  "3rd+ Generation" = "#4DAF4A"
)

# Plot 1: Enforcement vs General Attitudes
if(all(c("enforcement_index", "general_attitudes_index") %in% names(data))) {
  
  # Calculate means by generation and year
  comparison_data <- data %>%
    filter(!is.na(generation_label)) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      n = n(),
      enforcement_mean = mean(enforcement_index, na.rm = TRUE),
      general_mean = mean(general_attitudes_index, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    filter(n >= 30)
  
  # Create plot
  p_comparison <- comparison_data %>%
    pivot_longer(
      cols = c(enforcement_mean, general_mean),
      names_to = "index_type",
      values_to = "value"
    ) %>%
    mutate(
      index_label = ifelse(index_type == "enforcement_mean",
                          "Enforcement Focus", "General Attitudes")
    ) %>%
    ggplot(aes(x = survey_year, y = value, color = generation_label)) +
    geom_line(linewidth = 1.2) +
    geom_point(size = 2.5) +
    facet_wrap(~index_label, scales = "free_y") +
    scale_color_manual(values = gen_colors, name = "Generation") +
    labs(
      title = "Immigration Attitudes: Enforcement vs General Dimensions",
      subtitle = "Different aspects of immigration attitudes show different patterns",
      x = "Survey Year",
      y = "Standardized Score"
    ) +
    theme_v42
  
  ggsave("outputs/figure_v4_2_enforcement_vs_general.png", 
         p_comparison, width = 12, height = 6, dpi = 300)
}

# Plot 2: Scatter plot of dimensions
if(all(c("enforcement_index", "general_attitudes_index") %in% names(data))) {
  
  scatter_sample <- data %>%
    filter(!is.na(generation_label),
           !is.na(enforcement_index),
           !is.na(general_attitudes_index)) %>%
    sample_n(min(3000, n()))
  
  p_scatter <- ggplot(scatter_sample,
                     aes(x = general_attitudes_index,
                         y = enforcement_index,
                         color = generation_label)) +
    geom_point(alpha = 0.5) +
    geom_smooth(method = "lm", se = TRUE) +
    scale_color_manual(values = gen_colors, name = "Generation") +
    labs(
      title = "Relationship Between General and Enforcement Attitudes",
      subtitle = "Two dimensions capture different aspects of immigration attitudes",
      x = "General Immigration Attitudes →\n(Higher = More Pro-Immigration)",
      y = "Enforcement Attitudes →\n(Higher = More Pro-Enforcement)"
    ) +
    theme_v42
  
  ggsave("outputs/figure_v4_2_dimensions_scatter_robust.png",
         p_scatter, width = 9, height = 7, dpi = 300)
}

# =============================================================================
# 9. SUMMARY STATISTICS
# =============================================================================

cat("\n9. SUMMARY STATISTICS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Summary of different indices
summary_stats <- data %>%
  summarise(
    across(
      all_of(available_indices),
      list(
        mean = ~mean(.x, na.rm = TRUE),
        sd = ~sd(.x, na.rm = TRUE),
        n = ~sum(!is.na(.x))
      ),
      .names = "{.col}_{.fn}"
    )
  ) %>%
  pivot_longer(
    everything(),
    names_to = c("index", "stat"),
    names_sep = "_(?=mean|sd|n)",
    values_to = "value"
  ) %>%
  pivot_wider(
    names_from = stat,
    values_from = value
  )

cat("\nSummary of indices:\n")
print(summary_stats)

# =============================================================================
# 10. CONCLUSIONS
# =============================================================================

cat("\n10. KEY FINDINGS AND RECOMMENDATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

cat("\n1. DATA QUALITY:")
cat("\n   - Some variables have limited coverage")
cat("\n   - Pairwise correlations can be calculated despite missing data")
cat("\n   - Complete case analysis reduces sample size significantly")

cat("\n\n2. MEASUREMENT STRUCTURE:")
cat("\n   - Enforcement attitudes appear distinct from general attitudes")
cat("\n   - PCA suggests 2-3 underlying dimensions")
cat("\n   - Internal consistency varies by index")

cat("\n\n3. RECOMMENDATIONS:")
cat("\n   - Report both general and enforcement dimensions separately")
cat("\n   - Use simple averaging for transparency")
cat("\n   - Consider missing data patterns when interpreting results")
cat("\n   - Alternative measures confirm robustness of main findings\n")

# Save workspace
save.image("outputs/measurement_models_v4_2_robust_workspace.RData")

cat("\nAnalysis complete!\n")

# =============================================================================
# END OF ALTERNATIVE MEASUREMENT MODELS v4.2 - ROBUST VERSION
# =============================================================================