# -------------------------------
# Revised Analysis Code for Immigration Policy Attitudes
# This script reads the NSL2018 dataset, recodes key variables, creates a composite
# measure of anti-immigration attitudes, and then performs descriptive and inferential analyses.
# Modeling includes: a multivariate regression, separate models for nativity and generation,
# and a combined categorical variable approach.

# Start logging
sink("new_analysis_log.txt")
message_con_new <- file("new_analysis_messages.txt", open = "wt")
sink(message_con_new, type = "message")

# -------------------------------
# Load Required Packages
required_packages <- c("survey", "ggplot2", "dplyr", "scales")
new_packages <- required_packages[!required_packages %in% installed.packages()[, "Package"]]
if (length(new_packages) > 0) install.packages(new_packages)
invisible(lapply(required_packages, library, character.only = TRUE))

# -------------------------------
# Set Working Directory and Read the Dataset
setwd("/Users/azure/Desktop/Coursework/PhD Coursework/1.2 Winter 2025/1.2.5 Survey Analysis--Anti-Immigration Immigrant/Pew-Research-Center_2018-National-Survey-of-Latinos-Dataset 2")
nsl_data <- read.csv("NSL2018_data.csv", stringsAsFactors = FALSE)

# -------------------------------
# 1. Data Preparation

# (a) Recode nativity from qn4: "another country" indicates foreign-born (1), otherwise 0.
nsl_data <- nsl_data %>%
  mutate(foreign_born = ifelse(tolower(trimws(qn4)) == "another country", 1, 0))

# (b) Recode generation status from immgen.
#   "First Gen FB w/o PR"  -> "First Gen"
#   "Second Gen NB"        -> "Second Gen"
#   "Third or more"        -> "Third+ Gen"
#   All other responses (e.g., "NB Gen Unknown") become NA.
nsl_data <- nsl_data %>%
  mutate(generation = case_when(
    tolower(trimws(immgen)) == "first gen fb w/o pr" ~ "First Gen",
    tolower(trimws(immgen)) == "second gen nb" ~ "Second Gen",
    tolower(trimws(immgen)) == "third or more" ~ "Third+ Gen",
    TRUE ~ NA_character_
  ))
nsl_data$generation <- factor(nsl_data$generation, levels = c("First Gen", "Second Gen", "Third+ Gen"))

# (c) Recode the three immigration policy indicators:
#   - qn14a: Trump Support (1 if "approve", 0 if "disapprove")
#   - qn29: Border Wall Favorability (1 if "favor", 0 if "oppose")
#   - qn31: Opinion on Immigrant Population (1 if "too many", 0 if "too few" or "right amount")
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
# 2. Create the Composite Latent Variable

# Sum the three binary indicators to create the composite score (0-3)
nsl_data <- nsl_data %>%
  mutate(immigration_policy = trump_support_bin + favor_wall + too_many_imm,
         immigration_policy_cat = factor(immigration_policy, levels = 0:3, ordered = TRUE))

# Check the composite variable
summary(nsl_data$immigration_policy)

# -------------------------------
# 3. Descriptive Analyses

# (a) Descriptives for Independent Variables

# Nativity (foreign_born)
cat("Descriptive stats for nativity (foreign_born):\n")
print(table(nsl_data$foreign_born, useNA = "ifany"))
cat("\nSummary for foreign_born:\n")
print(summary(nsl_data$foreign_born))

# Generation status
cat("\nDescriptive stats for generation status:\n")
print(table(nsl_data$generation, useNA = "ifany"))
cat("\nSummary for generation:\n")
print(summary(nsl_data$generation))

# (b) Descriptives for the Dependent Variable (immigration_policy)
cat("\nDescriptive stats for the composite immigration policy variable (immigration_policy):\n")
print(summary(nsl_data$immigration_policy))
cat("\nFrequency table for immigration_policy_cat:\n")
print(table(nsl_data$immigration_policy_cat, useNA = "ifany"))
#This typically happens when one or more of the three component indicators (trump_support_bin, favor_wall, or too_many_imm) is NA, so their sum cannot be computed.
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
# 4. Linear Regression Analysis


