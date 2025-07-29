# -------------------------------
# Revised Analysis Code for Immigration Policy Attitudes
# This script reads the NSL2018 dataset, recodes key variables, creates a composite 
# measure of anti-immigration attitudes, and then performs descriptive and inferential analyses.
# Modeling includes: separate models for nativity and generation,
# and a combined categorical variable approach.
# -------------------------------

# 0. Logging Setup
sink("new_analysis_log.txt")
message_con_new <- file("new_analysis_messages.txt", open = "wt")
sink(message_con_new, type = "message")

# -------------------------------
# 1. Load Required Packages and Read Dataset
required_packages <- c("survey", "ggplot2", "dplyr", "scales", "broom")
new_packages <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
if (length(new_packages) > 0) install.packages(new_packages)
invisible(lapply(required_packages, library, character.only = TRUE))

# Set working directory and read the dataset
setwd("/Users/azure/Desktop/Coursework/PhD Coursework/1.2 Winter 2025/1.2.5 Survey Analysis--Anti-Immigration Immigrant/Pew-Research-Center_2018-National-Survey-of-Latinos-Dataset 2")
nsl_data <- read.csv("NSL2018_data.csv", stringsAsFactors = FALSE)

# -------------------------------
# 2. Data Preparation

# (a) Recode nativity from qn4: "another country" indicates foreign-born (1), otherwise 0.
nsl_data <- nsl_data %>%
  mutate(foreign_born = ifelse(tolower(trimws(qn4)) == "another country", 1, 0))

# (b) Recode generation status from immgen.
#     "First Gen FB w/o PR"  -> "First Gen"
#     "Second Gen NB"        -> "Second Gen"
#     "Third or more"        -> "Third+ Gen"
#     Other responses (e.g., "NB Gen Unknown") are set to NA.
nsl_data <- nsl_data %>%
  mutate(generation = case_when(
    tolower(trimws(immgen)) == "first gen fb w/o pr" ~ "First Gen",
    tolower(trimws(immgen)) == "second gen nb" ~ "Second Gen",
    tolower(trimws(immgen)) == "third or more" ~ "Third+ Gen",
    TRUE ~ NA_character_
  ))
nsl_data$generation <- factor(nsl_data$generation, levels = c("First Gen", "Second Gen", "Third+ Gen"))

# (c) Recode the three immigration policy indicators:
#     - qn14a: Trump Support (1 if "approve", 0 if "disapprove")
#     - qn29: Border Wall Favorability (1 if "favor", 0 if "oppose")
#     - qn31: Opinion on Immigrant Population (1 if "too many", 0 if "too few" or "right amount")
nsl_data <- nsl_data %>%
  mutate(trump_support_bin = case_when(
    tolower(trimws(qn14a)) == "approve" ~ 1,
    tolower(trimws(qn14a)) == "disapprove" ~ 0,
    TRUE ~ NA_real_
  ),
  favor_wall = case_when(
    tolower(trimws(qn29)) == "favor"  ~ 1,
    tolower(trimws(qn29)) == "oppose" ~ 0,
    TRUE ~ NA_real_
  ),
  too_many_imm = case_when(
    tolower(trimws(qn31)) == "too many" ~ 1,
    tolower(trimws(qn31)) %in% c("too few", "right amount") ~ 0,
    TRUE ~ NA_real_
  ))

# -------------------------------
# 3. Create the Composite Latent Variable

# Sum the three binary indicators to create the composite score (0-3)
nsl_data <- nsl_data %>%
  mutate(immigration_policy = trump_support_bin + favor_wall + too_many_imm,
         immigration_policy_cat = factor(immigration_policy, levels = 0:3, ordered = TRUE))
# Check composite variable summary
summary(nsl_data$immigration_policy)

# -------------------------------
# 4. Descriptive Analyses

# (a) Descriptives for Independent Variables

cat("Descriptive stats for nativity (foreign_born):\n")
print(table(nsl_data$foreign_born, useNA = "ifany"))
cat("\nSummary for foreign_born:\n")
print(summary(nsl_data$foreign_born))

cat("\nDescriptive stats for generation status:\n")
print(table(nsl_data$generation, useNA = "ifany"))
cat("\nSummary for generation:\n")
print(summary(nsl_data$generation))

