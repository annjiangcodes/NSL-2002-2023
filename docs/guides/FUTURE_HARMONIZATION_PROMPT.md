# 🎯 COMPREHENSIVE SURVEY HARMONIZATION PROMPT
## For Advanced Variable Identification & Processing

### **CONTEXT & APPROACH**
You are harmonizing a longitudinal survey dataset where **demographic variables exist under different names across years** and may use **flexible question wording and coding schemes** that speak to the same underlying concept. Your task is to achieve **maximum possible coverage** by exhaustively identifying all relevant variables using sophisticated pattern matching and contextual understanding.

---

## 🔍 **SYSTEMATIC VARIABLE IDENTIFICATION PROTOCOL**

### **1. EXHAUSTIVE PATTERN SEARCH - NEVER ASSUME MISSING**
For each demographic concept, search for **ALL possible naming conventions**:

**AGE - Multiple Formats:**
```r
# Search patterns: age, AGE, birth, year, qn + numbers
age_patterns <- c("age", "AGE", "AGES", "birth", "BIRTH", "year", "YEAR", 
                  "qn[0-9]+", "ageuse", "agewgt", "yob", "born")
```
- **Continuous**: `AGE`, `age`, `ageuse`, `qn50`, `qn62`, `qn58`, `qn64`, `qn67`
- **Categorical**: `AGE1`, `AGE2` (convert ranges: 18-29→24, 30-39→35, 40-54→47, 55+→62)
- **Birth Year**: Calculate age = survey_year - birth_year

**GENDER/SEX - Often Interviewer-Recorded:**
```r
# Search patterns: gender, sex, observation variables
gender_patterns <- c("gender", "GENDER", "sex", "SEX", "male", "female", 
                     "QND18", "RSEX", "observe", "record")
```
- **Key Finding**: `QND18` often labeled "GENDER" (interviewer observation)
- **Missing Pattern**: Early years (2002, 2006) may genuinely lack gender questions

**RACE - Context-Dependent Interpretation:**
```r
# In Hispanic surveys: race = within-Hispanic racial identity
race_patterns <- c("race", "RACE", "qn11", "qn118", "interviewer.*race", 
                   "white", "black", "asian", "indigenous")
```
- **Hispanic Context**: 1=White Hispanic, 2=Black Hispanic, 3=Asian Hispanic, 4=Indigenous/Other Hispanic
- **Questions**: "What race do you consider yourself to be?" (qn11), "INTERVIEWER: RECORD RACE" (qn118)

**ETHNICITY - Hispanic Subgroups:**
```r
# Heritage and national origin within Hispanic population
ethnicity_patterns <- c("QN1", "qn1", "qn4", "heritage", "origin", "mexican", 
                        "puerto", "cuban", "dominican", "hispanic", "latino")
```

**LANGUAGE - Preference/Proficiency:**
```r
# Interview language, home language, proficiency
language_patterns <- c("QN2", "language", "LANGUAGE", "english", "spanish", 
                       "qn70", "interview", "primary", "lang1", "prefer")
```

### **2. BINARY VARIABLE INVESTIGATION**
Many demographics are binary (1,2) - **check all binary variables for labels**:
```r
for(var in names(data)[1:100]) {  # Check more variables than default
  unique_vals <- unique(data[[var]])
  clean_vals <- unique_vals[!is.na(unique_vals)]
  
  if(length(clean_vals) == 2 && all(clean_vals %in% 1:2)) {
    label <- attr(data[[var]], 'label')
    cat(var, ": Label =", ifelse(is.null(label), "No label", label), "\n")
  }
}
```

### **3. LABEL-BASED IDENTIFICATION**
**ALWAYS examine variable and value labels** - variables may have unexpected names:
```r
# Check ALL variables for demographic-related labels
for(var in names(data)) {
  label <- attr(data[[var]], 'label')
  if(!is.null(label)) {
    if(grepl("age|gender|sex|race|ethnic|language|interview", label, ignore.case=TRUE)) {
      cat(var, ":", label, "\n")
    }
  }
}
```

---

## 🧩 **FLEXIBLE HARMONIZATION STRATEGIES**

