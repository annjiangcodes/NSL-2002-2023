# 📊 National Survey of Latinos (NSL) Harmonization and Analysis Project

A comprehensive project created in July 2025 for harmonizing and analyzing longitudinal survey data from the National Survey of Latinos spanning 2002-2023, with a focus on immigration attitudes, generational differences, and demographic trends within the Hispanic/Latino community.

## 🎯 Project Overview

This project harmonizes 22 years of National Survey of Latinos data (2002-2023), creating a comprehensive longitudinal dataset (37,496+ observations) suitable for studying immigration attitudes, political opinions, generational assimilation patterns, and demographic changes within Latino communities over two decades.

### Key Achievements
- ✅ **Complete temporal coverage**: Full harmonization of 2002-2023 NSL data (22 years)
- ✅ **Comprehensive immigration attitudes**: Multiple indices including liberalism, restrictionism, and concern measures
- ✅ **Generation variable derivation**: Sophisticated generation coding from nativity and parent birthplace data
- ✅ **Survey weight integration**: Properly weighted analyses for nationally representative estimates
- ✅ **Advanced statistical analysis**: Multilevel modeling, trend analysis, and generational comparisons
- ✅ **Research-ready outputs**: Multiple versions of analysis-ready datasets with full documentation

---

## 📁 Repository Structure

```
📦 longitudinal-survey-harmonization/
├── 📂 data/                          # All data files organized by processing stage
│   ├── 📂 raw/                       # Original survey files (.sav, .dta, .txt formats)
│   │   ├── 2002 RAE008b FINAL DATA FOR RELEASE.sav
│   │   ├── 2004 Political Survey Rev 1-6-05.sav
│   │   ├── f1171_050207 uploaded dataset.sav          # 2006 data
│   │   ├── publicreleaseNSL07_UPDATED_3.7.22.sav     # 2007 data
│   │   ├── PHCNSL2008aPublicRelease_UPDATED 3.7.22.sav
│   │   ├── PHCNSL2009PublicRelease.sav
│   │   ├── PHCNSL2010PublicRelease_UPDATED 3.7.22.sav
│   │   ├── PHCNSL2011PubRelease_UPDATED 3.7.22.sav
│   │   ├── PHCNSL2012PublicRelease_UPDATED 3.7.22.sav
│   │   ├── NSL2014_FOR RELEASE.sav
│   │   ├── NSL2015_FOR RELEASE.sav
│   │   ├── NSL 2016_FOR RELEASE.sav
│   │   ├── NSL 2018_FOR RELEASE_UPDATED 3.7.22.sav
│   │   ├── 2021 ATP W86.sav
│   │   ├── NSL 2022 complete dataset national survey of latinos 2022.dta
│   │   └── 2023ATP W138.sav
│   ├── 📂 processed/                 # Intermediate processed data
│   │   ├── 📂 cleaned_data/          # Year-by-year harmonized files
│   │   │   ├── cleaned_2002.csv
│   │   │   ├── cleaned_2004.csv
│   │   │   └── [...through 2012]
│   │   ├── 📂 cleaned_data_final/    # Final processing iterations
│   │   └── 📂 cleaned_data_corrected/# Quality-corrected versions
│   └── 📂 final/                     # Final research-ready datasets
│       ├── COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv  # 📊 MAIN DATASET (37,496+ obs)
│       ├── longitudinal_survey_data_2002_2023_COMPREHENSIVE.csv
│       └── [Additional analysis-ready versions]
├── 📂 scripts/                       # All analysis and processing scripts
│   ├── 00_master_script.R            # 🎯 Main workflow orchestrator
│   ├── 📂 01_extraction/             # Variable identification & extraction
│   │   ├── 01_variable_extraction.R
│   │   ├── 01_variable_extraction_extended.R
│   │   ├── 01_variable_extraction_robust.R
│   │   ├── 02_keyword_search.R
│   │   └── 02_keyword_search_extended.R
│   ├── 📂 02_harmonization/          # Data harmonization & combination
│   │   ├── 03_harmonization_plan.R
│   │   ├── 03_harmonization_plan_extended.R
│   │   ├── 04_data_harmonization_fixed.R      # 🔧 Main harmonization script
│   │   ├── 04_data_harmonization_ENHANCED.R
│   │   ├── 05_combine_waves_fixed.R           # 🔗 Wave combination script
│   │   └── [Additional harmonization versions...]
│   ├── 📂 03_analysis/               # Analysis scripts organized by version
│   │   ├── IMMIGRATION_ATTITUDES_ANALYSIS_v3_0_SURVEY_WEIGHTED.R  # 🎯 Latest version
│   │   └── [Previous versions for reference]
│   ├── 📂 04_diagnostics/            # Data quality and coverage diagnostics
│   ├── 📂 05_visualization/          # Visualization and figure generation scripts
│   └── 📂 06_utilities/              # Utility functions and specialized analyses
├── 📂 docs/                          # Documentation and guides
│   ├── 📂 codebooks/                 # Survey codebooks and methodologies
│   │   ├── 2002 RAE008b Additional Notes to accompany released data.docx
│   │   ├── 2004 latino political survey codebook.docx
│   │   ├── 2006 F1171col Codebook.docx
│   │   ├── 2007 PublicReleaseNSL2007Codebook&Notes_UPDATED 3.7.22.docx
│   │   ├── [Additional codebooks for 2008-2012...]
│   │   ├── 2021 National Survey of Latinos ATP W86 methodology.pdf
│   │   └── [PDF questionnaires and methodology documents...]
│   └── 📂 guides/                    # Project guides and documentation
│       ├── COMPREHENSIVE_HARMONIZATION_GUIDE.md     # 📚 Detailed technical guide
│       ├── FUTURE_HARMONIZATION_PROMPT.md           # 🎯 Actionable prompt for future work
│       ├── DATA_HARMONIZATION_FIXES_SUMMARY.md      # 📊 Complete project summary
│       ├── COMPREHENSIVE_IMMIGRATION_ATTITUDES_SUMMARY.md
│       └── Chat_History_Harmonization_Extension_2007_2012.Rmd
├── 📂 outputs/                       # Analysis outputs and summaries
│   ├── 📂 summaries/                 # Data summaries and metadata
│   │   ├── variable_summary.csv                     # 📋 Variable coverage statistics
│   │   ├── concept_summary_by_year.csv              # 📈 Concept availability by year
│   │   ├── harmonization_review_template.csv        # 🔍 Harmonization documentation
│   │   └── [Additional summary files...]
│   ├── 📂 logs/                      # Processing logs and audit trails
│   │   └── processing_log.csv                       # 📝 Processing metadata
│   └── 📂 validation/                # Quality assurance outputs
└── 📂 temp/                          # Temporary and backup files
    ├── 📂 intermediate/              # Intermediate processing files
    ├── 📂 backup/                    # Backup versions and archives
    └── [Temporary files...]
```

