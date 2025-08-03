# File Organization Plan

## Overview
This plan organizes single files into existing folders without changing the overall structure. Files will be moved based on their function and type.

## Proposed Organization

### Root Directory (Keep)
- README.md (project overview)
- LICENSE (legal requirements)
- mini-report-on-NSL-2018/ (complete subdirectory)

### scripts/ (Move analysis scripts here)
#### scripts/03_analysis/
- ANALYSIS_v2_0_DATA_INVESTIGATION.R
- ANALYSIS_v2_1_CORRECTED_HARMONIZATION.R
- ANALYSIS_v2_1_FIXED_FILEPATHS.R
- ANALYSIS_v2_2_COMPLETE_GENERATION_FIX.R
- ANALYSIS_v2_3_PROPER_GENERATION_DERIVATION.R
- ANALYSIS_v2_4_COMPLETE_GENERATION_CLEANUP.R
- ANALYSIS_v2_6_COMPREHENSIVE_FIXED.R
- ANALYSIS_v2_6_COMPREHENSIVE.R
- ANALYSIS_v2_6_CORRECTED.R
- ANALYSIS_v2_6_GENERATION_FIXED.R
- IMMIGRATION_ATTITUDES_ANALYSIS_v2_7_COMPREHENSIVE.R
- IMMIGRATION_ATTITUDES_ANALYSIS_v2_8_WEIGHTS_CONTROLS_SIMPLIFIED.R
- IMMIGRATION_ATTITUDES_ANALYSIS_v2_8_WEIGHTS_CONTROLS.R
- IMMIGRATION_ATTITUDES_ANALYSIS_v3_0_MAXIMUM_DATA.R
- IMMIGRATION_ATTITUDES_ANALYSIS_v3_0_SURVEY_WEIGHTED.R
- LONGITUDINAL_ANALYSIS_v2_4.R

#### scripts/04_diagnostics/
- DIAGNOSTIC_v2_1_GENERATION_COVERAGE.R
- DIAGNOSTIC_v2_6_DATA_COVERAGE.R
- TRAJECTORY_DIAGNOSTIC_v2_5.R
- MISSING_DATA_ANALYSIS_v2_8_BASIC.R
- MISSING_DATA_ANALYSIS_v2_8.R

#### scripts/05_visualization/
- create_trend_visualization.R
- PUBLICATION_VISUALIZATION_v2_9.R
- PUBLICATION_VISUALIZATION_v3_0.R

#### scripts/06_utilities/
- assess_measurement_robustness.R
- investigate_political_contradiction.R
- preliminary_generational_analysis.R

### docs/ (Move documentation here)
#### docs/methodology/
- COMPREHENSIVE_DATASET_ROADMAP.md
- COMPREHENSIVE_HARMONIZATION_GUIDE.md
- HARMONIZATION_DECISIONS_DOCUMENTATION.md
- FINAL_METHODOLOGICAL_REVIEW_v2_8.md

#### docs/reports/
- LONGITUDINAL_ANALYSIS_v2_6_REPORT.md
- PRELIMINARY_GENERATIONAL_FINDINGS_SUMMARY.md
- NSL_v3_0_COMPREHENSIVE_SYSTEM_REVIEW.md
- NSL_v3_0_GENERATION_DATA_RECOVERY_SUCCESS.md
- NSL_v3_0_PHASE_1_COMPLETION_SUMMARY.md

#### docs/planning/
- EXTENSION_PLAN_2013_2023.md
- IMMEDIATE_FIX_PLAN.md
- INFRASTRUCTURE_FIX_PLAN.md
- REPOSITORY_REORGANIZATION_PLAN.md
- WORK_ESTIMATION_CONFERENCE_JOURNAL.md
- SOCIOECONOMIC_GEOGRAPHIC_ENHANCEMENT_SUMMARY.md

### outputs/ (Move output files here)
- immigration_attitudes_by_generation_trend.png
- v3_0_analysis_output.log

## Implementation Steps

1. **Create new subdirectories**:
   - scripts/03_analysis/
   - scripts/04_diagnostics/
   - scripts/05_visualization/
   - scripts/06_utilities/
   - docs/methodology/
   - docs/reports/
   - docs/planning/

2. **Move files** according to the plan above

3. **Update references** in scripts if any use relative paths

4. **Update README.md** to reflect new organization

## Benefits

1. **Clearer navigation**: Related files grouped together
2. **Reduced clutter**: Root directory only contains essential files
3. **Logical hierarchy**: Scripts organized by function
4. **Better documentation structure**: Docs organized by type
5. **Maintained continuity**: Existing folder structure preserved

## Files Not Moved

- data/ (already well-organized)
- outputs/summaries/ (already organized)
- outputs/logs/ (already organized)
- temp/ (temporary files, leave as is)
- mini-report-on-NSL-2018/ (complete subdirectory, leave as is)