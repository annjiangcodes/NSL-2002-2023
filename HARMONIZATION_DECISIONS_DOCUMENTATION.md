# 📋 HARMONIZATION DECISIONS & METHODOLOGY DOCUMENTATION
## Complete Decision Log for Latino Longitudinal Survey Dataset (2002-2023)

---

## **🎯 EXECUTIVE SUMMARY**

This document provides comprehensive documentation of all **methodological decisions**, **assumptions**, and **harmonization principles** used in creating the most robust Latino longitudinal political attitudes dataset spanning 2002-2023. This documentation is essential for **transparency**, **replicability**, and **future public release notes**.

---

## **🏗️ FOUNDATIONAL PRINCIPLES**

### **Core Harmonization Philosophy**
1. **Maximize Temporal Coverage**: Prioritize including all available survey years over perfect variable consistency
2. **Preserve Original Meaning**: Maintain substantive interpretation while standardizing formats
3. **Transparent Documentation**: Document every decision for full methodological transparency
4. **Quality Over Quantity**: Better to have fewer variables with high quality than many with poor harmonization
5. **Future Extensibility**: Design framework to easily accommodate new years and variables

### **Data Quality Standards**
- **Missing Value Threshold**: Variables with >90% missing excluded from final dataset
- **Coverage Reporting**: Automated calculation and reporting of variable coverage by year
- **Validation Requirements**: Cross-check harmonized variables against original codebooks
- **Error Tolerance**: Zero tolerance for data corruption during harmonization process

---

## **📊 VARIABLE HARMONIZATION DECISIONS**

### **🧑‍🤝‍🧑 DEMOGRAPHIC VARIABLES**

#### **Age (`age`)**
**Decision**: Harmonize to continuous years where possible, categorical ranges where necessary

**Implementation Logic**:
```r
# Year-specific mappings based on original variable formats
age_var_map_extended <- list(
  "2002" = "AGE",           # Direct continuous
  "2004" = c("AGE1", "AGE2"), # Range format: convert to midpoint
  "2006" = "qn74year",      # Birth year: convert to age
  "2021" = "F_AGECAT",      # Categorical: use midpoints
  "2022" = "F_AGECAT"
)
```

**Key Assumptions**:
- **Range Conversion**: For age ranges (e.g., "30-39"), use midpoint (35)
- **Birth Year Calculation**: Current survey year minus birth year
- **Missing Codes**: 98, 99, 999 treated as missing
- **Outlier Handling**: Ages <18 or >100 flagged for review

**Rationale**: Age is fundamental demographic control variable essential for all longitudinal analysis

---

#### **Gender (`gender`)**
**Decision**: Binary harmonization with explicit missing category

**Implementation Logic**:
```r
# Standardized to 1=Male, 2=Female format
gender_harmonization <- case_when(
  gender_raw == 1 ~ 1,  # Male
  gender_raw == 2 ~ 2,  # Female
  gender_raw %in% c(8, 9, 98, 99) ~ NA_real_
)
```

**Key Assumptions**:
- **Binary Framework**: Gender conceptualized as binary male/female (reflecting survey era limitations)
- **No Third Categories**: Most surveys pre-date non-binary gender options
- **Sex vs Gender**: Treat "sex" and "gender" variables as equivalent for harmonization

**Alternative Considered**: Some years asked "sex" instead of "gender" - treated as equivalent

---

#### **Race (`race`) & Ethnicity (`ethnicity`)**
**Decision**: Separate harmonization acknowledging Latino sample limitations

**Implementation Logic**:
```r
# Race: Limited utility in Latino-focused surveys
race_harmonization <- case_when(
  race_raw == 1 ~ 1,  # White
  race_raw == 2 ~ 2,  # Black/African American
  race_raw == 3 ~ 3,  # Other/Mixed
  TRUE ~ NA_real_
)

# Ethnicity: Focus on Latino/Hispanic subgroups
ethnicity_harmonization <- case_when(
  ethnicity_raw == 1 ~ 1,  # Mexican/Mexican-American
  ethnicity_raw == 2 ~ 2,  # Puerto Rican
  ethnicity_raw == 3 ~ 3,  # Cuban
  ethnicity_raw == 4 ~ 4,  # Other Latino/Hispanic
  TRUE ~ NA_real_
)
```