# A. Separate Models Approach
# Model 1: Using only nativity (foreign_born)
model_nat <- lm(immigration_policy ~ foreign_born, data = nsl_data)
cat("\nLinear Regression: Immigration Policy ~ Nativity\n")
print(summary(model_nat))

# Model 2: Using only generation (for U.S.-born respondents)
nsl_usborn <- subset(nsl_data, foreign_born == 0)
model_gen <- lm(immigration_policy ~ generation, data = nsl_usborn)
cat("\nLinear Regression: Immigration Policy ~ Generation (U.S.-born only)\n")
print(summary(model_gen))

# B. Combined Categorical Variable Approach
# Create 'nativity_generation': For foreign-born, assign "Foreign-born (First Gen)";
# otherwise, use the 'generation' variable.
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
# 5. Visualization



# 5.1 Bar Chart: Mean Composite Score by Nativity/Generation with Standard Error
mean_data <- nsl_data %>%
  group_by(nativity_generation) %>%
  summarise(mean_policy = mean(immigration_policy, na.rm = TRUE),
            se_policy = sd(immigration_policy, na.rm = TRUE) / sqrt(n()))

ggplot(mean_data, aes(x = nativity_generation, y = mean_policy)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  geom_errorbar(aes(ymin = mean_policy - se_policy, ymax = mean_policy + se_policy), width = 0.2) +
  labs(title = "Mean Anti-Immigration Attitude by Nativity/Generation",
       x = "Nativity / Generation",
       y = "Mean Composite Score") +
  theme_minimal()

# Improved Visualizations for Immigration Policy Analysis


# 1. Clear, focused bar chart showing mean composite scores with confidence intervals
# This consolidates information in a single accessible visualization

mean_data <- nsl_data %>%
  group_by(nativity_generation) %>%
  summarise(
    mean_policy = mean(immigration_policy, na.rm = TRUE),
    ci_lower = mean_policy - qt(0.975, sum(!is.na(immigration_policy))-1) * 
      (sd(immigration_policy, na.rm = TRUE) / sqrt(sum(!is.na(immigration_policy)))),
    ci_upper = mean_policy + qt(0.975, sum(!is.na(immigration_policy))-1) * 
      (sd(immigration_policy, na.rm = TRUE) / sqrt(sum(!is.na(immigration_policy)))),
    n = sum(!is.na(immigration_policy))
  )

# Create bar chart with proper labels and accessible colors
ggplot(mean_data, aes(x = nativity_generation, y = mean_policy)) +
  geom_bar(stat = "identity", fill = "#3182bd", alpha = 0.8) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.2, color = "#252525") +
  labs(
    title = "Anti-Immigration Attitudes by Nativity/Generation",
    subtitle = "Higher scores indicate stronger anti-immigration attitudes (scale: 0-3)",
    x = "",  # Label provided in caption instead
    y = "Mean Composite Score",
    caption = "Nativity/Generation categories from left to right: Foreign-born (First Gen), Second Generation, Third+ Generation\nError bars represent 95% confidence intervals"
  ) +
  scale_y_continuous(limits = c(0, 3), breaks = seq(0, 3, 0.5)) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "#636363"),
    plot.caption = element_text(size = 9, color = "#636363", hjust = 0),
    axis.title.y = element_text(size = 11),
    axis.text = element_text(size = 10),
    panel.grid.minor = element_blank()
  )

# 2. Stacked bar chart showing distribution of composite scores with clear patterns
# Using a colorblind-friendly palette and clearer labels

