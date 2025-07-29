# -------------------------------
# Start logging for advanced analysis

# For regular output
sink("advanced_analysis_log.txt")

# For messages and warnings
message_con <- file("advanced_analysis_messages.txt", open = "wt")
sink(message_con, type = "message")

# Load required packages
required_packages <- c("survey", "ggplot2", "vcd", "dplyr", "reshape2", "tidyr", 
                       "broom", "psych", "MatchIt", "stargazer")

# Only install missing packages
new_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]
if(length(new_packages) > 0) {
  install.packages(new_packages)
}

# Load all required packages
invisible(lapply(required_packages, library, character.only = TRUE))

# Load the data prepared in the basic analysis
load("nsl_prepared_data.RData")

# ------------------------------------------------------------------------------
# 1. REGRESSION ANALYSES
# --------------------------------

# Logistic regression for each outcome variable
# Trump support model
model_trump <- svyglm(trump_support ~ age + factor(educ) + factor(sex), 
                      design = foreign_design, family = quasibinomial())
summary(model_trump)

# Border wall support model
model_wall <- svyglm(favor_wall ~ age + factor(educ) + factor(sex), 
                     design = foreign_design, family = quasibinomial())
summary(model_wall)

# Too many immigrants model
model_imm <- svyglm(too_many_imm ~ age + factor(educ) + factor(sex), 
                    design = foreign_design, family = quasibinomial())
summary(model_imm)

# Composite conservative/anti-immigration model
model_composite <- svyglm(cons_antiimm ~ age + factor(educ) + factor(sex), 
                          design = foreign_design, family = quasibinomial())
summary(model_composite)

# Calculate and plot odds ratios for clearer interpretation
# Function to extract odds ratios and confidence intervals
get_odds_ratios <- function(model) {
  tidy_model <- tidy(model, conf.int = TRUE, exponentiate = TRUE)
  tidy_model <- tidy_model[tidy_model$term != "(Intercept)", ]
  return(tidy_model)
}

# Get odds ratios for all models
odds_trump <- get_odds_ratios(model_trump)
odds_wall <- get_odds_ratios(model_wall)
odds_imm <- get_odds_ratios(model_imm)
odds_composite <- get_odds_ratios(model_composite)

# Add model identifier
odds_trump$model <- "Trump Support"
odds_wall$model <- "Border Wall Support"
odds_imm$model <- "Too Many Immigrants"
odds_composite$model <- "Composite Measure"

# Combine for plotting
all_odds <- rbind(odds_trump, odds_wall, odds_imm, odds_composite)

# Plot odds ratios
ggplot(all_odds, aes(x = term, y = estimate, color = model)) +
  geom_point(position = position_dodge(width = 0.5), size = 3) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), 
                position = position_dodge(width = 0.5), width = 0.2) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  coord_flip() +
  scale_y_log10() +
  labs(title = "Odds Ratios for Anti-Immigration Attitudes",
       x = "Predictors", y = "Odds Ratio (log scale)",
       color = "Outcome") +
  theme_minimal()

# --------------------------------
# 2. ADVANCED DEMOGRAPHIC BREAKDOWNS
# --------------------------------

# Create meaningful age groups 
nsl_data <- nsl_data %>%
  mutate(age_group = cut(age, breaks = c(18, 30, 45, 60, 100), 
                         labels = c("18-29", "30-44", "45-59", "60+")))

# Update survey design with new variables
nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)
foreign_design <- subset(nsl_design, foreign_born == 1)

# Explore how views differ by age group
age_breakdown <- svyby(~trump_support + favor_wall + too_many_imm + conservative, 
                       ~age_group, design = foreign_design, svymean, na.rm = TRUE)
print(age_breakdown)

