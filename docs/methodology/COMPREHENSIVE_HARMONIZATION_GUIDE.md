# 🔧 COMPREHENSIVE SURVEY HARMONIZATION GUIDE
## Advanced Variable Identification & Processing Protocol

### 📋 **BACKGROUND CONTEXT**
This guide emerged from extending harmonization of a longitudinal Hispanic/Latino survey dataset from 2002-2006 to include 2007-2012. Key insights: demographic variables exist under different names across years, age can be continuous or categorical, and race measures within-Hispanic racial identity. The greater purpose of this project is to create a merged waves dataset on NSL to study how attitutes on immigration (inferred by specific questions like support border wall, legalization of DACA, is ther etoo many immigrants, etc) changes over generation among hispanics in the U.S.

---

## 🎯 **CORE HARMONIZATION PRINCIPLES**

### **1. EXHAUSTIVE VARIABLE IDENTIFICATION**
Never assume variables don't exist - they may use different naming conventions:

**AGE Variables - Multiple Formats:**
- **Continuous**: `AGE`, `age`, `ageuse`, `qn50`, `qn62`, `qn58`, `qn64`, `qn67`
- **Categorical Ranges**: `AGE1`, `AGE2` (e.g., 1=18-29, 2=30-39, 3=40-54, 4=55+)
- **Birth Year**: `qn74year`, `birthyear`, `yob`
- **Age Groups**: Convert ranges to midpoints (18-29 → 24, 30-39 → 35, etc.)

**GENDER/SEX Variables:**
- **Standard**: `gender`, `sex`, `QND18`, `GENDER`, `RSEX`
- **Observation**: Often interviewer-recorded as `QND18` with label "GENDER"
- **Missing Pattern**: Early survey years (2002, 2006) may genuinely lack gender questions

**RACE Variables (Within-Hispanic Context):**
- **Self-Report**: `qn11` ("What race do you consider yourself to be?")
- **Interviewer**: `qn118` ("INTERVIEWER: RECORD YOUR RACE OR ETHNICITY")
- **Categories**: 1=White, 2=Black/African-American, 3=Asian, 4=Indigenous/Other
- **Interpretation**: Racial identity within Hispanic/Latino population, NOT general population race

**ETHNICITY Variables (Hispanic Subgroups):**
- **Heritage**: `QN1`, `qn1`, `qn4` ("Hispanic or Latin origin such as Mexican, Puerto Rican, Cuban...")
- **Subgroups**: Mexican, Puerto Rican, Cuban, Dominican, Central/South American, Caribbean
- **Coding**: Often 1=Yes Hispanic, 2=No (but may vary by subgroup)

**LANGUAGE Variables:**
- **Interview**: `QN2`, `language`, `qn70` ("Prefer English or Spanish interview?")
- **Home**: `Primary_language`, `lang1`, `interview_language`
- **Proficiency**: May include English proficiency scales

---

## 🔍 **SYSTEMATIC SEARCH PROTOCOL**

### **Step 1: Comprehensive Pattern Search**
```r
# Multi-pattern search for each concept
age_patterns <- c("age", "AGE", "birth", "BIRTH", "year", "YEAR", "qn.*[0-9]+.*age")
gender_patterns <- c("gender", "GENDER", "sex", "SEX", "male", "female", "QND18", "RSEX")
race_patterns <- c("race", "RACE", "ethnic", "ETHNIC", "qn11", "qn118", "interviewer.*race")
language_patterns <- c("language", "LANGUAGE", "english", "spanish", "interview", "qn2", "qn70")

for(pattern in age_patterns) {
  matches <- names(data)[grepl(pattern, names(data), ignore.case = TRUE)]
  if(length(matches) > 0) cat("AGE matches for", pattern, ":", paste(matches, collapse=", "), "\n")
}
```

### **Step 2: Binary Variable Investigation**
```r
# Find potential demographic variables (often binary)
for(var in names(data)[1:50]) {
  unique_vals <- unique(data[[var]])
  clean_vals <- unique_vals[!is.na(unique_vals)]
  
  if(length(clean_vals) == 2 && all(clean_vals %in% 1:2)) {
    label <- attr(data[[var]], 'label')
    cat(var, ": values =", paste(clean_vals, collapse=", "), 
        "- Label:", ifelse(is.null(label), "No label", substr(label, 1, 80)), "\n")
  }
}
```