---

## 🚀 Quick Start Guide

### **1. Main Dataset Access**
The primary research-ready dataset is located at:
```
data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
```
- **37,496+ observations** across 2002-2023
- **40+ harmonized variables** including demographics, immigration attitudes, generation status
- **Survey weights included** for nationally representative analyses
- **Analysis-ready format** with consistent coding across all 22 years

### **2. Running the Harmonization Pipeline**
To reproduce the entire harmonization process:

```r
# Navigate to project root
setwd("/path/to/longitudinal-survey-harmonization")

# Run the complete harmonization pipeline
source("scripts/00_master_script.R")

# Or run individual components:
source("scripts/02_harmonization/04_data_harmonization_fixed.R")
source("scripts/02_harmonization/05_combine_waves_fixed.R")
```

### **3. Understanding Variable Coverage**
Check coverage statistics:
```r
# Load coverage summary
coverage <- read.csv("outputs/summaries/variable_summary.csv")
print(coverage)

# Load concept availability by year
concepts <- read.csv("outputs/summaries/concept_summary_by_year.csv")
print(concepts)
```

---

## 📊 Dataset Overview

### **Temporal Coverage**
- **2002-2023**: 14 survey waves (missing 2003, 2005, 2013, 2017, 2019, 2020)
- **Total observations**: 37,496+
- **Survey population**: Hispanic/Latino adults in the United States
- **Survey organizations**: Pew Research Center, Kaiser Family Foundation, American Trends Panel

### **Key Variables & Coverage**
| Variable | Coverage | Description |
|----------|----------|-------------|
| **age** | 83.4% | Continuous age (18-90+) + converted categorical ranges |
| **gender** | 44.0% | Interviewer-recorded gender (limited by survey design) |
| **ethnicity** | 93.3% | Hispanic subgroup heritage (Mexican, Puerto Rican, Cuban, etc.) |
| **language_home** | 64.7% | Interview language preference (English vs Spanish) |
| **race** | 23.0% | Within-Hispanic racial identity (White/Black/Asian/Indigenous Hispanic) |
| **citizenship_status** | 56.4% | U.S. citizenship status |
| **place_birth** | 70.0% | Country/place of birth (U.S. vs foreign-born) |
| **immigrant_generation** | 62.4% | Generation status (1st, 2nd, 3rd+ generation) |
| **immigration_attitude** | 83.7% | Attitudes toward immigration policy |
| **border_security_attitude** | 83.6% | Border security and enforcement attitudes |
| **political_party** | 57.3% | Political party identification |
| **vote_intention** | 28.5% | Voting intention and candidate preference |