# Years in the US (if this variable exists in your dataset, e.g., 'years_in_us')
# If it doesn't exist but you have year of immigration, you can create it
if("year_immigration" %in% names(nsl_data)) {
  nsl_data <- nsl_data %>%
    mutate(years_in_us = 2018 - as.numeric(as.character(year_immigration)))
  
  # Create years in US groups
  nsl_data <- nsl_data %>%
    mutate(time_in_us = cut(years_in_us, 
                            breaks = c(0, 5, 10, 20, 100), 
                            labels = c("<5 years", "5-10 years", "10-20 years", "20+ years")))
  
  # Update survey design
  nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)
  foreign_design <- subset(nsl_design, foreign_born == 1)
  
  # Breakdown by time in US
  time_breakdown <- svyby(~trump_support + favor_wall + too_many_imm + conservative, 
                          ~time_in_us, design = foreign_design, svymean, na.rm = TRUE)
  print(time_breakdown)
}

# Citizenship status (if available in your dataset as 'citizenship')
if("citizenship" %in% names(nsl_data)) {
  citizen_breakdown <- svyby(~trump_support + favor_wall + too_many_imm + conservative, 
                             ~citizenship, design = foreign_design, svymean, na.rm = TRUE)
  print(citizen_breakdown)
}

# Country of origin (using qn5 if that's the variable containing this info)
if("qn5" %in% names(nsl_data)) {
  # Get the top 5 countries of origin
  top_countries <- names(sort(table(nsl_data$qn5[nsl_data$foreign_born == 1]), decreasing = TRUE)[1:5])
  
  # Filter for only top countries to avoid small cell sizes
  country_data <- subset(foreign_design, qn5 %in% top_countries)
  
  country_breakdown <- svyby(~trump_support + favor_wall + too_many_imm + conservative, 
                             ~qn5, design = country_data, svymean, na.rm = TRUE)
  print(country_breakdown)
}

# --------------------------------
# 3. INTERACTION EFFECTS
# --------------------------------

# Age and education interaction - does the effect of education vary by age?
interaction_model <- svyglm(cons_antiimm ~ age*factor(educ), 
                            design = foreign_design, family = quasibinomial())
summary(interaction_model)

# --------------------------------
# 4. CORRELATION ANALYSIS
# --------------------------------

# Create correlation matrix of key outcomes
# Select only the outcome variables and handle missing values
outcomes <- nsl_data %>% 
  filter(foreign_born == 1) %>%
  select(trump_support, favor_wall, too_many_imm, conservative) %>%
  na.omit()

# Calculate correlation matrix
cor_matrix <- cor(outcomes)
print(cor_matrix)

# Visualize correlation matrix
cor_long <- melt(cor_matrix)

ggplot(cor_long, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0) +
  geom_text(aes(label = round(value, 2)), color = "black", size = 3) +
  theme_minimal() +
  labs(title = "Correlation Between Anti-Immigration Attitudes",
       x = "", y = "", fill = "Correlation") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# --------------------------------
# 5. ADVANCED VISUALIZATIONS
# --------------------------------

# Create a dataset for demographic comparison
demo_comp <- nsl_data %>%
  select(foreign_born, age_group, educ, sex, trump_support, favor_wall, too_many_imm, conservative)

# Example: Create stacked bar chart comparing attitudes by education level among foreign-born
if(sum(!is.na(nsl_data$educ)) > 0) {
  # First, ensure education is a factor with meaningful labels
  nsl_data <- nsl_data %>%
    mutate(educ_level = factor(educ, 
                              levels = sort(unique(educ)),
                              labels = paste("Education Level", sort(unique(educ)))))
  
  # Update survey design
  nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)
  foreign_design <- subset(nsl_design, foreign_born == 1)
  
  # Get proportions by education level
  educ_breakdown <- svyby(~trump_support + favor_wall + too_many_imm + conservative, 
                          ~educ_level, design = foreign_design, svymean, na.rm = TRUE)
  
  # Convert to long format for plotting
  educ_long <- reshape2::melt(educ_breakdown, id.vars = "educ_level")
  
  # Plot
  ggplot(educ_long, aes(x = educ_level, y = value, fill = variable)) +
    geom_bar(stat = "identity", position = "dodge") +
    scale_fill_brewer(palette = "Set1", 
                     labels = c("Trump Support", "Favor Wall", "Too Many Immigrants", "Conservative")) +
    labs(title = "Anti-Immigration Attitudes by Education Level",
         x = "Education Level", y = "Proportion", fill = "Attitude") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# --------------------------------
