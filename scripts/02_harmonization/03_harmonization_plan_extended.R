# ==============================================================================
# Extended Harmonization Plan for 2002-2007 Survey Data
# ==============================================================================

# Load required libraries
library(dplyr)
library(stringr)
library(readr)
library(tidyr)

# Function to determine if a variable needs manual review
needs_manual_review <- function(raw_name, label, concept) {
  
  # Handle missing labels
  if (is.na(label) || is.null(label) || label == "") {
    return("YES - Missing label")
  }
  
  # Variables that definitely need manual review
  manual_review_patterns <- c(
    # Complex attitude scales
    "scale", "index", "composite",
    # Open-ended responses  
    "other", "specify", "text",
    # Multi-part questions
    "part", "section", 
    # Complex policy questions
    "proposal", "policy", "legislation",
    # Ambiguous labels
    "unclear", "ambiguous", "complex"
  )
  
  # Check label complexity
  if (nchar(label) > 100) return("YES - Long/complex label")
  if (str_detect(str_to_lower(label), paste(manual_review_patterns, collapse = "|"))) {
    return("YES - Complex question type")
  }
  
  # Variables that are clearly about multiple topics
  if (str_count(str_to_lower(label), "\\?") > 1) return("YES - Multiple questions")
  
  # Age variables with unusual patterns
  if (concept == "age" && !str_detect(str_to_lower(raw_name), "age|birth|born|year")) {
    return("YES - Indirect age measure")
  }
  
  # Variables with unusual naming patterns
  if (concept %in% c("citizenship_status", "nativity", "place_birth", "immigrant_generation") &&
      str_detect(str_to_lower(raw_name), "qn[0-9]+[a-z]")) {
    return("YES - Sub-question may need verification")
  }
  
  return("NO")
}

# Function to suggest harmonized variable names and coding
suggest_harmonization <- function(concept, raw_name, label) {
  
  harmonizations <- list(
    # Core demographics
    gender = list(
      harmonized_name = "gender",
      values_recode = "1=Male, 2=Female, 3=Other/Non-binary",
      notes = "Standard binary/ternary gender coding"
    ),
    
    age = list(
      harmonized_name = "age",
      values_recode = "Continuous variable (years)",
      notes = "Age in years at time of survey"
    ),
    
    # Nativity and Immigration
    nativity = list(
      harmonized_name = "nativity", 
      values_recode = "1=US born, 2=Foreign born",
      notes = "Binary nativity status"
    ),
    
    place_birth = list(
      harmonized_name = "place_birth",
      values_recode = "1=US born, 2=Foreign born",
      notes = "Place of birth (binary or country codes)"
    ),
    
    citizenship_status = list(
      harmonized_name = "citizenship_status",
      values_recode = "1=US Citizen, 2=Permanent Resident, 3=Other/Non-citizen",
      notes = "Citizenship/legal status"
    ),
    
    immigrant_generation = list(
      harmonized_name = "immigrant_generation",
      values_recode = "1=First generation, 2=Second generation, 3=Third+ generation",
      notes = "Derived from respondent and parent nativity"
    ),
    
    parents_immigrant = list(
      harmonized_name = "parent_nativity",
      values_recode = "1=Both US born, 2=One foreign born, 3=Both foreign born",
      notes = "Combined mother and father nativity"
    ),
    
    # Ethnicity and race
    ethnicity_race = list(
      harmonized_name = "hispanic_origin",
      values_recode = "1=Mexican, 2=Puerto Rican, 3=Cuban, 4=Other Hispanic, 5=Non-Hispanic",
      notes = "Hispanic origin/ethnicity categories"
    ),
    
    # Language
    language = list(
      harmonized_name = "language_home",
      values_recode = "1=English only, 2=Spanish only, 3=Both English and Spanish, 4=Other",
      notes = "Primary language spoken at home"
    ),
    
    # Political variables
    political_party = list(
      harmonized_name = "political_party",
      values_recode = "1=Democrat, 2=Republican, 3=Independent, 4=Other/No preference",
      notes = "Political party identification"
    ),
    
    political_attitudes = list(
      harmonized_name = "political_attitudes",
      values_recode = "Variable-specific - see codebook",
      notes = "Political attitude scales - needs manual review per variable"
    ),
    
    vote_intention = list(
      harmonized_name = "vote_intention", 
      values_recode = "1=Yes/Definitely, 2=Probably, 3=Probably not, 4=No/Definitely not",
      notes = "Likelihood of voting"
    ),
    
    # Immigration attitudes
    immigration_attitudes = list(
      harmonized_name = "immigration_attitude",
      values_recode = "1=Pro-immigration, 2=Neutral, 3=Anti-immigration",
      notes = "General immigration attitude scale"
    ),
    
    policy_preferences = list(
      harmonized_name = "policy_preference",
      values_recode = "1=Support, 0=Oppose",
      notes = "Support for specific immigration policies"
    ),
    
    undocumented_contact = list(
      harmonized_name = "undocumented_contact",
      values_recode = "1=Yes, 0=No",
      notes = "Contact with undocumented immigrants"
    ),
    
    # Socioeconomic
    education = list(
      harmonized_name = "education",
      values_recode = "1=<HS, 2=HS, 3=Some college, 4=College+",
      notes = "Educational attainment categories"
    ),
    
    income = list(
      harmonized_name = "household_income",
      values_recode = "Categorical income brackets - see codebook", 
      notes = "Household income categories"
    ),
    
    employment = list(
      harmonized_name = "employment_status",
      values_recode = "1=Employed, 2=Unemployed, 3=Not in labor force",
      notes = "Employment status"
    ),
    
    # Geographic
    geography = list(
      harmonized_name = "geography",
      values_recode = "State/region codes",
      notes = "Geographic location indicators"
    ),
    
    # Religion and cultural
    religion = list(
      harmonized_name = "religion",
      values_recode = "1=Catholic, 2=Protestant, 3=Other Christian, 4=Other, 5=None",
      notes = "Religious affiliation"
    ),
    
    # Household
    marital_status = list(
      harmonized_name = "marital_status",
      values_recode = "1=Married, 2=Single, 3=Divorced/Separated, 4=Widowed",
      notes = "Marital status categories"
    ),
    
    household = list(
      harmonized_name = "household_size",
      values_recode = "Continuous variable (number of people)",
      notes = "Number of people in household"
    )
  )
  
  if (concept %in% names(harmonizations)) {
    return(harmonizations[[concept]])
  } else {
    return(list(
      harmonized_name = concept,
      values_recode = "Needs manual review",
      notes = paste("No standard harmonization for concept:", concept)
    ))
  }
}