### **Important Notes**
- **Race interpretation**: In this Hispanic-focused survey, "race" measures racial identity *within* the Hispanic population (e.g., White Hispanic, Black Hispanic), not general population race categories.
- **Gender limitation**: Gender variables are genuinely absent in some early survey years (2002, 2006) and later years (2010-2012) due to survey design decisions.
- **Missing data**: Coded as NA; legacy missing codes (8, 9, 98, 99, 999) have been standardized to NA.

---

## 🔧 Advanced Usage

### **For Researchers**
1. **Longitudinal Analysis**: Use `survey_year` for time-series analysis
2. **Cohort Studies**: Leverage `immigrant_generation` for generational comparisons  
3. **Policy Impact Analysis**: Track `immigration_attitude` and `border_security_attitude` across political periods
4. **Demographic Trends**: Analyze changes in `ethnicity`, `language_home`, and `citizenship_status` over time

### **For Data Scientists**
1. **Variable Harmonization**: Reference `docs/guides/COMPREHENSIVE_HARMONIZATION_GUIDE.md` for technical details
2. **Quality Assessment**: Use `outputs/summaries/variable_summary.csv` for coverage analysis
3. **Extension Guidelines**: Follow `docs/guides/FUTURE_HARMONIZATION_PROMPT.md` for adding new years/variables
4. **Validation Scripts**: Check `outputs/logs/processing_log.csv` for processing audit trail

---

## 📚 Documentation Guide

### **Essential Reading**
1. **`docs/guides/DATA_HARMONIZATION_FIXES_SUMMARY.md`** - Complete project overview and methodology
2. **`docs/guides/COMPREHENSIVE_HARMONIZATION_GUIDE.md`** - Technical harmonization guide
3. **`outputs/summaries/variable_summary.csv`** - Variable coverage and statistics

### **Codebooks by Year**
- **2002**: `docs/codebooks/2002 RAE008b Additional Notes to accompany released data.docx`
- **2004**: `docs/codebooks/2004 latino political survey codebook.docx`
- **2006**: `docs/codebooks/2006 F1171col Codebook.docx`
- **2007**: `docs/codebooks/2007 PublicReleaseNSL2007Codebook&Notes_UPDATED 3.7.22.docx`
- **2008-2012**: Additional codebooks in `docs/codebooks/`

### **Methodology References**
- Survey methodologies and questionnaires are available in `docs/codebooks/`
- Processing methodology detailed in `docs/guides/DATA_HARMONIZATION_FIXES_SUMMARY.md`

---

## 🤝 Contributing

### **Adding New Years**
Follow the comprehensive guide in `docs/guides/FUTURE_HARMONIZATION_PROMPT.md` for:
- Systematic variable identification
- Flexible harmonization strategies  
- Quality validation procedures

### **Analysis Scripts**
Add your analysis scripts to `scripts/03_analysis/` with clear documentation.

### **Documentation Updates**
Keep documentation current when making significant changes to data or methods.

---

## 📈 Research Applications

This dataset enables research on:

### **Temporal Analysis (2002-2012)**
- Immigration attitude evolution during Bush and early Obama administrations
- Political participation changes across economic recession (2008-2010)
- Demographic transitions within Latino communities
- Pre-DACA period baseline attitudes (2002-2011)

### **Cross-Sectional Analysis**
- Generational differences in political views using `immigrant_generation`
- Language preferences and political attitudes via `language_home`
- Citizenship status effects on political participation using `citizenship_status`
- Within-Hispanic racial identity patterns via `race`

### **Policy Period Comparisons**
- **Bush era** (2002-2008): Immigration enforcement attitudes
- **Obama early years** (2009-2012): Immigration reform expectations
- **Economic impact** (2008-2010): Recession effects on immigration attitudes

---

## ⚠️ Important Considerations

### **Survey Design Limitations**
- **Gender data**: Limited availability due to survey design evolution
- **Race data**: Context-specific (within-Hispanic identity), available primarily 2009-2011
- **Political variables**: Coverage varies by electoral cycles

### **Data Quality Notes**  
- All missing value codes have been standardized to NA
- Age ranges have been converted to midpoint estimates where necessary
- Variable harmonization decisions are documented in `outputs/summaries/harmonization_review_template.csv`

### **Citation**
When using this dataset, please cite the original survey sources (detailed in individual codebooks) and acknowledge the harmonization methodology developed in this project.

---

## 📞 Support

For questions about:
- **Data structure**: See `docs/guides/DATA_HARMONIZATION_FIXES_SUMMARY.md`
- **Variable definitions**: Check individual codebooks in `docs/codebooks/`
- **Harmonization methods**: Reference `docs/guides/COMPREHENSIVE_HARMONIZATION_GUIDE.md`
- **Adding new data**: Follow `docs/guides/FUTURE_HARMONIZATION_PROMPT.md`

---

**Last Updated**: August 2025  
**Dataset Version**: v3.0 (2002-2023 Complete)  
**Total Observations**: 37,496+ across 14 survey years  
**Project Created**: July 2025