# 6. ADVANCED STATISTICAL TECHNIQUES
# --------------------------------

# 6.1 Factor Analysis to identify latent dimensions
if(require(psych)) {
  # Extract just the attitude variables for foreign-born respondents
  attitude_vars <- nsl_data %>%
    filter(foreign_born == 1) %>%
    select(trump_support, favor_wall, too_many_imm, conservative) %>%
    na.omit()
  
  # Check if we have enough complete cases
  if(nrow(attitude_vars) > 50) {
    # Perform factor analysis
    fa_result <- fa(attitude_vars, nfactors = 2, rotate = "varimax")
    print(fa_result)
    
    # Visualize factor loadings
    fa.diagram(fa_result)
  } else {
    print("Not enough complete cases for factor analysis")
  }
}

# 6.2 Comparison with Native-Born Hispanics (Propensity Score Matching)
if(require(MatchIt)) {
  # Prepare data for matching
  match_data <- nsl_data %>%
    select(foreign_born, age, educ, sex, trump_support) %>%
    na.omit()
  
  # Only proceed if we have enough data
  if(nrow(match_data) > 100) {
    # Propensity score matching
    match_model <- matchit(foreign_born ~ age + factor(educ) + factor(sex),
                          data = match_data, method = "nearest")
    
    # Get matched data
    matched_data <- match.data(match_model)
    
    # Analyze differences in matched sample
    t.test(trump_support ~ foreign_born, data = matched_data)
    
    # Compare with unmatched sample
    t.test(trump_support ~ foreign_born, data = match_data)
  } else {
    print("Not enough complete cases for propensity score matching")
  }
}

# --------------------------------
# 7. OUTPUT AND REPORTING
# --------------------------------

# Save key results to a comprehensive report
result_list <- list(
  models = list(
    trump = model_trump,
    wall = model_wall,
    imm = model_imm,
    composite = model_composite,
    interaction = interaction_model
  ),
  demographics = list(
    age = age_breakdown
    # Add others if available
  ),
  correlation = cor_matrix
)

# Save as RData for future analysis
save(result_list, file = "nsl_advanced_analysis_results.RData")

# Print regression tables (can be saved to HTML or LaTeX)
stargazer(model_trump, model_wall, model_imm, model_composite,
          title = "Predictors of Anti-Immigration Attitudes Among Foreign-Born Hispanics",
          type = "text",
          out = "regression_results.txt")

# Generate summary statistics table
stargazer(as.data.frame(nsl_data %>% filter(foreign_born == 1) %>% 
                          select(age, trump_support, favor_wall, too_many_imm, conservative)),
          title = "Descriptive Statistics for Foreign-Born Hispanics",
          type = "text",
          out = "descriptive_stats.txt")

# Create a comprehensive markdown report
cat("# Analysis of Anti-Immigration Attitudes Among Foreign-Born Hispanics\n\n", 
    file = "analysis_report.md")

cat("## Regression Results\n\n", 
    "See [regression_results.txt](regression_results.txt) for detailed regression tables.\n\n",
    file = "analysis_report.md", 
    append = TRUE)

cat("## Demographic Breakdowns\n\n", 
    "Anti-immigration attitudes vary by age group:\n\n",
    capture.output(print(age_breakdown)),
    file = "analysis_report.md", 
    append = TRUE)

cat("\n\n## Correlation Between Attitudes\n\n", 
    capture.output(print(cor_matrix)),
    file = "analysis_report.md", 
    append = TRUE)

# Close sinks
sink() # Close the regular output sink
sink(type = "message") # Close the message sink
close(message_con) # Close the connection