### **YEAR-SPECIFIC MAPPING WITH FALLBACKS**
Create comprehensive variable maps with multiple fallback options:
```r
age_var_map <- list(
  "2002" = c("AGE", "age", "RAGES", "birth_year", "yob"),
  "2004" = c("AGE1", "AGE2", "age", "RAGES", "agecat"), 
  "2006" = c("qn74year", "age", "birth_year", "agegroup"),
  "2007" = c("qn50", "age", "ageuse"),
  # ... continue with all possibilities
)
```

### **HANDLE MULTIPLE DATA FORMATS**
```r
# Age: continuous, categorical, birth year
if(var %in% c("AGE1", "AGE2")) {
  # Convert age ranges to midpoints
  age <- case_when(
    age == 1 ~ 24,   # 18-29
    age == 2 ~ 35,   # 30-39  
    age == 3 ~ 47,   # 40-54
    age == 4 ~ 62,   # 55+
    age == 5 ~ 70,   # 65+
    TRUE ~ NA_real_
  )
} else if(grepl("year|birth|yob", var, ignore.case=TRUE)) {
  # Convert birth year to age
  age <- survey_year - age
}
```

---

## 📊 **CRITICAL VALIDATION & DEBUGGING**

### **COVERAGE ANALYSIS - IDENTIFY MISSED VARIABLES**
```r
# Year-by-year coverage check
coverage_by_year <- combined_data %>%
  group_by(survey_year) %>%
  summarise(
    total = n(),
    age_available = sum(!is.na(age)),
    gender_available = sum(!is.na(gender)),
    race_available = sum(!is.na(race)),
    .groups = 'drop'
  ) %>%
  mutate(
    age_pct = round(100 * age_available / total, 1),
    gender_pct = round(100 * gender_available / total, 1),
    race_pct = round(100 * race_available / total, 1)
  )

# FLAG: Any 0% coverage = likely missed variables
print(coverage_by_year)
```

### **WHEN YOU SEE 0% COVERAGE:**
1. **Re-examine raw data** for that specific year
2. **Search alternative naming patterns** (capitalization, prefixes, suffixes)
3. **Check binary variables** with demographic labels
4. **Review survey documentation** for variable name changes
5. **Consider genuine absence** (some early surveys lack certain demographics)

---

## 🎯 **CONTEXT-SPECIFIC CONSIDERATIONS**

### **Hispanic/Latino Surveys:**
- **Ethnicity** = Hispanic subgroups (Mexican, Puerto Rican, Cuban, etc.)
- **Race** = Racial identity within Hispanic population (NOT general race)
- **Language** = Interview preference or home language proficiency
- **Generation** = Critical variable (derive from nativity if direct measure unavailable)

### **Variable Naming Evolution:**
- **Early years (2002-2006)**: Capitalized (`AGE`, `QN1`, `LANGUAGE`)
- **Mid years (2007-2009)**: Mixed case (`qn50`, `gender`, `ageuse`)
- **Later years (2010-2012)**: Lowercase prefixed (`qn58`, `qn64`)

### **Missing Data Interpretation:**
- **Systematic missing** = Variable not asked in that year
- **Item missing** = Asked but not answered
- **Legacy codes** = 8, 9, 98, 99, 999 (refused/don't know) → convert to NA

---

## ✅ **SUCCESS CRITERIA & FINAL CHECKS**

### **Target Coverage Benchmarks:**
- **Age**: >80% (available in most years via multiple formats)
- **Gender**: >40% (limited by survey design in early years)
- **Ethnicity**: >90% (core question in Hispanic surveys)
- **Language**: >60% (interview preference widely asked)
- **Race**: >20% (context-dependent, limited availability)

### **Quality Validation:**
1. **Coverage by year** - No unexplained 0% coverage
2. **Value distributions** - Reasonable demographic patterns
3. **Logical consistency** - Age ranges 18-100, balanced gender, etc.
4. **Documentation** - Clear notes on variable sources and limitations

---

## 🔄 **ITERATIVE IMPROVEMENT MANTRA**

**"Never assume variables don't exist - they're hiding under different names"**

1. **Search exhaustively** using multiple patterns
2. **Examine all binary variables** for demographic labels  
3. **Check variable labels** for unexpected naming
4. **Handle multiple formats** (continuous, categorical, birth year)
5. **Validate coverage** and debug zero-coverage years
6. **Document thoroughly** - sources, decisions, limitations

**Your goal: Maximum possible demographic coverage given the survey design constraints.**