# Calculate percentages
dist_data <- nsl_data %>%
  filter(!is.na(nativity_generation), !is.na(immigration_policy_cat)) %>%
  group_by(nativity_generation, immigration_policy_cat) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(nativity_generation) %>%
  mutate(
    percentage = count / sum(count) * 100,
    label_pos = cumsum(percentage) - 0.5 * percentage,
    sample_size = sum(count)
  )

# Create a colorblind-friendly palette
cb_palette <- c("#E69F00", "#56B4E9", "#009E73", "#F0E442")

# Create stacked bar chart with value labels
ggplot(dist_data, aes(x = nativity_generation, y = percentage, fill = immigration_policy_cat)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_text(
    aes(y = label_pos, label = sprintf("%.1f%%", percentage)),
    color = "black", size = 3.5, 
    # Only show labels for segments with enough space
    data = subset(dist_data, percentage > 7)
  ) +
  scale_fill_manual(
    values = cb_palette,
    name = "Anti-Immigration\nAttitude Score",
    labels = c("0 (Low)", "1", "2", "3 (High)")
  ) +
  labs(
    title = "Distribution of Anti-Immigration Attitudes by Nativity/Generation",
    subtitle = "Higher scores indicate stronger anti-immigration attitudes",
    x = "",
    y = "Percentage of Respondents",
    caption = "Values less than 7% not labeled. Nativity/Generation from left to right: Foreign-born (First Gen), Second Generation, Third+ Generation"
  ) +
  scale_y_continuous(limits = c(0, 100), labels = function(x) paste0(x, "%")) +
  theme_minimal() +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "#636363"),
    plot.caption = element_text(size = 9, color = "#636363", hjust = 0),
    axis.title.y = element_text(size = 11),
    axis.text = element_text(size = 10),
    panel.grid.minor = element_blank()
  ) +
  # Add sample size information below each bar
  geom_text(
    aes(y = -5, label = paste0("n = ", sample_size)),
    size = 3, color = "#636363"
  )
#-----------
library(dplyr)
library(ggplot2)

# 1. Ensure your factor levels are 0 < 1 < 2 < 3
nsl_data$immigration_policy_cat <- factor(
  nsl_data$immigration_policy_cat,
  levels = c("0", "1", "2", "3"),  # ascending
  ordered = TRUE
)

# 2. Calculate percentages with original ordering
dist_data <- nsl_data %>%
  filter(!is.na(nativity_generation), !is.na(immigration_policy_cat)) %>%
  group_by(nativity_generation, immigration_policy_cat) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(nativity_generation) %>%
  mutate(
    percentage = count / sum(count) * 100,
    sample_size = sum(count)
  )

# 3. Sort so that 0 is first, then 1, then 2, then 3
#    This ensures the bar is stacked from 0 at the bottom to 3 at the top.
plot_data <- dist_data %>%
  arrange(nativity_generation, immigration_policy_cat) %>%
  group_by(nativity_generation) %>%
  mutate(
    # For label placement if desired
    ypos_bottom = lag(cumsum(percentage), default = 0),
    ypos = ypos_bottom + (percentage / 2)
  )

# 4. Define a palette in the same ascending order: "0","1","2","3"
#    So that "0" is the first color, "3" is the last
my_palette <- c(
  "0" = "#F0E442",  # Yellow for 0
  "1" = "#009E73",  # Green for 1
  "2" = "#56B4E9",  # Blue for 2
  "3" = "#E69F00"   # Orange for 3
)

