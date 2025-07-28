# Longitudinal Survey Data Harmonization Workflow

This repository contains R scripts for harmonizing longitudinal survey data focused on **immigration attitudes, nativity, generation, and political attitudes**. The workflow is designed to handle survey datasets stored in `.sav` (SPSS) or `.dta` (Stata) formats across multiple years.

## 🎯 Objectives

1. **Extract** variable names and labels from all survey files
2. **Identify** variables related to immigration, nativity, generation, and political attitudes
3. **Map** these variables across survey years despite differing names
4. **Harmonize** them into a consistent longitudinal dataset
5. **Create** reusable R scripts for cleaning and merging each wave

## 📁 Repository Structure

```
├── 00_master_script.R              # Runs complete workflow
├── 01_variable_extraction.R        # Extracts variables from all files
├── 02_keyword_search.R             # Searches for target concepts
├── 03_harmonization_plan.R         # Creates harmonization mapping
├── 04_data_harmonization.R         # Applies harmonization to data
├── README.md                       # This documentation
└── [survey data files]             # .sav/.dta files
```

## 🚀 Quick Start

### Prerequisites

Install required R packages:
```r
install.packages(c("haven", "dplyr", "stringr", "readr", "tidyr", "labelled", "purrr"))
```

### Option 1: Run Complete Workflow
```r
source("00_master_script.R")
```

### Option 2: Run Individual Steps
```r
# Step 1: Extract all variables
source("01_variable_extraction.R")

# Step 2: Search for target concepts
source("02_keyword_search.R")

# Step 3: Create harmonization plan
source("03_harmonization_plan.R")

# Step 4: Apply harmonization
source("04_data_harmonization.R")
```

## 📊 Output Files

| File | Description |
|------|-------------|
| `all_variables_extracted.csv` | All variables from all survey files |
| `matched_variables_by_concept.csv` | Variables matching target concepts |
| `concept_summary_by_year.csv` | Summary of concepts by year |
| `harmonization_plan.csv` | Variable mapping plan |
| `harmonization_review_template.csv` | Template for manual review |
| `processing_summary.csv` | Data processing summary |
| `cleaned_data/` | Directory with individual cleaned wave files |
| `longitudinal_data_[timestamp].csv` | Final merged longitudinal dataset |

## 🔍 Target Concepts and Keywords

The workflow searches for variables related to:

### Immigration Attitudes
- Keywords: `immigration`, `immigrant`, `immigr`

### Nativity/Place of Birth
- Keywords: `nativity`, `born in u.s`, `born in united states`, `place of birth`, `country of birth`, `native born`

### Generation Status
- Keywords: `generation`, `first generation`, `second generation`, `u.s. born`

### Citizenship
- Keywords: `citizen`, `citizenship`, `naturalized`, `legal status`

### Political Attitudes
- Keywords: `political`, `party`, `vote`, `election`, `approve`, `president`, `democrat`, `republican`

### Border/Immigration Policy
- Keywords: `border`, `illegal`, `undocumented`, `deportation`, `amnesty`

## 🛠 Harmonization Process

### Step 1: Variable Extraction
```r
# Function extracts:
# - Variable names
# - Variable labels  
# - Year (from filename)
extract_variables(file_path, year)
```

### Step 2: Keyword Matching
```r
# Searches variable names and labels for target keywords
# Creates concept assignments for each variable
search_keywords(variables_df)
```

### Step 3: Harmonization Planning
```r
# Suggests harmonized variable names and recoding schemes
# Example output:
| year | raw_name | concept | harmonized_name | values_recode | notes |
|------|----------|---------|------------------|---------------|-------|
| 2002 | q15a     | immigration | immigration_attitude | 1=Approve, 2=Disapprove | Original label: Immigration policy |
```

### Step 4: Data Harmonization
```r
# Applies harmonization plan to actual data
# Recodes variables according to plan
# Exports cleaned CSV files
harmonize_variable(data, raw_name, harmonized_name, values_recode)
```

## 📋 Example Harmonized Variables

| Concept | Harmonized Name | Description |
|---------|-----------------|-------------|
| Immigration | `immigration_attitude` | General immigration attitudes |
| Nativity | `place_birth` | US-born vs foreign-born |
| Generation | `immigrant_generation` | 1st, 2nd, 3rd+ generation |
| Citizenship | `citizenship_status` | Citizen, permanent resident, other |
| Political | `political_party` | Party identification |
| Political | `vote_intention` | Voting preferences |
| Political | `approval_rating` | Presidential approval |

## 🔧 Customization

### Adding New Keywords
Edit the `keyword_patterns` list in `02_keyword_search.R`:
```r
keyword_patterns <- list(
  immigration = c("immigration", "immigrant", "border"),
  # Add new concepts:
  new_concept = c("keyword1", "keyword2", "keyword3")
)
```

### Modifying Harmonization Rules
Edit the `suggest_harmonized_names()` function in `03_harmonization_plan.R`:
```r
if (str_detect(label_lower, "your_pattern")) {
  return("your_harmonized_name")
}
```

### Adding New Survey Years
1. Place new `.sav` or `.dta` files in the repository
2. Update year mappings in `01_variable_extraction.R` if needed
3. Modify `focus_years` parameter in scripts

## 📝 Manual Review Process

1. **Review** `harmonization_review_template.csv`
2. **Verify** suggested harmonized names make sense
3. **Check** value recoding schemes using original codebooks
4. **Update** `harmonization_plan.csv` as needed
5. **Re-run** steps 4-5 with refined plan

## ⚠️ Important Notes

- **Always backup** original data files
- **Review harmonization plan** before applying to data
- **Check value distributions** in harmonized variables
- **Consult original codebooks** for complex recoding
- **Test on subset** before processing all waves

## 🔄 Iterative Workflow

1. Start with 2002-2004 (as implemented)
2. Review and refine harmonization rules
3. Add 2006-2008 waves
4. Continue adding waves iteratively
5. Validate harmonized variables across waves

## 📚 Dependencies

- `haven`: Reading SPSS/Stata files
- `dplyr`: Data manipulation
- `stringr`: String operations
- `readr`: CSV I/O
- `tidyr`: Data reshaping
- `labelled`: Variable labels
- `purrr`: Functional programming

## 🤝 Contributing

1. Test workflow on new survey waves
2. Improve keyword detection patterns
3. Enhance harmonization logic
4. Add validation checks
5. Document new variable concepts

## 📞 Support

For questions about specific survey variables or harmonization decisions, consult:
- Original survey codebooks
- Variable documentation files
- Survey methodology reports

---

**Note**: This workflow is designed for the specific survey collection in this repository. Adapt keyword patterns and harmonization rules for other survey series.