### **Step 3: Codebook Analysis**
**ALWAYS examine variable labels and value labels:**
```r
# Check variable labels
attr(data$VARIABLE_NAME, 'label')

# Check value labels  
attr(data$VARIABLE_NAME, 'labels')

# For haven objects, use labelled package
library(labelled)
val_labels(data$VARIABLE_NAME)
```

---

## 🧩 **FLEXIBLE HARMONIZATION STRATEGIES**

### **Age Harmonization - Multi-Format Support**
```r
harmonize_age <- function(data, year) {
  age <- rep(NA_real_, nrow(data))
  
  # Year-specific mapping with fallbacks
  age_var_map <- list(
    "2002" = c("AGE", "age", "RAGES", "birth_year"),
    "2004" = c("AGE1", "AGE2", "age", "RAGES"), 
    "2006" = c("qn74year", "age", "birth_year"),
    # ... continue for all years
  )
  
  year_str <- as.character(year)
  if(year_str %in% names(age_var_map)) {
    age_vars <- age_var_map[[year_str]]
    
    for(var in age_vars) {
      if(var %in% names(data)) {
        age <- clean_values(data[[var]])
        
        # Handle different age formats
        if(var %in% c("AGE1", "AGE2")) {
          # Convert age ranges to midpoints
          age <- case_when(
            age == 1 ~ 24,   # 18-29
            age == 2 ~ 35,   # 30-39  
            age == 3 ~ 47,   # 40-54
            age == 4 ~ 62,   # 55+
            age == 5 ~ 70,   # 65+ (if exists)
            TRUE ~ NA_real_
          )
        } else if(grepl("year|birth", var, ignore.case=TRUE)) {
          # Convert birth year to age (survey_year - birth_year)
          current_year <- as.numeric(year)
          age <- current_year - age
        }
        
        # Validate reasonable age range
        age <- ifelse(age >= 18 & age <= 100, age, NA_real_)
        break
      }
    }
  }
  
  return(age)
}
```

### **Race Harmonization - Context-Aware**
```r
harmonize_race <- function(data, year) {
  race <- rep(NA_real_, nrow(data))
  
  # Note: In Hispanic-focused surveys, race = racial identity within Hispanic population
  race_var_map <- list(
    "2009" = c("qn11", "qn118"),  # Self-report + interviewer observation
    "2010" = c("race", "qn_race"),
    "2011" = c("race", "interviewer_race")
  )
  
  year_str <- as.character(year)
  if(year_str %in% names(race_var_map)) {
    race_vars <- race_var_map[[year_str]]
    
    for(var in race_vars) {
      if(var %in% names(data)) {
        race <- clean_values(data[[var]])
        
        # Standardize race coding
        race <- case_when(
          race == 1 ~ 1,  # White (Hispanic)
          race == 2 ~ 2,  # Black/African-American (Hispanic)
          race == 3 ~ 3,  # Asian (Hispanic)
          race == 4 ~ 4,  # Indigenous/Other (Hispanic)
          race == 5 ~ 4,  # Other (Hispanic) - group with Indigenous
          race == 6 ~ 4,  # Some other race
          TRUE ~ NA_real_
        )
        break
      }
    }
  }
  
  return(race)
}
```

---

## ⚠️ **CRITICAL VALIDATION CHECKS**

### **1. Coverage Validation**
```r
# Year-by-year coverage assessment
coverage_check <- function(data, variable) {
  by_year <- data %>%
    group_by(survey_year) %>%
    summarise(
      total = n(),
      available = sum(!is.na(.data[[variable]])),
      pct_coverage = round(100 * available / total, 1),
      unique_values = n_distinct(.data[[variable]], na.rm=TRUE)
    )
  
  print(by_year)
  
  # Flag suspicious patterns
  if(any(by_year$pct_coverage == 0)) {
    zero_years <- by_year$survey_year[by_year$pct_coverage == 0]
    cat("WARNING: Zero coverage in years:", paste(zero_years, collapse=", "), "\n")
  }
}
```