# 5. Build the stacked bar chart
my_plot <- ggplot(plot_data, aes(x = nativity_generation, y = percentage, fill = immigration_policy_cat)) +
  # No reverse stacking; "0" is drawn first => bottom
  geom_bar(stat = "identity", width = 0.7, position = "stack") +
  
  # (A) Percentage labels on segments >7% to avoid clutter
  geom_text(
    data = subset(plot_data, percentage > 7),
    aes(label = sprintf("%.1f%%", percentage), y = ypos),
    color = "black", size = 3.5
  ) +
  
  # (B) Use the color mapping for 0->yellow, 1->green, 2->blue, 3->orange
  scale_fill_manual(
    values = my_palette,
    name = "Anti-Immigration\nAttitude Score",
    labels = c("0 (Low)", "1", "2", "3 (High)")
  ) +
  
  labs(
    title = "Distribution of Anti-Immigration Attitudes by Nativity/Generation",
    subtitle = "Higher scores indicate stronger anti-immigration attitudes",
    x = NULL,
    y = "Percentage of Respondents",
    caption = "Values < 7% not labeled.\nGroups from left to right: Foreign-born (First Gen), Second Gen, Third+ Gen"
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
  
  # (C) Sample size below each bar
  geom_text(
    aes(y = -5, label = paste0("n=", sample_size)),
    size = 3, color = "#636363"
  )

print(my_plot)



# -------------------------------
# 4. Create the Stacked Bar Chart with Reversed Stacking for Plotting Only
my_plot <- ggplot(plot_data, aes(x = nativity_generation, y = percentage, fill = immigration_policy_cat_reversed)) + 
  geom_bar(stat = "identity", width = 0.7) + 
  geom_text(
    aes(y = ypos, label = sprintf("%.1f%%", percentage)),
    color = "black", size = 3.5,
    data = subset(plot_data, percentage > 7)
  ) + 
  scale_fill_manual(
    values = cb_palette,
    name = "Anti-Immigration\nAttitude Score",
    labels = c("3 (High)", "2", "1", "0 (Low)")
  ) + 
  labs(
    title = "Distribution of Anti-Immigration Attitudes by Nativity/Generation",
    subtitle = "Higher scores indicate stronger anti-immigration attitudes",
    x = "",
    y = "Percentage of Respondents",
    caption = "Values less than 7% not labeled.\nNativity/Generation from left to right: Foreign-born (First Gen), Second Gen, Third+ Gen"
  ) + 
  scale_y_continuous(limits = c(0, 100), labels = function(x) paste0(x, "%")) + 
  theme_minimal() + 
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "#636363"),
    plot.caption = element_text(size = 9, color = "#636363", hjust = 0),
    axis.title.y = element_text(size = 11),
    axis.text = element_text(size = 10),
    panel.grid.minor = element_blank()
  ) + 
  geom_text(
    aes(y = -5, label = paste0("n = ", sample_size)),
    size = 3, color = "#636363"
  )

# Print the plot
print(my_plot)


#--------
# 3. Regression coefficient plot - clear visualization of model results
# This properly displays the model findings with uncertainty

if(!"broom" %in% installed.packages()[, "Package"]) install.packages("broom")
library(broom)

# Tidy the model output
coef_data <- tidy(model_combined)
# Remove intercept for clearer visualization
coef_data <- coef_data[coef_data$term != "(Intercept)",]

# Rename the terms for clarity
coef_data$term <- gsub("nativity_generation", "", coef_data$term)

ggplot(coef_data, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "#636363") +
  geom_point(size = 3, color = "#3182bd") +
  geom_errorbarh(
    aes(xmin = estimate - 1.96 * std.error, xmax = estimate + 1.96 * std.error), 
    height = 0.2, color = "#3182bd"
  ) +
  labs(
    title = "Effect of Nativity/Generation on Anti-Immigration Attitudes",
    subtitle = "Reference category: Foreign-born (First Generation)",
    x = "Effect Size (Regression Coefficient)",
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
# 6. Exporting and Closing

# Optionally, export regression results using stargazer (if installed)
if("stargazer" %in% installed.packages()[,"Package"]){
  stargazer(model, model_nat, model_gen, model_combined, type = "text", 
            title = "Regression Results: Immigration Policy Composite")
}

# Close sinks
sink()           # Close the regular output sink
sink(type = "message")  # Close the message sink
close(message_con_new)

