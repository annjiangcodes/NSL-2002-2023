# ==============================================================================
# Extended Keyword Search for 2002-2007 Survey Variables
# ==============================================================================

# Load required libraries
library(dplyr)
library(stringr)
library(readr)
library(tidyr)

# Define comprehensive keywords for each concept
expanded_keyword_patterns <- list(
  # Demographics
  gender = c("gender", "sex", "male", "female", "woman", "man", "respondent.*sex"),
  
  age = c("age", "birth", "born", "year.*born", "how old", "birthday", "birthdate"),
  
  # Nativity and Immigration Status
  nativity = c("nativity", "born in u\\.?s", "born in united states", "born in america", 
               "place of birth", "country of birth", "where.*born", "native born",
               "forborn", "foreign.*born", "us.*born", "american.*born"),
  
  place_birth = c("place.*birth", "country.*birth", "born.*country", "birth.*place",
                  "where.*you.*born", "what.*country.*born", "born.*outside",
                  "born.*us", "born.*america", "born.*united.*states"),
  
  immigrant_generation = c("generation", "generational", "first generation", "second generation", 
                          "1st generation", "2nd generation", "third generation", "3rd generation",
                          "gen1", "gen2", "gen3", "immigrant.*generation"),
  
  parents_immigrant = c("parent.*born", "mother.*born", "father.*born", "parents.*country",
                       "mother.*country", "father.*country", "parent.*immigrant", 
                       "mother.*immigrant", "father.*immigrant", "mothernat", "fathernat",
                       "parent.*nativity", "parents.*foreign", "mom.*born", "dad.*born"),
  
  citizenship_status = c("citizen", "citizenship", "naturalized", "permanent.*resident", 
                        "green.*card", "legal.*status", "immigration.*status",
                        "us.*citizen", "american.*citizen", "naturalization"),
  
  # Ethnicity and Race
  ethnicity_race = c("ethnicity", "ethnic", "race", "racial", "hispanic", "latino", "latina",
                    "chicano", "mexican", "puerto.*rican", "cuban", "dominican", "salvadoran",
                    "guatemalan", "colombian", "ecuadorian", "peruvian", "venezuelan",
                    "central.*american", "south.*american", "caribbean", "white", "black",
                    "african.*american", "asian", "native.*american", "indigenous"),
  
  # Language
  language = c("language", "speak", "spanish", "english", "bilingual", "monolingual",
              "language.*home", "primary.*language", "first.*language", "native.*language",
              "speak.*spanish", "speak.*english", "proficiency", "fluent", "accent"),
  
  # Political Attitudes and Participation
  political_party = c("party", "political.*party", "democrat", "democratic", "republican", 
                     "independent", "partido", "politics", "partisan", "affiliation"),
  
  political_attitudes = c("approve", "approval", "disapprove", "trust", "government", 
                         "president", "congress", "senate", "vote", "voting", "election",
                         "political.*views", "conservative", "liberal", "ideology"),
  
  vote_intention = c("vote", "voting", "election", "ballot", "candidate", "campaign",
                    "turnout", "registered.*vote", "plan.*vote", "intend.*vote",
                    "will.*vote", "going.*vote", "primary", "general.*election"),
  
  # Immigration Policy and Attitudes
  immigration_attitudes = c("immigration", "immigrant", "immigr", "undocumented", "illegal.*alien",
                           "border", "deportation", "amnesty", "legalization", "pathway.*citizenship"),
  
  policy_preferences = c("daca", "dream.*act", "border.*wall", "border.*security", 
                        "comprehensive.*immigration", "guest.*worker", "temporary.*worker",
                        "e-verify", "sanctuary.*city", "local.*enforcement", "287g",
                        "secure.*communities", "detention", "family.*separation"),
  
  undocumented_contact = c("undocumented", "contact.*undocumented", "know.*undocumented",
                          "family.*undocumented", "friend.*undocumented", "worry.*deportation",
                          "fear.*deportation", "ice", "immigration.*enforcement",
                          "immigration.*raid", "mixed.*status"),
  
  # Geographic and Location
  geography = c("state", "region", "city", "county", "zip", "metropolitan", "urban", "rural",
               "northeast", "southeast", "midwest", "west", "southwest", "california", 
               "texas", "florida", "new.*york", "illinois", "arizona", "nevada",
               "colorado", "new.*mexico", "georgia", "north.*carolina"),
  
  # Socioeconomic
  education = c("education", "school", "grade", "diploma", "college", "university", 
               "degree", "bachelor", "master", "doctorate", "high.*school", "elementary",
               "graduate", "undergraduate", "vocational", "technical"),
  
  income = c("income", "salary", "wage", "earnings", "money", "financial", "economic",
            "household.*income", "family.*income", "personal.*income", "poverty"),
  
  employment = c("employ", "job", "work", "occupation", "profession", "career", 
                "unemployed", "retired", "student", "homemaker", "disabled"),
  
  # Religion and Cultural
  religion = c("religion", "religious", "church", "catholic", "protestant", "christian",
              "evangelical", "born.*again", "attend.*church", "pray", "bible", "faith"),
  
  # Additional sociodemographic
  marital_status = c("married", "single", "divorced", "widow", "separated", "partner",
                    "spouse", "husband", "wife", "relationship.*status"),
  
  household = c("household", "family.*size", "children", "kids", "dependents",
               "people.*household", "live.*with", "family.*members")
)

