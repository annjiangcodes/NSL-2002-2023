
## Research Question: How many hispanic immigrants shows anti-immigration indicators out of all hispanics in the United States?

# 0. Upload and transform the dataset into csv format
library(foreign)
data <- read.spss("/Users/azure/Desktop/Coursework/PhD Coursework/Survey Analysis--Anti-Immigration Immigrant/Pew-Research-Center_2018-National-Survey-of-Latinos-Dataset 2/NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav", to.data.frame=TRUE)
write.csv(data, "/Users/azure/Desktop/NSL2018_data.csv", row.names = FALSE)

# Load required packages
library(dplyr)
install.packages("survey")
library(survey)

# 1. Data Preparation and Weighting
# Read in the CSV file 
setwd("/Users/azure/Desktop/Coursework/PhD Coursework/Survey Analysis--Anti-Immigration Immigrant/Pew-Research-Center_2018-National-Survey-of-Latinos-Dataset 2")
nsl_data <- read.csv("NSL2018_data.csv", stringsAsFactors = FALSE)

# Inspect the dataset
str(nsl_data)
summary(nsl_data)

# Verify that the weight variable exists.
head(nsl_data$weight)

# 2. Isolating the Foreign-Born Subsample
# Q4 responses are documented as words: "U.S.", "Puerto Rico", or "foreign country".
# We create a binary variable: foreign_born = 1 if Q4 is "foreign country", 0 otherwise.
names(nsl_data)
unique_values <- unique(tolower(trimws(nsl_data$qn4)))
print(unique_values)

nsl_data <- nsl_data %>%
  mutate(foreign_born = ifelse(tolower(trimws(qn4)) == "another country", 1, 0))

# Verify the frequency for foreign-born respondents
table(nsl_data$foreign_born)

# 3. Defining Outcome Variables Using the Documented Coding

# (a) Trump Support (Q14A)
# Documented responses: "Approve", "Disapprove", "Don't know", "Refused"
# We'll code "Approve" as 1 and "Disapprove" as 0; others become NA.
nsl_data <- nsl_data %>%
  mutate(trump_support = case_when(
    tolower(trimws(qn14a)) == "approve"    ~ 1,
    tolower(trimws(qn14a)) == "disapprove" ~ 0,
    TRUE ~ NA_real_
  ))

# Verify 
table(nsl_data$trump_support)

# (b) Border Wall Opinion (Q29)
# Documented responses: "Favor", "Oppose", "Don't know", "Refused"
nsl_data <- nsl_data %>%
  mutate(favor_wall = case_when(
    tolower(trimws(qn29)) == "favor"  ~ 1,
    tolower(trimws(qn29)) == "oppose" ~ 0,
    TRUE ~ NA_real_
  ))

# Verify 
table(nsl_data$favor_wall)

# (c) Opinion on Immigrant Population (Q31)
# Documented responses: "Too many", "Too few", "Right amount", plus "Don't know"/"Refused".
# We code "Too many" as 1 (anti-immigration) and "Too few" or "Right amount" as 0.
nsl_data <- nsl_data %>%
  mutate(too_many_imm = case_when(
    tolower(trimws(qn31)) == "too many" ~ 1,
    tolower(trimws(qn31)) %in% c("too few", "right amount") ~ 0,
    TRUE ~ NA_real_
  ))

# Verify 
table(nsl_data$too_many_imm)

# (d) Conservative Orientation – Party Identification (PARTY)
# Documented responses: e.g., "Republican", "Democrat", "Independent", etc.
# We'll code "Republican" as 1 (conservative) and others ("Democrat", "Independent", etc.) as 0.
nsl_data <- nsl_data %>%
  mutate(conservative = case_when(
    tolower(trimws(party)) == "republican" ~ 1,
    tolower(trimws(party)) %in% c("democrat", "independent") ~ 0,
    TRUE ~ NA_real_
  ))

# Verify 
table(nsl_data$conservative)

# (e) Composite Indicator (Optional)
# Flag a respondent as "conservative/anti-immigration/trump supporting/too many immigrants" if at least one of the following is true:
#   - Approves of Trump (trump_support == 1)
#   - Favors the border wall (favor_wall == 1)
#   - Believes there are too many immigrants (too_many_imm == 1)
#   - Identifies as Republican (conservative == 1)
nsl_data <- nsl_data %>%
  mutate(cons_antiimm = ifelse(trump_support == 1 | favor_wall == 1 | too_many_imm == 1 | conservative == 1, 1, 0))

