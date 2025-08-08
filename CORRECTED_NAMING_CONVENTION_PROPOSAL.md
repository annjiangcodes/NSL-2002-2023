# CORRECTED NAMING CONVENTION PROPOSAL FOR NSL PROJECT

## Current Date: August 8, 2025

## Revised Approach: Preserve + Enhance (Not Replace)

### Problem with Previous Approach:
- Used wrong date (January 2025 instead of August 2025)
- Proposed replacing valuable version history (v2.8, v2.9w, etc.)
- Lost important methodological provenance

### Better Solution: Dual Naming System

#### Keep Original Versions + Add Date-Current System

### Format: `{ORIGINAL_NAME}` + `{CURRENT_DATE_VERSION}`

#### For Active Development (Latest/Current Files):
- `CURRENT_2025_08_08_{TYPE}_{DESCRIPTION}.{ext}`
- `LATEST_{TYPE}_{DESCRIPTION}.{ext}` (symlinks)

#### For Historical Preservation:
- Keep all original names: `COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv`
- Keep all version history: `ANALYSIS_v2_9w_WEIGHTED.R`, `v2_9c_coverage_summary.csv`

### Examples:

#### Current Master Files (What to use for ongoing work):
```
CURRENT_2025_08_08_DATA_comprehensive_immigration_attitudes.csv
CURRENT_2025_08_08_ANALYSIS_enhanced_weighted_master.R
CURRENT_2025_08_08_REPORT_analysis_summary.md

# With symlinks for easy access:
LATEST_DATA_master.csv -> CURRENT_2025_08_08_DATA_comprehensive_immigration_attitudes.csv
LATEST_ANALYSIS_master.R -> CURRENT_2025_08_08_ANALYSIS_enhanced_weighted_master.R
```

#### Historical Files (Preserved exactly as is):
```
data/final/COMPREHENSIVE_IMMIGRATION_DATASET_v2_7.csv                    ← Keep!
scripts/03_analysis/ENHANCED_WEIGHTED_ANALYSIS_v2_9w_PLUS.R             ← Keep!
outputs/v2_9w_plus_trend_results.csv                                    ← Keep!
docs/reports/BUG_FIX_AND_MAXIMUM_COVERAGE_SUMMARY_v2_9c.md             ← Keep!
```

### Directory Structure:
```
current/           <- Active development files (dated 2025_08_08)
  data/
  scripts/
  docs/
  outputs/
latest/           <- Symlinks to current versions for easy access
  master_data.csv
  master_analysis.R
  master_report.md
archive/          <- Historical versions (keep original names!)
  v2_7/
  v2_8/
  v2_9/
  v2_9w/
  v2_9c/
  v5_0/
[original structure preserved]
```

### Benefits:
- ✅ Preserves all version history and naming
- ✅ Clear current/latest versions for active work
- ✅ Uses correct date (August 8, 2025)
- ✅ Maintains methodological provenance
- ✅ Easy for future researchers to find current vs historical

### Implementation:
1. **Don't rename existing files** - keep all original version names
2. **Create current/ directory** with today's dated versions
3. **Create latest/ symlinks** for easy access to current files
4. **Organize archive/** by version folders but keep original names
5. **Document the mapping** in VERSION_MAPPING.md

## Corrected Migration Strategy

### Phase 1: Identify Current Best (without renaming)
- Map which original files are current authoritative versions
- Document the evolution path (v2.7 → v2.8 → v2.9w → current)

### Phase 2: Create Current/Latest Structure
- Copy best versions to `current/` with August 8, 2025 naming
- Create `latest/` symlinks for easy access
- Preserve all original files in place

### Phase 3: Documentation
- `VERSION_MAPPING.md` - Shows relationship between versions
- `CURRENT_STATUS.md` - Points to latest authoritative files
- `RESEARCH_TIMELINE.md` - Chronicles the evolution

This preserves the valuable research history while making current work clear.