# (b) Descriptives for the Dependent Variable
cat("\nDescriptive stats for the composite immigration policy variable (immigration_policy):\n")
print(summary(nsl_data$immigration_policy))
cat("\nFrequency table for immigration_policy_cat:\n")
print(table(nsl_data$immigration_policy_cat, useNA = "ifany"))
cat("\nExplanation: The NA values in 'immigration_policy_cat' indicate that for some respondents, one or more of the component indicators (trump_support_bin, favor_wall, or too_many_imm) is missing. As a result, their composite score could not be calculated.\n")

# (c) Mean and SD by Nativity
mean_by_nativity <- nsl_data %>%
  group_by(foreign_born) %>%
  summarise(mean_composite = mean(immigration_policy, na.rm = TRUE),
            sd_composite = sd(immigration_policy, na.rm = TRUE),
            n = n())
cat("\nMean and SD of immigration_policy by foreign_born:\n")
print(mean_by_nativity)

# (d) T-test for group differences (foreign-born vs. U.S.-born)
t_test_result <- t.test(immigration_policy ~ foreign_born, data = nsl_data)
cat("\nT-test result for immigration_policy by foreign_born:\n")
print(t_test_result)

# (e) Cross-tabulation and Chi-square: Foreign-born vs. Immigration Policy Composite
cross_tab <- table(nsl_data$foreign_born, nsl_data$immigration_policy_cat)
cat("\nCross-tabulation: Foreign-born vs. Immigration Policy Composite:\n")
print(cross_tab)
chi_sq_result <- chisq.test(cross_tab)
cat("\nChi-square test result (foreign_born vs. immigration_policy_cat):\n")
print(chi_sq_result)

# (f) Cross-tabulation and Chi-square: Generation vs. Immigration Policy Composite
cross_tab_gen <- table(nsl_data$generation, nsl_data$immigration_policy_cat)
cat("\nCross-tabulation: Generation Status vs. Immigration Policy Composite:\n")
print(cross_tab_gen)
chi_sq_gen <- chisq.test(cross_tab_gen)
cat("\nChi-square test for Generation Status vs. Composite:\n")
print(chi_sq_gen)

# -------------------------------
# 5. Linear Regression Analysis

# A. Separate Models Approach
# Model 1: Immigration Policy ~ Nativity
model_nat <- lm(immigration_policy ~ foreign_born, data = nsl_data)
cat("\nLinear Regression: Immigration Policy ~ Nativity\n")
print(summary(model_nat))

# Model 2: Immigration Policy ~ Generation (U.S.-born only)
nsl_usborn <- subset(nsl_data, foreign_born == 0)
model_gen <- lm(immigration_policy ~ generation, data = nsl_usborn)
cat("\nLinear Regression: Immigration Policy ~ Generation (U.S.-born only)\n")
print(summary(model_gen))

# B. Combined Categorical Variable Approach
nsl_data <- nsl_data %>%
  mutate(nativity_generation = ifelse(foreign_born == 1, 
                                      "Foreign-born (First Gen)", 
                                      as.character(generation)))
nsl_data$nativity_generation <- factor(nsl_data$nativity_generation,
                                       levels = c("Foreign-born (First Gen)", "Second Gen", "Third+ Gen"))
cat("\nDistribution of Combined Nativity/Generation Variable:\n")
print(table(nsl_data$nativity_generation, useNA = "ifany"))
model_combined <- lm(immigration_policy ~ nativity_generation, data = nsl_data)
cat("\nLinear Regression: Immigration Policy ~ Combined Nativity/Generation\n")
print(summary(model_combined))

# -------------------------------
# 6. Visualizations

# 6.1 Bar Chart: Mean Composite Score by Nativity/Generation (with SE)
mean_data <- nsl_data %>%
  group_by(nativity_generation) %>%
  summarise(mean_policy = mean(immigration_policy, na.rm = TRUE),
            se_policy = sd(immigration_policy, na.rm = TRUE) / sqrt(n()),
            n = n())

