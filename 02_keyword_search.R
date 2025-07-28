# ==============================================================================
# Step 2: Search for Variables by Keywords
# ==============================================================================

# Load required libraries
library(dplyr)
library(stringr)
library(readr)
library(tidyr)

# Define keywords for each concept
keyword_patterns <- list(
  immigration = c("immigration", "immigrant", "immigr"),
  nativity = c("nativity", "born in u\\.?s", "born in united states", "born in america", 
               "place of birth", "country of birth", "where.*born", "native born"),
  generation = c("generation", "generational", "first generation", "second generation", 
                 "1st generation", "2nd generation", "u\\.?s\\.? born"),
  citizenship = c("citizen", "citizenship", "naturalized", "legal status"),
  political_attitudes = c("political", "party", "vote", "voting", "election", "candidate",
                         "approve", "approval", "president", "congress", "government",
                         "democrat", "republican", "liberal", "conservative"),
  border_immigration = c("border", "illegal", "undocumented", "deportation", "amnesty",
                        "path to citizenship", "comprehensive immigration")
)

# Function to search for keywords in variable labels
search_keywords <- function(variables_df) {
  cat("Searching for keyword matches in variable labels...\n")
  
  # Create a copy for results
  results <- variables_df %>%
    mutate(
      label_lower = str_to_lower(label),
      raw_variable_name_lower = str_to_lower(raw_variable_name),
      matched_concepts = "",
      matched_keywords = ""
    )
  
  # Search for each concept
  for (concept_name in names(keyword_patterns)) {
    keywords <- keyword_patterns[[concept_name]]
    
    # Create pattern for this concept (case insensitive)
    pattern <- paste(keywords, collapse = "|")
    
    # Find matches in labels or variable names
    label_matches <- str_detect(results$label_lower, pattern)
    varname_matches <- str_detect(results$raw_variable_name_lower, pattern)
    
    concept_matches <- label_matches | varname_matches
    
    # Update results for matches
    results <- results %>%
      mutate(
        matched_concepts = ifelse(
          concept_matches,
          ifelse(matched_concepts == "", concept_name, paste(matched_concepts, concept_name, sep = "; ")),
          matched_concepts
        ),
        matched_keywords = ifelse(
          concept_matches,
          ifelse(matched_keywords == "", 
                 str_extract(paste(label_lower, raw_variable_name_lower), pattern),
                 paste(matched_keywords, str_extract(paste(label_lower, raw_variable_name_lower), pattern), sep = "; ")),
          matched_keywords
        )
      )
  }
  
  # Filter to only matched variables
  matched_vars <- results %>%
    filter(matched_concepts != "") %>%
    select(-label_lower, -raw_variable_name_lower) %>%
    arrange(year, matched_concepts, raw_variable_name)
  
  return(matched_vars)
}

# Function to create summary by concept and year
create_concept_summary <- function(matched_vars) {
  # Split concepts and create long format
  concept_summary <- matched_vars %>%
    separate_rows(matched_concepts, sep = "; ") %>%
    group_by(year, matched_concepts) %>%
    summarise(
      num_variables = n(),
      example_variables = paste(head(raw_variable_name, 3), collapse = ", "),
      .groups = "drop"
    ) %>%
    arrange(matched_concepts, year)
  
  return(concept_summary)
}

# Main function
main_keyword_search <- function(input_file = "all_variables_extracted_robust.csv") {
  # Read the extracted variables
  if (!file.exists(input_file)) {
    cat("Error: File", input_file, "not found. Please run 01_variable_extraction.R first.\n")
    return(NULL)
  }
  
  variables_df <- read_csv(input_file, show_col_types = FALSE)
  cat("Loaded", nrow(variables_df), "variables from", length(unique(variables_df$year)), "survey years\n\n")
  
  # Search for keyword matches
  matched_vars <- search_keywords(variables_df)
  
  cat("Found", nrow(matched_vars), "variables matching target concepts\n")
  
  # Create summary
  concept_summary <- create_concept_summary(matched_vars)
  
  # Save results
  write_csv(matched_vars, "matched_variables_by_concept.csv")
  write_csv(concept_summary, "concept_summary_by_year.csv")
  
  cat("Results saved to:\n")
  cat("- matched_variables_by_concept.csv\n")
  cat("- concept_summary_by_year.csv\n\n")
  
  # Print summary
  cat("Summary by concept and year:\n")
  print(concept_summary, n = Inf)
  
  cat("\nSample of matched variables:\n")
  sample_vars <- matched_vars %>%
    group_by(year) %>%
    slice_head(n = 3) %>%
    ungroup() %>%
    select(year, raw_variable_name, label, matched_concepts)
  
  print(sample_vars, n = Inf)
  
  return(list(matched_vars = matched_vars, concept_summary = concept_summary))
}

# Run the search
if (!interactive()) {
  results <- main_keyword_search()
}