### **2. Value Distribution Check**
```r
# Check for reasonable value distributions
validate_demographics <- function(data) {
  # Age distribution
  if("age" %in% names(data)) {
    age_summary <- summary(data$age)
    if(age_summary["Min."] < 18 || age_summary["Max."] > 100) {
      cat("WARNING: Age values outside 18-100 range\n")
    }
  }
  
  # Gender distribution (should be roughly balanced)
  if("gender" %in% names(data)) {
    gender_table <- table(data$gender, useNA="always")
    gender_ratio <- max(gender_table) / min(gender_table[gender_table > 0])
    if(gender_ratio > 2) {
      cat("WARNING: Highly imbalanced gender distribution\n")
    }
  }
  
  # Race distribution (context-dependent)
  if("race" %in% names(data)) {
    race_table <- table(data$race, useNA="always")
    cat("Race distribution (within-Hispanic):\n")
    print(race_table)
  }
}
```

---

## 🎯 **CONCEPT-SPECIFIC GUIDELINES**

### **Hispanic/Latino Surveys - Special Considerations**

1. **Ethnicity = Hispanic Subgroups**: Mexican, Puerto Rican, Cuban, Dominican, etc.
2. **Race = Within-Hispanic Identity**: White Hispanic, Black Hispanic, etc.
3. **Language = Interview/Home Language**: Often English vs Spanish preference
4. **Generation Status**: Key variable - derive from nativity if not available
5. **Immigration Variables**: Often extensive policy attitude questions

### **Variable Naming Evolution Patterns**
- **Early years (2002-2006)**: Often capitalized (`AGE`, `QN1`, `LANGUAGE`)
- **Mid years (2007-2009)**: Mixed case (`qn50`, `gender`, `ageuse`)  
- **Later years (2010-2012)**: Lowercase with prefixes (`qn58`, `qn64`)

### **Missing Data Patterns**
- **Systematic missing**: Variable not asked in that year
- **Item missing**: Asked but respondent didn't answer
- **Legacy codes**: 8, 9, 98, 99, 999 = refused/don't know → convert to NA

---

## 📊 **QUALITY ASSURANCE CHECKLIST**

### **Before Harmonization:**
- [ ] Load ALL survey years and examine variable names
- [ ] Run pattern searches for each demographic concept
- [ ] Check variable labels and value labels
- [ ] Identify age format (continuous vs categorical)
- [ ] Confirm survey population (general vs Hispanic-focused)

### **During Harmonization:**
- [ ] Use year-specific variable mappings with fallbacks
- [ ] Handle different coding schemes (age ranges, language preferences)
- [ ] Standardize missing value codes (8,9,98,99 → NA)
- [ ] Validate value ranges and distributions

### **After Harmonization:**
- [ ] Check coverage statistics by year
- [ ] Validate demographic distributions
- [ ] Cross-check with known survey characteristics
- [ ] Document limitations and data sources

---

## 🔄 **ITERATIVE IMPROVEMENT PROCESS**

1. **Initial Pass**: Basic pattern matching and obvious variables
2. **Deep Dive**: Examine "zero coverage" years for missed variables  
3. **Codebook Review**: Understand question wording and response options
4. **Flexible Recoding**: Handle different formats (ranges, preferences, scales)
5. **Validation**: Statistical checks and logical consistency
6. **Documentation**: Clear notes on sources, limitations, and decisions

---

## 💡 **KEY LESSONS LEARNED**

- **Never assume variables don't exist** - they may use unexpected names
- **Age can be continuous, categorical, or birth year** - handle all formats
- **Gender may genuinely be missing** in early survey years (not an error)
- **Race in Hispanic surveys ≠ general population race** - it's within-group identity
- **Language questions vary** - interview preference vs home language vs proficiency
- **Binary variables** (1,2) often contain demographic information - check labels
- **Variable names evolve** across survey years - use comprehensive mappings
- **Validation is critical** - coverage statistics reveal harmonization issues

This guide ensures comprehensive variable capture and robust harmonization across longitudinal survey datasets with evolving question formats and naming conventions.