ggplot(mean_data, aes(x = nativity_generation, y = mean_policy)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  geom_errorbar(aes(ymin = mean_policy - se_policy, ymax = mean_policy + se_policy), width = 0.2) +
  labs(title = "Mean Anti-Immigration Attitude by Nativity/Generation",
       x = "Nativity / Generation",
       y = "Mean Composite Score") +
  theme_minimal()

# 6.2 Stacked Bar Chart: Distribution of Composite Scores by Nativity/Generation
# Calculate percentages in natural order
dist_data <- nsl_data %>%
  filter(!is.na(nativity_generation), !is.na(immigration_policy_cat)) %>%
  group_by(nativity_generation, immigration_policy_cat) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(nativity_generation) %>%
  mutate(
    percentage = count / sum(count) * 100,
    label_pos = cumsum(percentage) - 0.5 * percentage,
    sample_size = sum(count)
  ) %>%
  arrange(nativity_generation, immigration_policy_cat)

# Define palette for ascending order: "0" -> Yellow, "1" -> Green, "2" -> Blue, "3" -> Orange
my_palette <- c(
  "0" = "#F0E442", 
  "1" = "#009E73", 
  "2" = "#56B4E9", 
  "3" = "#E69F00"
)

my_plot <- ggplot(dist_data, aes(x = nativity_generation, y = percentage, fill = immigration_policy_cat)) +
  geom_bar(stat = "identity", width = 0.7, position = "stack") +
  geom_text(
    data = subset(dist_data, percentage > 7),
    aes(label = sprintf("%.1f%%", percentage), y = label_pos),
    color = "black", size = 3.5
  ) +
  scale_fill_manual(
    values = my_palette,
    name = "Anti-Immigration\nAttitude Score",
    labels = c("0 (Low)", "1", "2", "3 (High)")
  ) +
  labs(
    title = "Distribution of Anti-Immigration Attitudes by Nativity/Generation",
    subtitle = "Score=0 is at the bottom, Score=3 is at the top",
    x = NULL,
    y = "Percentage of Respondents",
    caption = "Groups from left to right: Foreign-born (First Gen), Second Gen, Third+ Gen"
  ) +
  scale_y_continuous(limits = c(0, 100), labels = function(x) paste0(x, "%")) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "#636363"),
    plot.caption = element_text(size = 9, color = "#636363", hjust = 0),
    axis.text = element_text(size = 10),
    axis.title.y = element_text(size = 11),
    panel.grid.minor = element_blank()
  ) +
  geom_text(
    aes(y = -5, label = paste0("n=", sample_size)),
    size = 3, color = "#636363"
  )

print(my_plot)

# 6.3 Regression Coefficient Plot for Combined Model
# Tidy model output and remove intercept for clarity
coef_data <- tidy(model_combined)
coef_data <- coef_data[coef_data$term != "(Intercept)", ]
# Clean up term labels for clarity
coef_data$term <- gsub("nativity_generation", "", coef_data$term)

ggplot(coef_data, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#636363") +
  geom_point(size = 3, color = "#3182bd") +
  geom_errorbarh(aes(xmin = estimate - 1.96 * std.error, xmax = estimate + 1.96 * std.error),
                 height = 0.2, color = "#3182bd") +
  labs(
    title = "Effect of Nativity/Generation on Anti-Immigration Attitudes",
    subtitle = "Reference: Foreign-born (First Gen)",
    x = "Regression Coefficient",
    y = "",
    caption = "Error bars represent 95% confidence intervals"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "#636363"),
    plot.caption = element_text(size = 9, color = "#636363"),
    axis.title.x = element_text(size = 11),
    axis.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank()
  )

# -------------------------------
# 7. Exporting Regression Results (Optional)
if("stargazer" %in% installed.packages()[, "Package"]){
  stargazer(model, model_nat, model_gen, model_combined, type = "text", 
            title = "Regression Results: Immigration Policy Composite")
}

# -------------------------------
# 8. Exporting and Closing
sink()           # Close the regular output sink
sink(type = "message")  # Close the message sink
close(message_con_new)


# -------------------------------
# -------------------------------
# -------------------------------

# Appendix: Export Descriptive Statistics Report

# -------------------------------
# Export Descriptive Statistics and Regression Results Report

# Open a sink connection to write output to a text file.
sink("descriptive_regression_report.txt")

cat("Descriptive and Regression Results Report for Immigration Policy Attitudes\n")
cat("==========================================================================\n\n")

# -------------------------------
# 1. Descriptive Statistics

cat("1. Descriptive Statistics\n")
cat("--------------------------\n\n")

# 1a. Nativity (foreign_born)
cat("1a. Nativity (foreign_born)\n")
cat("This variable indicates whether a respondent is foreign-born (1) or U.S.-born (0).\n")
cat("Summary:\n")
print(summary(nsl_data$foreign_born))
cat("\nFrequency Table:\n")
print(table(nsl_data$foreign_born, useNA = "ifany"))
cat("\n\n")