# Verify 
table(nsl_data$cons_antiimm)

# 4. Survey Design Setup
# Create a survey design object using the weight variable.[not sure how weighting works]
nsl_design <- svydesign(ids = ~1, data = nsl_data, weights = ~weight)

# Subset the design to foreign-born respondents only
foreign_design <- subset(nsl_design, foreign_born == 1)

# 5a. Descriptive Analysis: Calculate weighted proportions
trump_prop    <- svymean(~trump_support, design = foreign_design, na.rm = TRUE)
wall_prop     <- svymean(~favor_wall, design = foreign_design, na.rm = TRUE)
imm_prop      <- svymean(~too_many_imm, design = foreign_design, na.rm = TRUE)
party_prop    <- svymean(~conservative, design = foreign_design, na.rm = TRUE)
composite_prop<- svymean(~cons_antiimm, design = foreign_design, na.rm = TRUE)

# Print the weighted proportions
print(trump_prop)
print(wall_prop)
print(imm_prop)
print(party_prop)
print(composite_prop)

# 5b.1 Cross-Tabulations
# Example: Cross-tabulate Trump support by Party Identification
table_trump_party <- svytable(~trump_support + party, design = foreign_design)
print(table_trump_party)

# 5b.2 Cross-tabulate border wall opinion and immigrant population opinion
table_wall_imm <- svytable(~favor_wall + too_many_imm, design = foreign_design)
print(table_wall_imm)

# 5b.3 Cross-tabulations for the full sample using the survey design (nsl_design)

# 5b.3.1. Foreign Born vs. Trump Support (qn14a)
table_foreign_trump <- svytable(~ foreign_born + trump_support, design = nsl_design)
print("Cross-tabulation: Foreign Born vs. Trump Support")
print(table_foreign_trump)

# 5b.3.2. Foreign Born vs. Favor Wall (qn29)
table_foreign_wall <- svytable(~ foreign_born + favor_wall, design = nsl_design)
print("Cross-tabulation: Foreign Born vs. Favor Wall")
print(table_foreign_wall)

# 5b.3.3. Foreign Born vs. Too Many Immigrants (qn31)
table_foreign_imm <- svytable(~ foreign_born + too_many_imm, design = nsl_design)
print("Cross-tabulation: Foreign Born vs. Too Many Immigrants")
print(table_foreign_imm)

# 5b.3.4. Foreign Born vs. Conservative Orientation (party)
table_foreign_party <- svytable(~ foreign_born + conservative, design = nsl_design)
print("Cross-tabulation: Foreign Born vs. Conservative (Republican Identification)")
print(table_foreign_party)

# 5b.3.5. Foreign Born vs. Composite Conservative/Anti-Immigration Indicator
table_foreign_composite <- svytable(~ foreign_born + cons_antiimm, design = nsl_design)
print("Cross-tabulation: Foreign Born vs. Composite Conservative/Anti-Immigration Indicator")
print(table_foreign_composite)




# 5c. Inferential Analysis
# Chi-square test between Trump support and conservative orientation
chi_test <- svychisq(~trump_support + conservative, design = foreign_design)
print(chi_test)

# Logistic regression: Outcome = Trump support; predictors include conservative orientation,
# controlling for sociodemographic variables (assuming variables AGE and EDUC exist).
model <- svyglm(trump_support ~ conservative + age + educ, 
                design = foreign_design, family = quasibinomial())
summary(model)

# Logistic regression for the composite indicator (optional)
model_comp <- svyglm(cons_antiimm ~ conservative + age + educ, 
                     design = foreign_design, family = quasibinomial())
summary(model_comp)

# 6. Exporting Results
# Create a data frame of descriptive weighted proportions
descriptives <- data.frame(
  Variable = c("Trump Support", "Favor Wall", "Too Many Immigrants", 
               "Republican Identification", "Composite Conservative/Anti-Immigration"),
  Proportion = c(coef(trump_prop), coef(wall_prop), coef(imm_prop), 
                 coef(party_prop), coef(composite_prop))
)

# Save the results to a CSV file
write.csv(descriptives, "foreign_born_descriptives.csv", row.names = FALSE)