# Function to search for variables by concept
search_variables_by_concept <- function(variables_df, concept_name, patterns) {
  
  cat("Searching for", concept_name, "variables...\n")
  
  # Create regex pattern (case insensitive)
  combined_pattern <- paste(patterns, collapse = "|")
  
  # Search in both variable names and labels
  matched_vars <- variables_df %>%
    filter(
      str_detect(str_to_lower(raw_variable_name), str_to_lower(combined_pattern)) |
      str_detect(str_to_lower(label), str_to_lower(combined_pattern))
    ) %>%
    mutate(concept = concept_name) %>%
    arrange(year, raw_variable_name)
  
  cat("Found", nrow(matched_vars), "variables for", concept_name, "\n")
  
  return(matched_vars)
}

# Main keyword search function
main_keyword_search_extended <- function(input_file = "all_variables_extracted_2002_2007.csv") {
  
  cat("=== Extended Keyword Search for 2002-2007 ===\n\n")
  
  # Read the extracted variables
  if (!file.exists(input_file)) {
    stop("Input file not found: ", input_file)
  }
  
  all_variables <- read_csv(input_file, show_col_types = FALSE)
  cat("Loaded", nrow(all_variables), "variables from", length(unique(all_variables$year)), "years\n\n")
  
  # Search for each concept
  all_matched_variables <- data.frame()
  
  for (concept_name in names(expanded_keyword_patterns)) {
    patterns <- expanded_keyword_patterns[[concept_name]]
    
    matched_vars <- search_variables_by_concept(all_variables, concept_name, patterns)
    
    if (nrow(matched_vars) > 0) {
      all_matched_variables <- rbind(all_matched_variables, matched_vars)
    }
  }
  
  # Remove duplicates (variables that match multiple concepts)
  # Keep the first match but add all matching concepts
  unique_vars <- all_matched_variables %>%
    group_by(year, raw_variable_name) %>%
    summarise(
      label = first(label),
      concepts = paste(unique(concept), collapse = "; "),
      .groups = "drop"
    ) %>%
    arrange(year, raw_variable_name)
  
  cat("\n=== Search Results Summary ===\n")
  cat("Total unique variables found:", nrow(unique_vars), "\n")
  
  # Summary by year
  year_summary <- unique_vars %>%
    group_by(year) %>%
    summarise(n_variables = n(), .groups = "drop")
  
  cat("\nVariables by year:\n")
  print(year_summary)
  
  # Summary by concept
  concept_summary <- all_matched_variables %>%
    group_by(concept) %>%
    summarise(n_variables = n(), .groups = "drop") %>%
    arrange(desc(n_variables))
  
  cat("\nVariables by concept:\n")
  print(concept_summary)
  
  # Save results
  matched_file <- "matched_variables_by_concept_2002_2007.csv"
  write_csv(all_matched_variables, matched_file)
  cat("\nSaved detailed results:", matched_file, "\n")
  
  unique_file <- "unique_variables_all_concepts_2002_2007.csv"
  write_csv(unique_vars, unique_file)
  cat("Saved unique variables:", unique_file, "\n")
  
  # Create concept summary by year for planning
  concept_by_year <- all_matched_variables %>%
    group_by(year, concept) %>%
    summarise(n_variables = n(), .groups = "drop") %>%
    pivot_wider(names_from = year, values_from = n_variables, values_fill = 0) %>%
    arrange(concept)
  
  concept_summary_file <- "concept_summary_by_year_2002_2007.csv"
  write_csv(concept_by_year, concept_summary_file)
  cat("Saved concept summary:", concept_summary_file, "\n")
  
  return(list(
    all_matched = all_matched_variables,
    unique_vars = unique_vars,
    concept_summary = concept_summary,
    concept_by_year = concept_by_year
  ))
}

# Run the search
if (!interactive()) {
  search_results <- main_keyword_search_extended()
}