# Main harmonization planning function
create_harmonization_plan_extended <- function(matched_vars_file = "matched_variables_by_concept_2002_2007.csv",
                                              focus_years = c(2002, 2004, 2006, 2007)) {
  
  cat("=== Creating Extended Harmonization Plan for 2002-2007 ===\n\n")
  
  # Read matched variables
  if (!file.exists(matched_vars_file)) {
    stop("Matched variables file not found: ", matched_vars_file)
  }
  
  matched_vars <- read_csv(matched_vars_file, show_col_types = FALSE)
  cat("Loaded", nrow(matched_vars), "matched variables\n")
  
  # Filter to focus years
  if (!is.null(focus_years)) {
    matched_vars <- matched_vars %>%
      filter(year %in% focus_years)
    cat("Filtered to", nrow(matched_vars), "variables for years:", paste(focus_years, collapse = ", "), "\n")
  }
  
  if (nrow(matched_vars) == 0) {
    stop("No variables found for the specified years")
  }
  
  # Remove duplicates and keep one concept per variable (prioritize key concepts)
  concept_priority <- c("citizenship_status", "nativity", "place_birth", "immigrant_generation", 
                       "parents_immigrant", "gender", "age", "ethnicity_race", "language",
                       "political_party", "immigration_attitudes", "vote_intention")
  
  unique_vars <- matched_vars %>%
    arrange(year, raw_variable_name, match(concept, concept_priority, nomatch = 999)) %>%
    group_by(year, raw_variable_name) %>%
    slice(1) %>%
    ungroup()
  
  cat("After removing duplicates:", nrow(unique_vars), "unique variables\n\n")
  
  # Create harmonization plan
  harmonization_plan <- unique_vars %>%
    rowwise() %>%
    mutate(
      harmonization = list(suggest_harmonization(concept, raw_variable_name, label)),
      harmonized_name = harmonization$harmonized_name,
      values_recode = harmonization$values_recode,
      harmonization_notes = harmonization$notes,
      manual_review_needed = needs_manual_review(raw_variable_name, label, concept),
      original_label = str_trunc(label, 200, "right")
    ) %>%
    select(year, raw_name = raw_variable_name, concept, harmonized_name, 
           values_recode, manual_review_needed, harmonization_notes, original_label) %>%
    arrange(year, concept, raw_name)
  
  cat("Generated harmonization plan with", nrow(harmonization_plan), "mappings\n")
  
  # Summary statistics
  cat("\n=== Harmonization Plan Summary ===\n")
  
  # Variables by year
  year_summary <- harmonization_plan %>%
    group_by(year) %>%
    summarise(n_variables = n(), .groups = "drop")
  cat("Variables by year:\n")
  print(year_summary)
  
  # Variables by concept
  concept_summary <- harmonization_plan %>%
    group_by(concept) %>%
    summarise(n_variables = n(), .groups = "drop") %>%
    arrange(desc(n_variables))
  cat("\nVariables by concept:\n")
  print(head(concept_summary, 15))
  
  # Manual review needed
  manual_review_summary <- harmonization_plan %>%
    group_by(manual_review_needed) %>%
    summarise(n_variables = n(), .groups = "drop")
  cat("\nManual review summary:\n")
  print(manual_review_summary)
  
  # Core concepts availability by year
  core_concepts <- c("gender", "age", "citizenship_status", "nativity", "place_birth", 
                    "immigrant_generation", "ethnicity_race", "language", "political_party")
  
  core_summary <- harmonization_plan %>%
    filter(concept %in% core_concepts) %>%
    group_by(year, concept) %>%
    summarise(n_variables = n(), .groups = "drop") %>%
    pivot_wider(names_from = year, values_from = n_variables, values_fill = 0) %>%
    arrange(concept)
  
  cat("\nCore concepts by year:\n")
  print(core_summary)
  
  # Save harmonization plan
  output_file <- "harmonization_plan_extended_2002_2007.csv"
  write_csv(harmonization_plan, output_file)
  cat("\nSaved harmonization plan:", output_file, "\n")
  
  # Save review template
  review_template <- harmonization_plan %>%
    filter(manual_review_needed != "NO") %>%
    select(year, raw_name, concept, harmonized_name, manual_review_needed, original_label) %>%
    mutate(
      review_status = "PENDING",
      reviewer_notes = "",
      final_harmonized_name = harmonized_name,
      final_values_recode = ""
    )
  
  review_file <- "harmonization_review_template_2002_2007.csv"
  write_csv(review_template, review_file)
  cat("Saved review template:", review_file, "\n")
  
  return(harmonization_plan)
}

# Run the harmonization planning
if (!interactive()) {
  harmonization_plan <- create_harmonization_plan_extended()
}