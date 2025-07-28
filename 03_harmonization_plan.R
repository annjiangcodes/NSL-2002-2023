# ==============================================================================
# Step 3: Create Harmonization Plan
# ==============================================================================

# Load required libraries
library(dplyr)
library(stringr)
library(readr)
library(tidyr)

# Function to suggest harmonized variable names based on concepts
suggest_harmonized_names <- function(concept, label) {
  concept_mappings <- list(
    immigration = c("immigration_attitude", "immigration_opinion", "immigration_view"),
    nativity = c("nativity", "place_birth", "born_us", "country_birth"),
    generation = c("generation", "immigrant_generation", "us_generation"),
    citizenship = c("citizenship_status", "citizen", "naturalized"),
    political_attitudes = c("political_party", "vote_choice", "political_view", "approval_rating"),
    border_immigration = c("border_security", "illegal_immigration", "deportation_view")
  )
  
  # Simple logic to suggest names - can be refined
  if (concept %in% names(concept_mappings)) {
    # Try to match more specific patterns in labels
    label_lower <- str_to_lower(label)
    
    if (str_detect(label_lower, "party|democrat|republican")) {
      return("political_party")
    } else if (str_detect(label_lower, "vote|voting|election")) {
      return("vote_intention")
    } else if (str_detect(label_lower, "approve|approval")) {
      return("approval_rating")
    } else if (str_detect(label_lower, "born.*us|born.*america|place.*birth")) {
      return("place_birth")
    } else if (str_detect(label_lower, "citizen|naturalized")) {
      return("citizenship_status")
    } else if (str_detect(label_lower, "generation")) {
      return("immigrant_generation")
    } else if (str_detect(label_lower, "immigration|immigrant")) {
      return("immigration_attitude")
    } else if (str_detect(label_lower, "border|illegal|undocumented")) {
      return("border_security_attitude")
    } else {
      return(concept_mappings[[concept]][1])
    }
  }
  
  return("unknown_concept")
}

# Function to suggest value recoding based on variable inspection
suggest_value_recode <- function(raw_name, label, year) {
  label_lower <- str_to_lower(label)
  
  # Common patterns for different variable types
  if (str_detect(label_lower, "yes|no") || str_detect(raw_name, "dummy|flag")) {
    return("1=Yes, 0=No")
  } else if (str_detect(label_lower, "party") && str_detect(label_lower, "democrat|republican")) {
    return("1=Democrat, 2=Republican, 3=Independent, 4=Other")
  } else if (str_detect(label_lower, "approve") || str_detect(label_lower, "opinion|attitude")) {
    return("1=Strongly Approve, 2=Somewhat Approve, 3=Somewhat Disapprove, 4=Strongly Disapprove")
  } else if (str_detect(label_lower, "generation")) {
    return("1=First generation, 2=Second generation, 3=Third+ generation")
  } else if (str_detect(label_lower, "citizen")) {
    return("1=US Citizen, 2=Permanent Resident, 3=Other")
  } else if (str_detect(label_lower, "born")) {
    return("1=US Born, 2=Foreign Born")
  } else {
    return("See codebook - needs manual review")
  }
}

# Main function to create harmonization plan
create_harmonization_plan <- function(matched_vars_file = "matched_variables_by_concept.csv", 
                                     focus_years = c(2002, 2004)) {
  
  if (!file.exists(matched_vars_file)) {
    cat("Error: File", matched_vars_file, "not found. Please run 02_keyword_search.R first.\n")
    return(NULL)
  }
  
  # Read matched variables
  matched_vars <- read_csv(matched_vars_file, show_col_types = FALSE)
  
  # Filter to focus years if specified
  if (!is.null(focus_years)) {
    matched_vars <- matched_vars %>%
      filter(year %in% focus_years)
    cat("Focusing on years:", paste(focus_years, collapse = ", "), "\n")
    
    if (nrow(matched_vars) == 0) {
      cat("WARNING: No variables found for the specified focus years.\n")
      cat("Available years in the dataset:\n")
      all_years <- read_csv(matched_vars_file, show_col_types = FALSE) %>%
        distinct(year) %>%
        arrange(year) %>%
        pull(year)
      cat(paste(all_years, collapse = ", "), "\n")
      
      # Return empty harmonization plan
      empty_plan <- data.frame(
        year = integer(),
        raw_name = character(),
        concept = character(),
        harmonized_name = character(),
        values_recode = character(),
        notes = character(),
        stringsAsFactors = FALSE
      )
      write_csv(empty_plan, "harmonization_plan.csv")
      cat("Created empty harmonization plan.\n")
      return(empty_plan)
    }
  }
  
  # Split concepts for cases where variables match multiple concepts
  harmonization_plan <- matched_vars %>%
    separate_rows(matched_concepts, sep = "; ") %>%
    rowwise() %>%
    mutate(
      concept = matched_concepts,
      harmonized_name = suggest_harmonized_names(concept, label),
      values_recode = suggest_value_recode(raw_variable_name, label, year),
      notes = paste("Original label:", label)
    ) %>%
    ungroup() %>%
    select(
      year,
      raw_name = raw_variable_name,
      concept,
      harmonized_name,
      values_recode,
      notes
    ) %>%
    arrange(year, concept, harmonized_name, raw_name)
  
  # Save the harmonization plan
  write_csv(harmonization_plan, "harmonization_plan.csv")
  
  cat("Created harmonization plan with", nrow(harmonization_plan), "variable mappings\n")
  cat("Saved to: harmonization_plan.csv\n\n")
  
  # Print summary
  plan_summary <- harmonization_plan %>%
    group_by(year, concept) %>%
    summarise(
      num_variables = n(),
      unique_harmonized_names = n_distinct(harmonized_name),
      .groups = "drop"
    ) %>%
    arrange(year, concept)
  
  cat("Summary of harmonization plan:\n")
  print(plan_summary, n = Inf)
  
  # Show sample of the plan
  cat("\nSample of harmonization plan:\n")
  sample_plan <- harmonization_plan %>%
    group_by(year) %>%
    slice_head(n = 5) %>%
    ungroup()
  
  print(sample_plan, n = Inf)
  
  return(harmonization_plan)
}

# Function to create a manual review template
create_review_template <- function(harmonization_plan) {
  review_template <- harmonization_plan %>%
    group_by(harmonized_name, concept) %>%
    summarise(
      years_available = paste(sort(unique(year)), collapse = ", "),
      example_raw_names = paste(head(raw_name, 3), collapse = "; "),
      example_labels = paste(head(str_trunc(notes, 50), 2), collapse = " | "),
      suggested_recode = first(values_recode),
      .groups = "drop"
    ) %>%
    mutate(
      manual_review_needed = "YES",
      final_harmonized_name = harmonized_name,
      final_recode_scheme = suggested_recode,
      reviewer_notes = ""
    ) %>%
    arrange(concept, harmonized_name)
  
  write_csv(review_template, "harmonization_review_template.csv")
  cat("Created manual review template: harmonization_review_template.csv\n")
  
  return(review_template)
}

# Main execution
if (!interactive()) {
  harmonization_plan <- create_harmonization_plan()
  if (!is.null(harmonization_plan)) {
    review_template <- create_review_template(harmonization_plan)
  }
}