# -------------------------------
# Start logging

# For regular output
sink("basic_analysis_log.txt")

# For messages and warnings
message_con <- file("basic_analysis_messages.txt", open = "wt")
sink(message_con, type = "message")

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

# (a) DACA support (qn14a) ASK ALL 28. As you may know, many immigrants who came illegally to the U.S. when they were children now have temporary legal status that may be ending. Would you favor or oppose Congress passing a law granting them permanent legal status? 1 Favor 2 Oppose D (DO NOT READ) Don’t know R (DO NOT READ) Refused


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



# (e) Composite Indicator: transform the above three variables by summing it into a [0-3] composite indicator
nsl_data <- nsl_data %>%


# -------------------------------
# 4. Survey Design Setup
nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)
# Create a design for foreign-born respondents only
foreign_design <- subset(nsl_design, foreign_born == 1)
#create a design for second gen v.s. third gen or above
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
write.csv(descriptives, "foreign_born_descriptives.csv", row.names = FALSE)

# Save the data for the advanced analysis
save(nsl_data, nsl_design, foreign_design, file = "nsl_prepared_data.RData")

# Close sinks
sink() # Close the regular output sink
sink(type = "message") # Close the message sink
close(message_con) # Close the connection
