# PROPOSED NAMING CONVENTION FOR NSL PROJECT

## Current Problem
- Version numbers (v2.8, v2.9w, v2.9c, v2.9w_plus) are confusing
- No clear indication of what's the "latest" or most authoritative
- Hard for future researchers to know which files to use
- Multiple "generation recovery" and "corrected" versions create confusion

## Proposed Solution: Date-Based Naming with Type Prefixes

### Format: `{TYPE}_{YYYY_MM_DD}_{DESCRIPTION}.{ext}`

### Type Prefixes:
- `DATA_` - Final processed datasets ready for analysis
- `ANALYSIS_` - Main analysis scripts  
- `VIZ_` - Visualization/plotting scripts
- `UTIL_` - Utility/helper scripts
- `REPORT_` - Documentation and reports

### Examples:

#### Data Files:
```
DATA_2025_01_15_comprehensive_immigration_attitudes.csv  (latest master dataset)
DATA_2025_01_15_generation_trends_weighted.csv         (latest trend results)
DATA_2025_01_10_comprehensive_immigration_attitudes.csv  (previous version)
```

#### Analysis Scripts:
```
ANALYSIS_2025_01_15_generational_trends_master.R       (latest main analysis)
ANALYSIS_2025_01_15_mixed_effects_weighted.R          (latest advanced analysis)
ANALYSIS_2025_01_10_generational_trends_master.R       (previous version)
```

#### Visualization Scripts:
```
VIZ_2025_01_15_publication_figures.R                   (latest publication plots)
VIZ_2025_01_15_conference_presentation.R              (latest conference plots)
```

#### Reports:
```
REPORT_2025_01_15_analysis_summary.md                  (latest findings summary)
REPORT_2025_01_15_methodology_notes.md                (latest methods documentation)
```

### Directory Structure:
```
data/
  latest/          <- Symlinks to latest versions
  archive/         <- All dated versions
scripts/
  latest/          <- Symlinks to latest versions  
  archive/         <- All dated versions
docs/
  latest/          <- Symlinks to latest versions
  archive/         <- All dated versions
outputs/
  latest/          <- Symlinks to latest versions
  YYYY_MM_DD/      <- Dated output folders
```

### Special Files:
- `LATEST_VERSION.txt` - Contains date of current authoritative version
- `VERSION_HISTORY.md` - Log of major changes by date
- `README_CURRENT.md` - Always points to latest analysis status

## Migration Plan

### Phase 1: Identify Current "Best" Versions
1. Determine the most authoritative current data file
2. Identify the best current analysis script
3. Document what each current file contains

### Phase 2: Rename and Reorganize
1. Rename best current files with today's date (2025-01-15)
2. Move older versions to archive folders
3. Create symlinks in "latest" folders
4. Update all script paths to use latest/ symlinks

### Phase 3: Update Documentation
1. Create VERSION_HISTORY.md documenting the migration
2. Update README with new naming convention
3. Create LATEST_VERSION.txt

## Benefits
- ✅ Clear chronological ordering
- ✅ Easy to identify latest version
- ✅ Preserves full history in archive
- ✅ Type prefixes make purpose clear  
- ✅ Consistent across all file types
- ✅ Future-proof for ongoing work
- ✅ Works well with version control

## Implementation Example

Current messy state:
```
COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv
generation_trends_CORRECTED_v5_0.csv  
ANALYSIS_v2_9w_WEIGHTED.R
ENHANCED_WEIGHTED_ANALYSIS_v2_9w_PLUS.R
```

After migration:
```
data/latest/comprehensive_immigration_attitudes.csv -> ../archive/DATA_2025_01_15_comprehensive_immigration_attitudes.csv
data/latest/generation_trends_weighted.csv -> ../archive/DATA_2025_01_15_generation_trends_weighted.csv  
scripts/latest/generational_trends_master.R -> ../archive/ANALYSIS_2025_01_15_generational_trends_master.R
scripts/latest/mixed_effects_weighted.R -> ../archive/ANALYSIS_2025_01_15_mixed_effects_weighted.R
```

## Adoption Strategy
1. Start with new naming for all future work
2. Gradually migrate existing files when updating them
3. Maintain backwards compatibility during transition
4. Full migration by end of current analysis phase