**Key Assumptions**:
- **Race Limitation**: Acknowledged that race has limited variation in Latino-focused surveys
- **Ethnicity Focus**: Latino/Hispanic origin more substantively meaningful than racial categories
- **Missing by Design**: Some race missingness expected and acceptable

**User Feedback Incorporated**: "race limitation is normal because all respondents are hispanic"

---

#### **Language Spoken at Home (`language_home`)**
**Decision**: Focus on English-Spanish continuum with accommodation for other languages

**Implementation Logic**:
```r
language_var_map_extended <- list(
  "2002" = "QN2",
  "2004" = "language",
  "2021" = "PRIMARY_LANGUAGE_W86",
  "2022" = "PRIMARY_LANGUAGE_W113"
)

# Standardized categories
# 1 = English only
# 2 = Spanish only  
# 3 = Both English and Spanish
# 4 = Other language
```

**Key Assumptions**:
- **Bilingual Continuum**: English-Spanish bilingualism central to Latino experience
- **Other Languages**: Preserve category for indigenous or other heritage languages
- **Primary Language**: When multiple language variables available, use "primary" or "main" language

---

### **🏛️ CITIZENSHIP & NATIVITY VARIABLES**

#### **Citizenship Status (`citizenship_status`)**
**Decision**: Comprehensive citizenship categories reflecting immigration pathways

**Implementation Logic**:
```r
# Harmonized categories
# 1 = U.S. citizen by birth
# 2 = U.S. citizen by naturalization
# 3 = Legal permanent resident
# 4 = Temporary legal status
# 5 = Undocumented/No legal status
```

**Key Assumptions**:
- **Legal Status Hierarchy**: Categories reflect increasing security of legal status
- **Self-Reporting**: Acknowledge potential underreporting of undocumented status
- **Missing Pattern**: High missingness expected on sensitive citizenship questions

---

#### **Place of Birth (`place_birth`)**
**Decision**: Binary U.S./foreign-born with detailed foreign country when available

**Implementation Logic**:
```r
place_birth_var_map <- list(
  "2021" = "F_BIRTHPLACE_EXPANDED",
  "2022" = "F_BIRTHPLACE_EXPANDED",
  "2018" = "birthplace"  # Basic U.S./foreign
)

# Core harmonization: 1=U.S.-born, 2=Foreign-born
```

**Key Assumptions**:
- **Generation Foundation**: Place of birth essential for immigrant generation derivation
- **ATP Enhancement**: ATP surveys provide more detailed birthplace information
- **Territorial Inclusion**: Puerto Rico, U.S. territories counted as U.S.-born

**Critical Issue Resolved**: Distinguished `F_BORN` (born-again Christian) from actual birthplace variables

---

#### **Immigrant Generation (`immigrant_generation`)**
**Decision**: Implement Portes' three-generation framework with explicit derivation logic

