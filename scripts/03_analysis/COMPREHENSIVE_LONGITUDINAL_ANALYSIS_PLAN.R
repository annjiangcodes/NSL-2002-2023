# =============================================================================
# COMPREHENSIVE LONGITUDINAL ANALYSIS PLAN FOR HISPANIC IMMIGRATION ATTITUDES
# =============================================================================
# Purpose: Enhanced analysis plan with aggregated/disaggregated analyses,
#          multiple visualization methods, and publication-ready outputs
# Date: January 2025
# Author: Research Team
# =============================================================================

# EXECUTIVE SUMMARY
# -----------------
# This comprehensive plan expands upon existing analyses to provide:
# 1. Aggregated overall Hispanic population trends (2002-2023)
# 2. Disaggregated generation-specific patterns (1st, 2nd, 3rd+ generations)
# 3. Period effects analysis (pre/post economic crisis, Trump era, COVID)
# 4. Demographic subgroup analyses (education, income, region, age cohorts)
# 5. Advanced visualization methods for publication
# 6. Theoretical interpretations and policy implications

# =============================================================================
# PART 1: ENHANCED DATA PREPARATION AND QUALITY CHECKS
# =============================================================================

# 1.1 Data Loading and Generation Recovery
# ----------------------------------------
# - Load COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
# - Apply generation recovery fixes for 2008, 2009, 2011, 2015, 2018, 2023
# - Create analytical weights combining survey weights with post-stratification
# - Handle missing data through multiple imputation for robustness checks

# 1.2 Variable Construction
# -------------------------
# Core Immigration Indices (existing):
# - liberalism_index: Support for legalization, DACA, immigrants strengthen
# - restrictionism_index: Support for border wall, deportation, limits
# - concern_index: Worry about deportation (limited years)

# New Composite Measures:
# - net_liberalism = liberalism_index - restrictionism_index
# - ambivalence_index = abs(liberalism_index) + abs(restrictionism_index)
# - polarization_index = within-group variance measure

# 1.3 Temporal Periodization
# ---------------------------
temporal_periods <- list(
  "Early Bush Era" = c(2002, 2004),
  "Immigration Reform Debates" = c(2006, 2007),
  "Economic Crisis Period" = c(2008, 2009, 2010),
  "Obama Era" = c(2011, 2012, 2013, 2014, 2015),
  "Trump Era" = c(2016, 2017, 2018),
  "COVID & Biden Era" = c(2021, 2022, 2023)
)

# =============================================================================
# PART 2: AGGREGATED ANALYSES - OVERALL HISPANIC POPULATION
# =============================================================================

# 2.1 Overall Temporal Trends
# ---------------------------
# - Weighted means and 95% CIs for each index by year
# - Smoothed trend lines using LOESS and splines
# - Change point detection for structural breaks
# - Decomposition into trend, seasonal, and irregular components

# 2.2 Period Effects Analysis
# ---------------------------
# - Average attitudes by temporal period
# - Difference-in-differences for period transitions
# - Event study design around key policy moments:
#   * 2006 Immigration protests
#   * 2012 DACA announcement
#   * 2016 Trump election
#   * 2020 COVID pandemic

# 2.3 Cohort Analysis
# --------------------
# - Birth cohort effects (Silent, Boomer, Gen X, Millennial, Gen Z)
# - Age-Period-Cohort (APC) decomposition
# - Within-cohort generational differences

# =============================================================================
# PART 3: DISAGGREGATED ANALYSES - GENERATION-SPECIFIC PATTERNS
# =============================================================================

# 3.1 Generation-Specific Trajectories
# ------------------------------------
# For each generation (1st, 2nd, 3rd+):
# - Individual trend lines with confidence bands
# - Growth curve modeling with random effects
# - Convergence/divergence tests between generations
# - Acceleration/deceleration of attitude change

# 3.2 Generational Assimilation Patterns
# ---------------------------------------
# Test classical assimilation hypotheses:
# - Straight-line assimilation: 3rd gen more restrictive than 1st
# - Segmented assimilation: 2nd gen divergence
# - Selective acculturation: Maintained pro-immigrant stance

# 3.3 Cross-Generational Comparisons
# -----------------------------------
# - Pairwise generation differences by year
# - Interaction effects: generation × time
# - Decomposition of between vs within-generation variance

# =============================================================================
# PART 4: DEMOGRAPHIC SUBGROUP ANALYSES
# =============================================================================

# 4.1 Education Effects
# ---------------------
# - Stratify by education (< HS, HS, Some College, College+)
# - Education × generation interactions
# - Test "education as liberalizing" hypothesis

# 4.2 Economic Status
# -------------------
# - Income quartiles analysis
# - Employment status effects
# - Economic vulnerability and restrictionism

# 4.3 Geographic Variation
# ------------------------
# - Regional differences (Southwest, Southeast, Northeast, etc.)
# - Border state vs interior effects
# - Urban/suburban/rural divides

# 4.4 Gender and Age Intersections
# ---------------------------------
# - Gender differences in attitudes
# - Age group patterns (18-29, 30-49, 50-64, 65+)
# - Intersectional analyses

# =============================================================================
# PART 5: ADVANCED STATISTICAL MODELING
# =============================================================================

