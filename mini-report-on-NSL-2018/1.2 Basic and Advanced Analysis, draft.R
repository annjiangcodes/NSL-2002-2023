
# -------------------------------
# Start logging

# For regular output
sink("my_console_log4.txt")

# For messages and warnings
message_con <- file("my_console_log4_messages.txt", open = "wt")
sink(message_con, type = "message")

# entire code here...




# Check and install required packages
required_packages <- c("survey", "ggplot2", "vcd", "dplyr", "reshape2", "tidyr", 
                       "broom", "psych", "MatchIt", "stargazer", "tidytext", "maps")

# Only install missing packages
new_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]
if(length(new_packages) > 0) {
  install.packages(new_packages)
}

# Load all required packages
invisible(lapply(required_packages, library, character.only = TRUE))

# Data Preparation
# Use a more portable way to set working directory or use relative paths
setwd("/Users/azure/Desktop/Coursework/PhD Coursework/Survey Analysis--Anti-Immigration Immigrant/Pew-Research-Center_2018-National-Survey-of-Latinos-Dataset 2")

# Read data
nsl_data <- read.csv("NSL2018_data.csv", stringsAsFactors = FALSE)

# Convert variables to appropriate types early
nsl_data$age <- as.numeric(as.character(nsl_data$age))

# -------------------------------
# 1. Data Preparation and Weighting
setwd("/Users/azure/Desktop/Coursework/PhD Coursework/Survey Analysis--Anti-Immigration Immigrant/Pew-Research-Center_2018-National-Survey-of-Latinos-Dataset 2")
nsl_data <- read.csv("NSL2018_data.csv", stringsAsFactors = FALSE)
str(nsl_data)
summary(nsl_data)
head(nsl_data$weight)

# -------------------------------
# 2. Isolating the Foreign-Born Subsample
# qn4 responses are documented as words: e.g., "U.S.", "Puerto Rico", or "another country".
# Here, we recode foreign_born = 1 if qn4 equals "another country" (as documented in your code), 0 otherwise.
unique_vals_qn4 <- unique(tolower(trimws(nsl_data$qn4)))
print(unique_vals_qn4)

nsl_data <- nsl_data %>%
  mutate(foreign_born = ifelse(tolower(trimws(qn4)) == "another country", 1, 0))
table(nsl_data$foreign_born)

# -------------------------------
# 3. Defining Outcome Variables Using Documented Coding

# (a) Trump Support (qn14a)
nsl_data <- nsl_data %>%
  mutate(trump_support = case_when(
    tolower(trimws(qn14a)) == "approve"    ~ 1,
    tolower(trimws(qn14a)) == "disapprove" ~ 0,
    TRUE ~ NA_real_
  ))
table(nsl_data$trump_support, useNA="ifany")

# (b) Border Wall Opinion (qn29)
nsl_data <- nsl_data %>%
  mutate(favor_wall = case_when(
    tolower(trimws(qn29)) == "favor"  ~ 1,
    tolower(trimws(qn29)) == "oppose" ~ 0,
    TRUE ~ NA_real_
  ))
table(nsl_data$favor_wall, useNA="ifany")

# (c) Opinion on Immigrant Population (qn31)
nsl_data <- nsl_data %>%
  mutate(too_many_imm = case_when(
    tolower(trimws(qn31)) == "too many" ~ 1,
    tolower(trimws(qn31)) %in% c("too few", "right amount") ~ 0,
    TRUE ~ NA_real_
  ))
table(nsl_data$too_many_imm, useNA="ifany")

# (d) Conservative Orientation – Party Identification (party)
nsl_data <- nsl_data %>%
  mutate(conservative = case_when(
    tolower(trimws(party)) == "republican" ~ 1,
    tolower(trimws(party)) %in% c("democrat", "independent") ~ 0,
    TRUE ~ NA_real_
  ))
table(nsl_data$conservative, useNA="ifany")

# (e) Composite Indicator: If any one is 1, then composite = 1; otherwise 0.
nsl_data <- nsl_data %>%
  mutate(cons_antiimm = ifelse(trump_support == 1 | favor_wall == 1 | too_many_imm == 1 | conservative == 1, 1, 0))
table(nsl_data$cons_antiimm, useNA="ifany")

# -------------------------------
# 4. Survey Design Setup
nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)
# Create a design for foreign-born respondents only
foreign_design <- subset(nsl_design, foreign_born == 1)

# -------------------------------
# 5a. Descriptive Analysis: Weighted Proportions (for foreign-born)
trump_prop    <- svymean(~trump_support, design = foreign_design, na.rm = TRUE)
wall_prop     <- svymean(~favor_wall, design = foreign_design, na.rm = TRUE)
imm_prop      <- svymean(~too_many_imm, design = foreign_design, na.rm = TRUE)
party_prop    <- svymean(~conservative, design = foreign_design, na.rm = TRUE)
composite_prop<- svymean(~cons_antiimm, design = foreign_design, na.rm = TRUE)

print(trump_prop)
print(wall_prop)
print(imm_prop)
print(party_prop)
print(composite_prop)

# -------------------------------
# 5b. Cross-Tabulations
# (i) Within foreign-born subsample: Example: Trump support by party identification
table_trump_party <- svytable(~trump_support + party, design = foreign_design)
print("Foreign-born: Trump Support vs Party Identification")
print(table_trump_party)

# (ii) Within foreign-born subsample: Border wall vs Immigrant population opinion
table_wall_imm <- svytable(~favor_wall + too_many_imm, design = foreign_design)
print("Foreign-born: Favor Wall vs Too Many Immigrants")
print(table_wall_imm)