**Implementation Framework** (Based on Portes' Demography Research):
```r
# 1st Generation: Foreign-born respondent
# 2nd Generation: U.S.-born with ≥1 foreign-born parent  
# 3rd+ Generation: U.S.-born with both parents U.S.-born
```

**Enhanced Implementation Logic**:
```r
derive_immigrant_generation_enhanced <- function(data, year) {
  # Priority 1: Use pre-calculated generation variables when available
  if (precalc_var_available) {
    use_precalc_generation()
  } else {
    # Priority 2: Derive using parent nativity + respondent nativity
    derive_from_parent_nativity()
  }
}
```

**Key Assumptions**:
- **Portes Framework**: Standard demographic approach for immigrant generations
- **Parent Nativity Priority**: When available, use both mother and father nativity
- **Conservative Coding**: If uncertain, code as missing rather than guess
- **Pre-calculated Variables**: Trust survey-constructed generation variables when available

**Major Issue Resolved**: Initial distribution (80.8% 1st generation) was "highly improbable" - resolved by:
1. Finding pre-calculated generation variables (`IMMGEN_W*`)
2. Proper parent nativity variables (`MOTHERNAT_W*`, `FATHERNAT_W*`, `parent`)
3. Implementing proper Portes framework logic

**User Feedback**: "generation and nativity needs to be inferred...please refer to portes' work on demography"

---

### **🗳️ POLITICAL VARIABLES**

#### **Political Party Identification (`party_identification`)**
**Decision**: Standard 7-point scale with independent leaners

**Implementation Logic**:
```r
party_var_map <- list(
  "2018" = "party",
  "2021" = "F_PARTY_FINAL",
  "2022" = "F_PARTY_FINAL"
)

# 1=Strong Democrat, 2=Weak Democrat, 3=Lean Democrat
# 4=Independent, 5=Lean Republican, 6=Weak Republican, 7=Strong Republican
```

**Key Assumptions**:
- **Standard Scale**: Use conventional political science 7-point party ID scale
- **Independent Leaners**: Preserve distinction between pure independents and leaners
- **Missing Partisanship**: Non-response on party ID substantively meaningful

---

#### **Immigration Attitudes Framework**
**Decision**: Multi-dimensional approach with explicit and implicit measures

**Core Philosophy**:
- **Direct Measures**: Explicit immigration policy questions (border wall, DACA, etc.)
- **Implicit Measures**: Indicators that correlate with immigration attitudes (presidential approval, crime priorities)
- **Composite Scores**: Average across available indicators for comprehensive measure

**Variable Categories**:

1. **Explicit Immigration Variables**:
   - `trump_support`: Presidential approval as immigration proxy
   - `border_wall_support`: Direct border security attitudes  
   - `immigration_level_concern`: "Too many immigrants" sentiment

2. **Implicit Immigration Variables**:
   - `border_asylum_performance`: Government job ratings on border/asylum
   - `presidential_performance`: Biden evaluation as restrictionism proxy
   - `crime_priority`: Crime importance as immigration-adjacent concern

3. **Comprehensive Composite**:
   - `immigration_restrictionism_composite`: Average of all available indicators

**Key Decision**: Multi-indicator approach more robust than single-item measures

**User Input Integration**: Based on user's mini-project analyzing 2018 NSL variables (`qn14a`, `qn29`, `qn31`)

---

### **💰 SOCIOECONOMIC VARIABLES**

#### **Household Income (`household_income`)**
**Decision**: 5-category harmonized scale across different survey formats

**Implementation Logic**:
```r
# NSL 2018 format (detailed categories) → 5-category
income_harmonization_2018 <- case_when(
  income_raw %in% c(1, 2) ~ 1,    # Low income (<$40k)
  income_raw == 3 ~ 2,            # Lower-middle ($40-60k)
  income_raw == 4 ~ 3,            # Middle ($60-100k)
  income_raw %in% c(5, 6) ~ 4,    # Upper-middle ($100k+)
  income_raw %in% c(7, 8) ~ 5,    # High income
  income_raw %in% c(98, 99) ~ NA_real_
)

# ATP 2022 format (already 5-category) → preserve
```

**Key Assumptions**:
- **Cross-Survey Consistency**: Prioritize comparable categories over original granularity
- **Economic Meaning**: Categories reflect meaningful income differences for Latino households
- **Missing Sensitivity**: High non-response expected on income questions
- **Inflation Adjustment**: Did not adjust for inflation - categories relative within survey year

**Alternative Considered**: Continuous income - rejected due to inconsistent measurement across surveys

---

#### **Education Level (`education_level`)**
**Decision**: 5-category standard educational attainment scale

**Implementation Logic**:
```r
# Standardized categories across all survey formats
# 1 = Less than high school
# 2 = High school graduate
# 3 = Some college/Associate degree  
# 4 = Bachelor's degree
# 5 = Graduate/Professional degree
```

**Key Assumptions**:
- **Educational Hierarchy**: Categories reflect increasing educational attainment
- **Meaningful Distinctions**: Each category represents substantively different educational experiences
- **GED Equivalence**: GED treated as equivalent to high school graduation
- **Associate Degree Placement**: Grouped with "some college" rather than separate category

**Rationale**: Education is crucial control variable and predictor of political attitudes

---

#### **Employment Status (`employment_status`)**
**Decision**: 5-category framework capturing major labor force categories

**Implementation Logic**:
```r
# Standardized categories
# 1 = Employed full-time
# 2 = Employed part-time
# 3 = Unemployed (seeking work)
# 4 = Retired
# 5 = Student/Other/Not in labor force
```

**Key Assumptions**:
- **Labor Force Framework**: Based on standard Bureau of Labor Statistics categories
- **Full/Part-time Distinction**: Important for understanding economic security
- **Retirement Separate**: Retired distinct from unemployed
- **Student Category**: Students grouped with "other" due to small sample sizes

**COVID-19 Consideration**: 2021 employment variables reflect pandemic-specific work situations

---

### **🗺️ GEOGRAPHIC VARIABLES**

#### **Census Region (`census_region`)**
**Decision**: Use standard U.S. Census Bureau 4-region classification

**Implementation Logic**:
```r
# Standard Census regions
# 1 = Northeast
# 2 = Midwest  
# 3 = South
# 4 = West
```

**Key Assumptions**:
- **Census Standard**: Use official Census Bureau regional definitions
- **Latino Distribution**: Regions capture meaningful variation in Latino population concentration
- **Political Relevance**: Regional differences important for political attitude variation

**Coverage**: Excellent in ATP surveys (2021, 2022), limited in NSL surveys

---

#### **Metropolitan Area (`metro_area`)**
**Decision**: Binary urban/rural classification based on metropolitan statistical areas

**Implementation Logic**:
```r
# Binary classification
# 1 = Metropolitan area (urban)
# 2 = Non-metropolitan area (rural)
```

**Key Assumptions**:
- **Urban-Rural Distinction**: Fundamental geographic divide for political attitudes
- **MSA Definition**: Use Office of Management and Budget metropolitan statistical area definitions
- **Binary Simplification**: More complex urban classifications collapsed for consistency

**Rationale**: Urban-rural divide increasingly important for understanding political polarization

---

### **⚖️ SURVEY METHODOLOGY VARIABLES**

#### **Survey Weights (`survey_weight`)**
**Decision**: Preserve original survey weights with outlier cleaning

**Implementation Logic**:
```r
# Weight preservation with cleaning
survey_weight <- as.numeric(original_weight)
survey_weight[survey_weight <= 0 | survey_weight > 10] <- NA
```

**Key Assumptions**:
- **Original Design**: Survey weights reflect intended population representation
- **Outlier Definition**: Weights >10 likely data errors rather than valid extreme weights
- **No Rescaling**: Preserve original scale for proper variance estimation
- **Missing Pattern**: Missing weights typically mean respondent excluded from weighted analysis

**Critical Importance**: Essential for population-representative estimates and proper statistical inference

---

## **🔧 TECHNICAL IMPLEMENTATION DECISIONS**

### **Missing Value Handling**

#### **Legacy Missing Code Standardization**
**Decision**: Normalize all legacy missing codes to R's NA

**Implementation**:
```r
# Standardized missing code treatment
missing_codes <- c(8, 9, 98, 99, 999, -1, -9)
standardized_data[standardized_data %in% missing_codes] <- NA
```

**Key Assumptions**:
- **Survey Convention**: Codes 98, 99 typically "Don't know" and "Refused"
- **Single Digit**: Codes 8, 9 often missing in older surveys
- **Negative Codes**: Some surveys use negative codes for missing
- **Conservative Approach**: When uncertain, code as missing rather than impute

---

#### **Value Coding Consistency**
**Decision**: Standardize all binary coding to 1=Yes, 0=No format

**Implementation Example**:
```r
# Convert various binary formats to consistent coding
standardized_binary <- case_when(
  original %in% c(1, "Yes") ~ 1,    # Yes/Approve/Favor
  original %in% c(2, "No") ~ 0,     # No/Disapprove/Oppose  
  TRUE ~ NA_real_
)
```

**Key Assumptions**:
- **Intuitive Coding**: 1=Yes more intuitive than 1=No
- **Cross-Survey Consistency**: Some surveys use 1=Yes, 2=No; others use 1=Yes, 0=No
- **Statistical Convenience**: 1/0 coding facilitates mean calculations and regression analysis

---

### **Variable Naming Conventions**

#### **Harmonized Variable Names**
**Decision**: Descriptive, standardized naming scheme

**Naming Principles**:
- **Descriptive**: Variable name indicates content (`household_income` not `inc`)
- **Underscore Separation**: Use underscores for readability
- **Consistent Suffixes**: `_level`, `_status`, `_attitude` for different variable types
- **No Abbreviations**: Avoid ambiguous abbreviations

**Examples**:
```
household_income          (not: income, inc, hh_inc)
education_level          (not: educ, education)
employment_status        (not: employ, work_status)
immigration_restrictionism_composite  (not: imm_restrict, composite)
```

---

### **File Organization & Workflow**

#### **Repository Structure Decision**
**Decision**: Implement standard research project organization

**Implemented Structure**:
```
data/
├── raw/                 # Original survey files
├── processed/           # Intermediate processing
│   ├── cleaned_data/    # Year-by-year harmonized files
│   └── cleaned_data_final/  # Final processing versions
└── final/              # Research-ready datasets

scripts/
├── 01_extraction/      # Variable identification scripts
├── 02_harmonization/   # Data harmonization scripts
└── 03_analysis/        # Analysis scripts

docs/
├── codebooks/          # Survey documentation
└── guides/             # Project documentation

outputs/
├── summaries/          # Data summaries and metadata
├── logs/               # Processing logs
└── validation/         # Quality assurance outputs
```

**Key Assumptions**:
- **Separation of Concerns**: Raw data never modified, all processing in separate directories
- **Reproducibility**: Complete workflow documentation and script organization
- **Collaboration**: Structure facilitates multiple researchers working on project

---

## **📋 DATA QUALITY ASSURANCE DECISIONS**

### **Coverage Reporting Framework**
**Decision**: Automated coverage calculation with color-coded status indicators

**Implementation**:
```r
# Automated coverage reporting
coverage_threshold <- list(
  excellent = 80,    # ✅ Green
  good = 50,         # ⚠️ Yellow  
  poor = 0           # ❌ Red
)

for(var in key_variables) {
  coverage <- 100 * sum(!is.na(data[[var]])) / nrow(data)
  status <- case_when(
    coverage >= 80 ~ "✅",
    coverage >= 50 ~ "⚠️",
    TRUE ~ "❌"
  )
}
```

**Key Assumptions**:
- **80% Threshold**: Variables with ≥80% coverage considered excellent
- **50% Threshold**: Variables with 50-79% coverage usable but need improvement
- **Visual Indicators**: Color-coding facilitates quick quality assessment

---

### **Validation Against External Sources**
**Decision**: Benchmark demographic variables against Census/ACS where possible

**Planned Validation**:
- **Age Distribution**: Compare to American Community Survey Latino population
- **Education**: Validate against Census educational attainment data
- **Geographic**: Cross-check regional distribution with Latino population patterns
- **Generation**: Compare generation distribution to established demographic research

**Key Assumptions**:
- **External Validity**: Survey should approximate known population parameters
- **Sample Representativeness**: Large deviations from known demographics indicate potential bias
- **Weighting Effectiveness**: Properly weighted data should align with external benchmarks

---

## **🎯 METHODOLOGICAL ASSUMPTIONS**

### **Longitudinal Comparability**
**Key Assumption**: Prioritize temporal consistency over perfect measurement

**Implementation Decisions**:
- **Consistent Categories**: Use same response categories across years even if original surveys had more/fewer options
- **Missing Years**: Accept gaps in temporal coverage rather than force problematic harmonization
- **Survey Design Changes**: Acknowledge that NSL→ATP transition affects comparability

**Trade-offs Accepted**:
- **Granularity Loss**: Some detail lost in harmonization for comparability
- **Survey Effects**: Cannot fully separate real change from survey design effects
- **Mode Effects**: Phone vs. web vs. in-person differences not fully adjustable

---

### **Cultural and Linguistic Considerations**
**Key Assumption**: Survey instruments capture meaningful concepts across Latino subgroups

**Implementation Decisions**:
- **Language Equivalence**: Assume English/Spanish survey versions measure same constructs
- **Cultural Validity**: Trust survey designers' cultural adaptation of questions
- **Subgroup Differences**: Acknowledge potential differences between Mexican, Puerto Rican, Cuban, etc. respondents

**Limitations Acknowledged**:
- **Translation Effects**: Cannot verify equivalence of English/Spanish question wording
- **Cultural Specificity**: Some political concepts may not translate directly across Latino subgroups
- **Interviewer Effects**: Different interviewer training/background may affect responses

---

### **Political Context Assumptions**
**Key Assumption**: Political attitudes measurable through survey instruments despite sensitive topics

**Implementation Decisions**:
- **Social Desirability**: Accept potential bias in immigration/political attitude reporting
- **Temporal Context**: Acknowledge that same questions may have different meanings across political eras
- **Issue Salience**: Assume immigration attitudes relevant across all survey years

**Contextual Considerations**:
- **Trump Era Effects**: 2016-2020 period may show unusual political attitude patterns
- **COVID-19 Impact**: 2020-2021 surveys may reflect pandemic-specific concerns
- **Policy Changes**: DACA, family separation, etc. may affect attitude measurement

---

## **⚠️ LIMITATIONS & CAVEATS**

### **Acknowledged Data Limitations**

1. **Temporal Gaps**: Missing survey years (2003, 2005, 2013, 2017, 2019-2020) limit continuous coverage
2. **Survey Design Changes**: NSL to ATP transition affects comparability
3. **Sample Representativeness**: Not all surveys use probability sampling
4. **Variable Availability**: Not all concepts measured in all years
5. **Response Bias**: Sensitive political/immigration questions subject to social desirability bias

### **Methodological Limitations**

1. **Harmonization Trade-offs**: Simplified categories may lose important nuance
2. **Missing Data**: No imputation performed - complete case analysis required
3. **Weighting**: Survey weights not harmonized across different survey designs
4. **Validation**: Limited external validation of harmonized variables
5. **Documentation**: Some original codebook information incomplete

### **Analytical Limitations**

1. **Causal Inference**: Observational data limits causal claims
2. **Generalizability**: Findings specific to Latino population in U.S.
3. **Temporal Trends**: Cannot separate real change from measurement artifacts
4. **Subgroup Analysis**: Limited power for smaller Latino subgroups
5. **Geographic Coverage**: Not all states/regions represented in all years

---

## **📝 DECISION RATIONALE DOCUMENTATION**

### **Why These Decisions Matter for Public Release**

1. **Transparency**: Full documentation enables users to understand data construction
2. **Replicability**: Decisions documented sufficiently for replication
3. **Appropriate Use**: Users can assess whether harmonized data suitable for their research questions
4. **Limitation Awareness**: Users understand what analyses are/aren't appropriate
5. **Quality Assessment**: Coverage statistics help users evaluate data quality

### **Future Public Release Notes Should Include**:

1. **Variable Construction Details**: How each harmonized variable was created
2. **Coverage Statistics**: Percentage coverage by variable and year
3. **Known Limitations**: What analyses are not recommended
4. **Recommended Uses**: What research questions dataset best addresses
5. **Citation Requirements**: How to properly credit original surveys and harmonization work

---

## **🔄 ITERATIVE IMPROVEMENT PROCESS**

### **User Feedback Integration**
**Process**: Continuously incorporated user feedback throughout development

**Examples of User-Driven Changes**:
1. **Generation Distribution**: "highly improbable" feedback led to improved derivation logic
2. **Missing Demographics**: User identified missing variables led to enhanced mapping
3. **Alternative Wording**: User suggested checking for alternative question wording
4. **Implicit Measures**: User mini-project inspired expanded immigration attitude framework

### **Quality Control Iterations**
**Process**: Multiple rounds of testing and refinement

**Iteration Examples**:
1. **Encoding Issues**: Developed multi-encoding file loading after initial failures
2. **Variable Mapping**: Refined mappings after discovering better variable names
3. **Coverage Reporting**: Enhanced automated quality reporting based on testing
4. **Error Handling**: Added robust error handling after encountering data loading issues

---

## **🎯 CONCLUSION**

This comprehensive documentation captures all major decisions, assumptions, and principles used in creating the enhanced Latino longitudinal political attitudes dataset. These decisions prioritize **transparency**, **replicability**, and **methodological rigor** while acknowledging inherent limitations in survey harmonization.

**Key Principles Consistently Applied**:
✅ **Maximize temporal coverage** while maintaining quality  
✅ **Document every decision** for full transparency  
✅ **Prioritize substantive meaning** over technical convenience  
✅ **Acknowledge limitations** rather than overstate capabilities  
✅ **Enable future improvement** through extensible framework  

This documentation should serve as the foundation for **public release notes**, **methodological appendices**, and **user guides** for the final dataset.