# 5.1 Multilevel Growth Models
# ----------------------------
multilevel_model_spec <- "
  Level 1 (Time): Attitude_ij = β0j + β1j(Time) + εij
  Level 2 (Individual): β0j = γ00 + γ01(Generation) + γ02(Demographics) + u0j
                        β1j = γ10 + γ11(Generation) + u1j
"

# 5.2 Latent Class Growth Analysis
# ---------------------------------
# Identify distinct trajectory classes:
# - Stable liberals
# - Stable restrictionists
# - Convergers (moving to center)
# - Polarizers (moving to extremes)

# 5.3 Bayesian Trend Analysis
# ---------------------------
# - Incorporate prior information
# - Uncertainty quantification
# - Posterior predictive checks

# =============================================================================
# PART 6: PUBLICATION-QUALITY VISUALIZATIONS
# =============================================================================

# 6.1 Main Trend Visualization (Enhanced)
# ----------------------------------------
# - Dual-panel plot: Liberalism and Restrictionism
# - Generation-specific lines with confidence ribbons
# - Period shading for temporal contexts
# - Annotations for key events

# 6.2 Heatmap Visualization
# -------------------------
# - Year × Generation × Attitude intensity
# - Color gradients showing attitude strength
# - Side panels with marginal distributions

# 6.3 Sankey/Alluvial Diagrams
# -----------------------------
# - Flow of attitudes across time periods
# - Generation-specific flows
# - Transition probabilities visualization

# 6.4 Interactive Dashboard Components
# ------------------------------------
# - Shiny app with filters for:
#   * Time period selection
#   * Demographic subgroups
#   * Geographic regions
# - Downloadable custom plots

# 6.5 Small Multiples Grid
# ------------------------
# - Matrix of plots by:
#   * Generation × Education
#   * Generation × Region
#   * Generation × Age group
# - Consistent scales for comparison

# =============================================================================
# PART 7: THEORETICAL INTERPRETATIONS
# =============================================================================

# 7.1 Assimilation Theory Testing
# --------------------------------
# Classical Assimilation Predictions:
# - H1: 3rd generation converges to mainstream (more restrictive)
# - H2: Linear progression across generations
# - H3: Reduced ethnic solidarity over generations

# Segmented Assimilation Predictions:
# - H4: 2nd generation shows bifurcation
# - H5: Education moderates assimilation patterns
# - H6: Context of reception affects trajectories

# Racial Formation Theory:
# - H7: Persistent racialization limits convergence
# - H8: Reactive ethnicity in response to threats
# - H9: Pan-ethnic solidarity during hostile periods

# 7.2 Period Effect Interpretations
# ----------------------------------
# Economic Competition Theory:
# - Economic downturns → increased restrictionism
# - Labor market competition effects

# Political Threat Theory:
# - Anti-immigrant rhetoric → defensive liberalism
# - Rally effects around co-ethnics

# Contact Theory:
# - Increased diversity → reduced prejudice
# - Generation × contact interactions

# =============================================================================
# PART 8: POLICY IMPLICATIONS AND RECOMMENDATIONS
# =============================================================================

# 8.1 Key Findings Summary
# ------------------------
# - Overall trajectory of Hispanic attitudes
# - Generational convergence or persistence
# - Critical period effects
# - Demographic variations

# 8.2 Policy Relevance
# --------------------
# - Immigration reform coalition building
# - Generational targeting strategies
# - Regional policy variations
# - Economic integration programs

# 8.3 Future Research Directions
# -------------------------------
# - Panel data collection needs
# - Qualitative follow-up priorities
# - Comparative ethnic studies
# - Causal identification strategies

# =============================================================================
# PART 9: IMPLEMENTATION TIMELINE
# =============================================================================

# Phase 1 (Week 1): Data preparation and quality checks
# - Fix generation coding issues
# - Create analytical weights
# - Construct new variables

# Phase 2 (Week 2): Basic trend analyses
# - Overall population trends
# - Generation-specific patterns
# - Period effects

# Phase 3 (Week 3): Advanced modeling
# - Multilevel models
# - Subgroup analyses
# - Interaction effects

# Phase 4 (Week 4): Visualization and interpretation
# - Create all plots
# - Write interpretations
# - Prepare publication materials

# =============================================================================
# PART 10: QUALITY ASSURANCE CHECKLIST
# =============================================================================

quality_checks <- list(
  data_quality = c(
    "Missing data patterns documented",
    "Weight calibration verified",
    "Generation coding validated",
    "Outliers investigated"
  ),
  
  statistical_rigor = c(
    "Multiple testing corrections applied",
    "Sensitivity analyses conducted",
    "Robustness checks completed",
    "Assumptions verified"
  ),
  
  visualization_standards = c(
    "Color-blind friendly palettes",
    "Consistent scales across plots",
    "Clear labeling and legends",
    "Publication resolution (300+ dpi)"
  ),
  
  interpretive_validity = c(
    "Theoretical grounding clear",
    "Alternative explanations considered",
    "Limitations acknowledged",
    "Implications justified"
  )
)

# =============================================================================
# END OF COMPREHENSIVE ANALYSIS PLAN
# =============================================================================