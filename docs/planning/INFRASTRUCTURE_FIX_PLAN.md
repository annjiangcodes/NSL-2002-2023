# 🔧 Infrastructure Fix Plan - Priority 1

## Critical File Path Issues

### Problem 1: Master Script Path Mismatches
**Current Issue**: `scripts/00_master_script.R` sources incorrect paths
- Sources: `"01_variable_extraction.R"`
- Should be: `"scripts/01_extraction/01_variable_extraction_robust.R"`

### Problem 2: Data File Path Mismatches  
**Current Issue**: Harmonization scripts look for data files in wrong locations
- Scripts expect: `"2002 RAE008b FINAL DATA FOR RELEASE.sav"`
- Files actually at: `"data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav"`

### Problem 3: Working Directory Assumptions
**Current Issue**: Scripts assume execution from project root with specific relative paths

## Immediate Fixes Needed

### Fix 1: Create Updated Master Script
```r
# Updated file paths for current structure
source("scripts/01_extraction/01_variable_extraction_robust.R")
source("scripts/01_extraction/02_keyword_search.R") 
source("scripts/02_harmonization/03_harmonization_plan.R")
source("scripts/02_harmonization/04_data_harmonization_fixed.R")
source("scripts/02_harmonization/05_combine_waves_fixed.R")
```

### Fix 2: Update Data File Mappings
All harmonization scripts need updated file mappings:
```r
file_mappings <- list(
  "2002" = "data/raw/2002 RAE008b FINAL DATA FOR RELEASE.sav",
  "2004" = "data/raw/2004 Political Survey Rev 1-6-05.sav",
  "2006" = "data/raw/f1171_050207 uploaded dataset.sav",
  "2007" = "data/raw/publicreleaseNSL07_UPDATED_3.7.22.sav",
  # ... continue for all years
)
```

### Fix 3: Generation Derivation Issues
Years with 0% generation coverage need investigation:
- 2008, 2009, 2011, 2015, 2018, 2023
- Check if parent nativity variables exist in these years
- Verify Portes framework implementation

## Test Strategy
1. Fix file paths in one script at a time
2. Test with small subset (2002-2004) first
3. Verify generation derivation works for problematic years
4. Run full pipeline once core issues resolved

## Success Metrics
- All data files successfully loaded
- Generation coverage >90% for all years with parent nativity data
- Immigration indices coverage >80%
- Complete end-to-end pipeline execution