# (iii) For full sample, cross-tabulate foreign_born with each anti-immigration metric:
# Foreign Born vs. Trump Support
table_foreign_trump <- svytable(~ foreign_born + trump_support, design = nsl_design)
print("Full Sample: Foreign Born vs Trump Support")
print(table_foreign_trump)

# Foreign Born vs. Favor Wall
table_foreign_wall <- svytable(~ foreign_born + favor_wall, design = nsl_design)
print("Full Sample: Foreign Born vs Favor Wall")
print(table_foreign_wall)

# Foreign Born vs. Too Many Immigrants
table_foreign_imm <- svytable(~ foreign_born + too_many_imm, design = nsl_design)
print("Full Sample: Foreign Born vs Too Many Immigrants")
print(table_foreign_imm)

# Foreign Born vs. Conservative Orientation
table_foreign_party <- svytable(~ foreign_born + conservative, design = nsl_design)
print("Full Sample: Foreign Born vs Conservative (Party)")
print(table_foreign_party)

# Foreign Born vs. Composite Indicator
table_foreign_composite <- svytable(~ foreign_born + cons_antiimm, design = nsl_design)
print("Full Sample: Foreign Born vs Composite Conservative/Anti-Immigration")
print(table_foreign_composite)

# -------------------------------
# 5c. Additional Inferential Analysis

# Additional Chi-square tests (Full Sample)
chi_trump_wall <- svychisq(~ trump_support + favor_wall, design = nsl_design)
print("Chi-square: Trump Support vs Favor Wall (Full Sample)")
print(chi_trump_wall)

chi_trump_imm <- svychisq(~ trump_support + too_many_imm, design = nsl_design)
print("Chi-square: Trump Support vs Too Many Immigrants (Full Sample)")
print(chi_trump_imm)

chi_wall_imm <- svychisq(~ favor_wall + too_many_imm, design = nsl_design)
print("Chi-square: Favor Wall vs Too Many Immigrants (Full Sample)")
print(chi_wall_imm)

# T-test: Compare mean age between foreign-born and U.S.-born respondents
class(nsl_data$age)
nsl_data <- nsl_data %>%
  mutate(age = as.numeric(as.character(age)))

nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)
ttest_age <- svyttest(age ~ factor(foreign_born), design = nsl_design)
print(ttest_age)




# T-test: Compare mean age among foreign-born respondents by Trump support

# -------------------------------
# 5d. Visualizations

# Create a data frame for weighted proportions among foreign-born
antiimm_df <- data.frame(
  Metric = c("Trump Support", "Favor Wall", "Too Many Immigrants", "Conservative", "Composite"),
  Proportion = c(coef(trump_prop), coef(wall_prop), coef(imm_prop), coef(party_prop), coef(composite_prop))
)

# Bar plot of anti-immigration indicators among foreign-born Hispanics
ggplot(antiimm_df, aes(x = Metric, y = Proportion)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  ylim(0,1) +
  ylab("Weighted Proportion") +
  ggtitle("Anti-Immigration Indicators Among Foreign-Born Hispanics") +
  theme_minimal()

# Mosaic plot for full sample: Foreign-born vs. Trump Support
mosaic(~ foreign_born + trump_support, data = nsl_data, shade = TRUE, legend = TRUE,
       main = "Mosaic Plot: Foreign-born vs Trump Support")

# -------------------------------
# 5e. Descriptive Statistics

# Descriptive stats for age and education by foreign-born status using svyby
desc_stats <- svyby(~ age + educ, ~ foreign_born, design = nsl_design, FUN = svymean, na.rm = TRUE)
print("Descriptive Statistics for Age and Education by Foreign-born Status:")
print(desc_stats)

# For additional descriptive summaries, you could use summary() on the design:
summary(nsl_design)

# -------------------------------
# 6. Exporting Results
descriptives <- data.frame(
  Variable = c("Trump Support", "Favor Wall", "Too Many Immigrants", 
               "Republican Identification", "Composite Indicator"),
  Proportion = c(coef(trump_prop), coef(wall_prop), coef(imm_prop), 
                 coef(party_prop), coef(composite_prop))
)
write.csv(descriptives, "foreign_born_descriptives2.csv", row.names = FALSE)

# -------------------------------ADDITIONAL ADVANCED ANALYSIS-------------------

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
library(broom)
library(ggplot2)

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
library(survey)
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

# Visualize predicted probabilities from interaction model
# Create a grid of values for prediction


# Plot interaction


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
library(reshape2)
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

# 5.1 Attitude composition by demographic group
# Reshape data for plotting

# --------------------------------
# 6. ADVANCED STATISTICAL TECHNIQUES
# --------------------------------

# 6.1 Factor Analysis to identify latent dimensions




# 6.2 Comparison with Native-Born Hispanics (Propensity Score Matching)
# This is a sketch - full implementation would require more setup





# --------------------------------
# 7. OUTPUT AND REPORTING
# --------------------------------

# Save key results to a comprehensive report
result_list <- list(
  descriptives = list(
    trump = trump_prop,
    wall = wall_prop,
    imm = imm_prop,
    conservative = party_prop,
    composite = composite_prop
  ),
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
save(result_list, file = "nsl_analysis_results.RData")

# Create table of regression results using stargazer


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


#End Logging Results
# Don't forget to close both sinks at the end
sink() # Close the regular output sink
sink(type = "message") # Close the message sink
close(message_con) # Close the connection