# 1b. Generation Status (generation)
cat("1b. Generation Status (generation)\n")
cat("Categories:\n")
cat(" - First Gen: Respondent is foreign-born.\n")
cat(" - Second Gen: Respondent is U.S.-born with at least one foreign-born parent.\n")
cat(" - Third+ Gen: Respondent is U.S.-born with both parents U.S.-born.\n")
cat("Summary:\n")
print(summary(nsl_data$generation))
cat("\nFrequency Table:\n")
print(table(nsl_data$generation, useNA = "ifany"))
cat("\n\n")

# 1c. Composite Anti-Immigration Attitude (immigration_policy)
cat("1c. Composite Anti-Immigration Attitude (immigration_policy)\n")
cat("This composite score is computed by summing three binary indicators:\n")
cat(" - Trump Support (qn14a): 1 = Approve, 0 = Disapprove\n")
cat(" - Border Wall Favorability (qn29): 1 = Favor, 0 = Oppose\n")
cat(" - Opinion on Immigrant Population (qn31): 1 = 'Too many', 0 = 'Too few' or 'Right amount'\n")
cat("Summary of Composite Score (range: 0-3):\n")
print(summary(nsl_data$immigration_policy))
cat("\nFrequency Table for Composite Score (immigration_policy_cat):\n")
print(table(nsl_data$immigration_policy_cat, useNA = "ifany"))
cat("\nExplanation: NA values in 'immigration_policy_cat' indicate that for some respondents, one or more component indicators (trump_support_bin, favor_wall, or too_many_imm) is missing, so their composite score could not be calculated.\n\n")

# 1d. Mean and SD by Nativity
cat("1d. Mean and Standard Deviation of Composite Score by Nativity\n")
mean_by_nativity <- nsl_data %>%
  group_by(foreign_born) %>%
  summarise(mean_composite = mean(immigration_policy, na.rm = TRUE),
            sd_composite = sd(immigration_policy, na.rm = TRUE),
            n = n())
print(mean_by_nativity)
cat("\n\n")

# 1e. T-test for group differences (Foreign-born vs. U.S.-born)
cat("1e. T-test for Difference in Composite Score (Foreign-born vs. U.S.-born)\n")
t_test_result <- t.test(immigration_policy ~ foreign_born, data = nsl_data)
print(t_test_result)
cat("\n\n")

# 1f. Cross-tabulations and Chi-square Tests
cat("1f. Cross-tabulation: Foreign-born vs. Composite Score\n")
cross_tab <- table(nsl_data$foreign_born, nsl_data$immigration_policy_cat)
print(cross_tab)
cat("\nChi-square Test Result (Foreign-born vs. Composite Score):\n")
chi_sq_result <- chisq.test(cross_tab)
print(chi_sq_result)
cat("\n\n")

cat("Cross-tabulation: Generation vs. Composite Score\n")
cross_tab_gen <- table(nsl_data$generation, nsl_data$immigration_policy_cat)
print(cross_tab_gen)
cat("\nChi-square Test Result (Generation vs. Composite Score):\n")
chi_sq_gen <- chisq.test(cross_tab_gen)
print(chi_sq_gen)
cat("\n\n")

# -------------------------------
# 2. Regression Results

cat("2. Regression Results\n")
cat("-----------------------\n\n")

# A. Separate Models Approach
cat("2a. Model 1: Immigration Policy ~ Nativity\n")
model_nat <- lm(immigration_policy ~ foreign_born, data = nsl_data)
print(summary(model_nat))
cat("\n")

cat("2b. Model 2: Immigration Policy ~ Generation (U.S.-born only)\n")
nsl_usborn <- subset(nsl_data, foreign_born == 0)
model_gen <- lm(immigration_policy ~ generation, data = nsl_usborn)
print(summary(model_gen))
cat("\n")

# B. Combined Categorical Variable Approach
cat("2c. Model 3: Immigration Policy ~ Combined Nativity/Generation\n")
nsl_data <- nsl_data %>%
  mutate(nativity_generation = ifelse(foreign_born == 1, 
                                      "Foreign-born (First Gen)", 
                                      as.character(generation)))
nsl_data$nativity_generation <- factor(nsl_data$nativity_generation,
                                       levels = c("Foreign-born (First Gen)", "Second Gen", "Third+ Gen"))
print("Distribution of Combined Nativity/Generation Variable:")
print(table(nsl_data$nativity_generation, useNA = "ifany"))
model_combined <- lm(immigration_policy ~ nativity_generation, data = nsl_data)
print(summary(model_combined))
cat("\n")

# Optionally, you could also use the broom package to tidy these results further.
# library(broom)
# print(tidy(model_combined))

# -------------------------------
# Close the sink
sink()






