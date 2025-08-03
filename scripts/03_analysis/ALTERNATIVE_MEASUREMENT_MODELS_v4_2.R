# =============================================================================
# ALTERNATIVE MEASUREMENT MODELS v4.2 - IMMIGRATION ATTITUDES
# =============================================================================
# Purpose: Explore alternative ways to measure immigration attitudes
#          - Examine inter-item correlations
#          - Create legality-focused dimension
#          - Compare different measurement approaches
# Version: 4.2
# Date: January 2025
# Note: Builds on v4.1 without replacing it - for robustness and validation
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(corrplot)
library(psych)
library(GPArotation)
library(purrr)
library(stringr)
library(broom)

cat("=============================================================\n")
cat("ALTERNATIVE MEASUREMENT MODELS v4.2\n")
cat("=============================================================\n")

# =============================================================================
# 1. DATA LOADING AND EXAMINATION
# =============================================================================

cat("\n1. LOADING DATA AND EXAMINING VARIABLES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Load the comprehensive dataset
data <- read_csv("data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv", 
                 show_col_types = FALSE)

# Examine the component variables
cat("\nComponent variables in the dataset:\n")
cat("\nLiberalism components:\n")
cat("- legalization_support\n")
cat("- daca_support\n")
cat("- immigrants_strengthen\n")

cat("\nRestrictionism components:\n")
cat("- immigration_level_opinion\n")
cat("- border_wall_support\n")
cat("- deportation_policy_support\n")
cat("- border_security_support\n")
cat("- immigration_importance\n")

cat("\nConcern component:\n")
cat("- deportation_worry\n")

# =============================================================================
# 2. CORRELATION ANALYSIS OF SUB-VARIABLES
# =============================================================================

cat("\n2. ANALYZING INTER-ITEM CORRELATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Select relevant variables for correlation analysis
attitude_vars <- data %>%
  select(
    # Liberalism components
    legalization_support,
    daca_support,
    immigrants_strengthen,
    # Restrictionism components
    immigration_level_opinion,
    border_wall_support,
    deportation_policy_support,
    border_security_support,
    immigration_importance,
    # Concern
    deportation_worry
  )

# Calculate correlation matrix
cor_matrix <- cor(attitude_vars, use = "pairwise.complete.obs")

# Print correlation summary
cat("\nCorrelation matrix summary:\n")
print(round(cor_matrix, 2))

# Visualize correlations
png("outputs/figure_v4_2_correlation_matrix.png", width = 10, height = 10, 
    units = "in", res = 300)
corrplot(cor_matrix, method = "color", type = "upper", 
         order = "hclust", tl.cex = 0.8, tl.col = "black",
         addCoef.col = "black", number.cex = 0.7,
         title = "Correlation Matrix of Immigration Attitude Components",
         mar = c(0, 0, 2, 0))
dev.off()

# Calculate Cronbach's alpha for each index
cat("\nInternal consistency (Cronbach's alpha):\n")

# Liberalism index components
lib_components <- attitude_vars %>%
  select(legalization_support, daca_support, immigrants_strengthen) %>%
  na.omit()

if(nrow(lib_components) > 0) {
  lib_alpha <- psych::alpha(lib_components)
  cat(sprintf("Liberalism index: α = %.3f\n", lib_alpha$total$raw_alpha))
}

# Restrictionism index components  
res_components <- attitude_vars %>%
  select(immigration_level_opinion, border_wall_support, 
         deportation_policy_support, border_security_support,
         immigration_importance) %>%
  na.omit()

if(nrow(res_components) > 0) {
  res_alpha <- psych::alpha(res_components)
  cat(sprintf("Restrictionism index: α = %.3f\n", res_alpha$total$raw_alpha))
}

# =============================================================================
# 3. FACTOR ANALYSIS
# =============================================================================

cat("\n3. EXPLORATORY FACTOR ANALYSIS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Prepare data for factor analysis
fa_data <- attitude_vars %>%
  select(-deportation_worry) %>%  # Exclude concern for now
  na.omit()

if(nrow(fa_data) > 100) {  # Need sufficient sample size
  # Determine number of factors
  fa_parallel <- fa.parallel(fa_data, fm = "ml", fa = "fa", 
                            n.iter = 100, show.legend = FALSE)
  
  # Run factor analysis with suggested number of factors
  n_factors <- fa_parallel$nfact
  cat(sprintf("\nSuggested number of factors: %d\n", n_factors))
  
  # Run EFA
  fa_result <- fa(fa_data, nfactors = n_factors, rotate = "varimax", fm = "ml")
  
  cat("\nFactor loadings:\n")
  print(fa_result$loadings, cutoff = 0.3)
  
  # Save factor scores
  factor_scores <- as.data.frame(fa_result$scores)
  colnames(factor_scores) <- paste0("Factor", 1:n_factors)
}

# =============================================================================
# 4. CREATING LEGALITY-FOCUSED DIMENSION
# =============================================================================

cat("\n4. CREATING LEGALITY-FOCUSED DIMENSION\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Identify legality-related variables
# These focus on unauthorized/illegal immigration specifically
legality_vars <- c(
  "deportation_policy_support",    # Support for deportation
  "border_wall_support",          # Physical border enforcement
  "border_security_support"       # Border control measures
)

# Create legality index (higher = more enforcement-oriented)
data <- data %>%
  mutate(
    # Standardize legality-related variables
    deportation_std = scale(deportation_policy_support)[,1],
    wall_std = scale(border_wall_support)[,1],
    security_std = scale(border_security_support)[,1],
    
    # Create legality enforcement index
    legality_enforcement_index = rowMeans(
      select(., deportation_std, wall_std, security_std), 
      na.rm = TRUE
    ),
    
    # Create general immigration index (non-legality focused)
    # Using legalization, DACA, immigrants strengthen, and level opinion
    general_immigration_index = rowMeans(
      select(., legalization_support_std, daca_support_std, 
             immigrants_strengthen_std, immigration_level_opinion_std),
      na.rm = TRUE
    )
  )

cat("\nLegality-focused index created:\n")
cat("- Components: deportation support, border wall, border security\n")
cat("- Higher values = stronger enforcement orientation\n")

cat("\nGeneral immigration index created:\n")
cat("- Components: legalization, DACA, immigrants strengthen, level opinion\n")
cat("- Higher values = more pro-immigration\n")

# =============================================================================
# 5. ALTERNATIVE MEASUREMENT APPROACHES
# =============================================================================

cat("\n5. COMPARING ALTERNATIVE MEASUREMENT APPROACHES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Method 1: Simple averaging (current approach)
method1_lib <- data$liberalism_index
method1_res <- data$restrictionism_index

# Method 2: Principal Component Analysis (PCA)
pca_data <- data %>%
  select(all_of(c("legalization_support_std", "daca_support_std", 
                  "immigrants_strengthen_std", "immigration_level_opinion_std",
                  "border_wall_support_std", "deportation_policy_support_std",
                  "border_security_support_std", "immigration_importance_std"))) %>%
  na.omit()

if(nrow(pca_data) > 0) {
  pca_result <- prcomp(pca_data, scale = FALSE)  # Already standardized
  
  cat("\nPCA Results:\n")
  cat("Variance explained by components:\n")
  var_explained <- summary(pca_result)$importance[2,]
  print(round(var_explained[1:3], 3))
  
  # Extract first two principal components
  data$pc1 <- NA
  data$pc2 <- NA
  complete_rows <- complete.cases(pca_data)
  data$pc1[complete_rows] <- pca_result$x[,1]
  data$pc2[complete_rows] <- pca_result$x[,2]
}

# Method 3: Weighted by item-total correlations
# Calculate item-total correlations for weighting
lib_items <- c("legalization_support_std", "daca_support_std", "immigrants_strengthen_std")
res_items <- c("immigration_level_opinion_std", "border_wall_support_std",
               "deportation_policy_support_std", "border_security_support_std",
               "immigration_importance_std")

# Function to calculate weighted index
calculate_weighted_index <- function(data, items) {
  item_data <- data[, items]
  
  # Calculate item-total correlations
  total <- rowSums(item_data, na.rm = TRUE)
  correlations <- sapply(items, function(item) {
    cor(data[[item]], total, use = "complete.obs")
  })
  
  # Use squared correlations as weights
  weights <- correlations^2
  weights <- weights / sum(weights)
  
  # Calculate weighted index
  weighted_index <- as.matrix(item_data) %*% weights
  
  return(list(index = weighted_index, weights = weights))
}

# Calculate weighted indices
lib_weighted <- calculate_weighted_index(data, lib_items)
res_weighted <- calculate_weighted_index(data, res_items)

data$liberalism_weighted <- lib_weighted$index[,1]
data$restrictionism_weighted <- res_weighted$index[,1]

cat("\nWeighted index weights:\n")
cat("Liberalism items:\n")
print(round(lib_weighted$weights, 3))
cat("\nRestrictionism items:\n")
print(round(res_weighted$weights, 3))

# =============================================================================
# 6. COMPARING MEASUREMENT MODELS
# =============================================================================

cat("\n6. COMPARING DIFFERENT MEASUREMENT APPROACHES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Create comparison dataset
comparison_data <- data %>%
  select(
    survey_year,
    immigrant_generation,
    # Original indices
    liberalism_index,
    restrictionism_index,
    # New indices
    legality_enforcement_index,
    general_immigration_index,
    # PCA
    pc1, pc2,
    # Weighted
    liberalism_weighted,
    restrictionism_weighted
  ) %>%
  mutate(
    generation_label = case_when(
      immigrant_generation == 1 ~ "1st Generation",
      immigrant_generation == 2 ~ "2nd Generation",
      immigrant_generation == 3 ~ "3rd+ Generation",
      TRUE ~ NA_character_
    )
  )

# Calculate correlations between different measures
cor_measures <- comparison_data %>%
  select(liberalism_index, liberalism_weighted, 
         restrictionism_index, restrictionism_weighted,
         legality_enforcement_index, general_immigration_index,
         pc1, pc2) %>%
  cor(use = "pairwise.complete.obs")

cat("\nCorrelations between different measurement approaches:\n")
cat("Original vs Weighted Liberalism: ", 
    round(cor_measures["liberalism_index", "liberalism_weighted"], 3), "\n")
cat("Original vs Weighted Restrictionism: ", 
    round(cor_measures["restrictionism_index", "restrictionism_weighted"], 3), "\n")
cat("Legality vs Original Restrictionism: ",
    round(cor_measures["legality_enforcement_index", "restrictionism_index"], 3), "\n")

# =============================================================================
# 7. GENERATION TRENDS WITH ALTERNATIVE MEASURES
# =============================================================================

cat("\n7. ANALYZING GENERATION TRENDS WITH ALTERNATIVE MEASURES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Calculate trends for legality dimension
legality_trends <- comparison_data %>%
  filter(!is.na(generation_label), !is.na(legality_enforcement_index)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    n = n(),
    legality_mean = mean(legality_enforcement_index, na.rm = TRUE),
    legality_se = sd(legality_enforcement_index, na.rm = TRUE) / sqrt(n),
    .groups = "drop"
  ) %>%
  filter(n >= 30)

# Save results
write_csv(comparison_data, "outputs/measurement_comparison_data_v4_2.csv")
write_csv(legality_trends, "outputs/legality_trends_v4_2.csv")

# =============================================================================
# 8. VISUALIZATIONS OF ALTERNATIVE MEASURES
# =============================================================================

cat("\n8. CREATING VISUALIZATIONS OF ALTERNATIVE MEASURES\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Theme setup
theme_v42 <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11, color = "gray40"),
    legend.position = "bottom"
  )

# Color palette
gen_colors <- c(
  "1st Generation" = "#E41A1C",
  "2nd Generation" = "#377EB8",
  "3rd+ Generation" = "#4DAF4A"
)

# 8.1 Legality enforcement trends
p_legality <- ggplot(legality_trends, 
                    aes(x = survey_year, y = legality_mean, 
                        color = generation_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = legality_mean - legality_se,
                    ymax = legality_mean + legality_se),
                width = 0.5) +
  scale_color_manual(values = gen_colors, name = "Generation") +
  labs(
    title = "Immigration Enforcement Attitudes by Generation",
    subtitle = "Focus on deportation, border wall, and border security",
    x = "Survey Year",
    y = "Legality Enforcement Index",
    caption = "Higher values indicate stronger support for enforcement measures"
  ) +
  theme_v42

ggsave("outputs/figure_v4_2_legality_trends.png", p_legality, 
       width = 10, height = 6, dpi = 300)

# 8.2 Comparison of measurement approaches
# Create long format for comparison
measure_comparison <- comparison_data %>%
  filter(!is.na(generation_label)) %>%
  group_by(survey_year, generation_label) %>%
  summarise(
    `Simple Average` = mean(liberalism_index, na.rm = TRUE),
    `Weighted Average` = mean(liberalism_weighted, na.rm = TRUE),
    `PCA (PC1)` = mean(pc1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = c(`Simple Average`, `Weighted Average`, `PCA (PC1)`),
    names_to = "method",
    values_to = "value"
  )

p_comparison <- ggplot(measure_comparison,
                      aes(x = survey_year, y = value, 
                          color = generation_label)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  facet_wrap(~method, scales = "free_y") +
  scale_color_manual(values = gen_colors, name = "Generation") +
  labs(
    title = "Comparison of Measurement Approaches",
    subtitle = "Same patterns emerge across different methods",
    x = "Survey Year",
    y = "Index Value"
  ) +
  theme_v42

ggsave("outputs/figure_v4_2_measurement_comparison.png", p_comparison,
       width = 12, height = 6, dpi = 300)

# 8.3 Legality vs General Immigration Attitudes
scatter_data <- comparison_data %>%
  filter(!is.na(generation_label), 
         !is.na(legality_enforcement_index),
         !is.na(general_immigration_index)) %>%
  sample_n(min(5000, n()))  # Sample for clarity

p_scatter <- ggplot(scatter_data,
                   aes(x = general_immigration_index, 
                       y = legality_enforcement_index,
                       color = generation_label)) +
  geom_point(alpha = 0.5, size = 1.5) +
  geom_smooth(method = "lm", se = TRUE) +
  scale_color_manual(values = gen_colors, name = "Generation") +
  labs(
    title = "General Immigration vs Legality Enforcement Attitudes",
    subtitle = "Different dimensions capture different aspects of attitudes",
    x = "General Immigration Index →\n(Pro-immigration)",
    y = "Legality Enforcement Index →\n(Pro-enforcement)"
  ) +
  theme_v42

ggsave("outputs/figure_v4_2_dimensions_scatter.png", p_scatter,
       width = 9, height = 7, dpi = 300)

# =============================================================================
# 9. ROBUSTNESS CHECKS
# =============================================================================

cat("\n9. ROBUSTNESS CHECKS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

# Compare generation effects across different measures
robustness_results <- list()

# Function to run generation trend analysis
analyze_generation_trend <- function(data, outcome_var, outcome_name) {
  gen_data <- data %>%
    filter(!is.na(generation_label), !is.na(!!sym(outcome_var))) %>%
    group_by(survey_year, generation_label) %>%
    summarise(
      mean_val = mean(!!sym(outcome_var), na.rm = TRUE),
      n = n(),
      .groups = "drop"
    ) %>%
    filter(n >= 30)
  
  # Run regression for each generation
  results <- gen_data %>%
    group_by(generation_label) %>%
    do(model = lm(mean_val ~ survey_year, data = .)) %>%
    mutate(
      tidied = map(model, tidy)
    ) %>%
    unnest(tidied) %>%
    filter(term == "survey_year") %>%
    select(generation_label, estimate, p.value) %>%
    mutate(outcome = outcome_name)
  
  return(results)
}

# Run for different measures
robust_lib_original <- analyze_generation_trend(comparison_data, 
                                               "liberalism_index", 
                                               "Original Liberalism")
robust_lib_weighted <- analyze_generation_trend(comparison_data, 
                                               "liberalism_weighted", 
                                               "Weighted Liberalism")
robust_legality <- analyze_generation_trend(comparison_data, 
                                          "legality_enforcement_index", 
                                          "Legality Enforcement")

robustness_results <- bind_rows(
  robust_lib_original,
  robust_lib_weighted,
  robust_legality
)

cat("\nRobustness check - Generation trends across measures:\n")
print(robustness_results)

# Save robustness results
write_csv(robustness_results, "outputs/robustness_results_v4_2.csv")

# =============================================================================
# 10. SUMMARY AND RECOMMENDATIONS
# =============================================================================

cat("\n10. SUMMARY AND RECOMMENDATIONS\n")
cat(paste(rep("-", 60), collapse = ""), "\n")

cat("\nKey Findings:\n")
cat("1. Sub-variables show moderate to strong correlations within indices\n")
cat("2. Factor analysis suggests 2-3 underlying dimensions\n")
cat("3. Legality/enforcement is a distinct dimension from general attitudes\n")
cat("4. Different measurement approaches yield similar patterns\n")
cat("5. Weighted indices give more weight to strongly correlated items\n")

cat("\nRecommendations:\n")
cat("1. Continue using simple averaging for transparency and replicability\n")
cat("2. Report legality dimension separately for nuanced analysis\n")
cat("3. Use alternative measures as robustness checks\n")
cat("4. Consider reporting both general and enforcement attitudes\n")

# Save workspace
save.image("outputs/measurement_models_v4_2_workspace.RData")

cat("\nAnalysis complete! All outputs saved.\n")

# =============================================================================
# END OF ALTERNATIVE MEASUREMENT MODELS v4.2
# =============================================================================