# VERSION MAPPING: v4.x and v5.x Assets
Date: 2025-08-08

This document catalogs v4.x and v5.x series files and their current status. These are retained for provenance and comparison, but analytical claims should default to the latest v2.9w+ enhanced analysis unless otherwise noted.

## Repository Roots Referenced
- Current workspace: `NSL-2002-2023/` (this repo)
- Secondary path with additional v4/v5 artifacts:
  `"/Users/ajiang/Documents/Research/Immigrants against Immigrants?/NSL Project/NSL-2002-2023"`

## v4.x Assets (Secondary path)
- Docs (reports/handouts)
  - `docs/reports/ENHANCED_LONGITUDINAL_ANALYSIS_INTERPRETATION_v4_0.md` (legacy interpretation)
  - `docs/reports/ALTERNATIVE_MEASUREMENT_MODELS_FINDINGS_v4_2.md` (legacy alt models)
  - `docs/reports/DISAGGREGATED_ANALYSIS_FINDINGS_v4_3.md` (source of cross-sectional variability claim)
  - `docs/conference/CONFERENCE_HANDOUT_HIERARCHICAL_v5.md` (see v5.x below; kept here for reference)

- Scripts (analysis/visualization)
  - `scripts/03_analysis/ENHANCED_LONGITUDINAL_ANALYSIS_v4_0.R`
  - `scripts/03_analysis/ENHANCED_LONGITUDINAL_ANALYSIS_v4_0_SIMPLE.R`
  - `scripts/03_analysis/ALTERNATIVE_MEASUREMENT_MODELS_v4_2.R`
  - `scripts/03_analysis/ALTERNATIVE_MEASUREMENT_MODELS_v4_2_ROBUST.R`
  - `scripts/03_analysis/DISAGGREGATED_SUBVARIABLE_ANALYSIS_v4_3*.R`
  - `scripts/05_visualization/ADVANCED_VISUALIZATIONS_v4_0*.R`
  - `scripts/05_visualization/ENHANCED_VISUALIZATIONS_MAGNIFIED_v4_1.R`
  - `scripts/05_visualization/PUBLICATION_QUALITY_VISUALIZATIONS_v4_4.R`

- Outputs (figures/data)
  - `outputs/overall_trends_v4_0.csv`
  - `outputs/generation_year_trends_v4_0.csv`
  - `outputs/period_effects_v4_0.csv`
  - `outputs/regression_results_v4_0.csv`
  - `outputs/divergence_analysis_v4_3.csv`
  - `outputs/disaggregated_trends_v4_3.csv`
  - `outputs/heterogeneity_by_category_v4_3.csv`
  - Figures (examples):
    - `outputs/figure_v4_0_main_generation_trends.png`
    - `outputs/figure_v4_1_magnified_generation_trends.png`
    - `outputs/figure_v4_2_dimensions_scatter_robust.png`
    - `outputs/figure_v4_3_key_contrasts.png`
    - `outputs/figure_v4_4_main_generation_trends.png`

Status/guidance:
- v4.x results are pre-correction and may reflect the misinterpretation (2nd gen “volatile”).
- Use for historical comparison only. Do not cite v4.x volatility claims without cross-checking v2.9w+.

## v5.x Assets (Secondary path)
- Docs
  - `docs/conference/CONFERENCE_HANDOUT_HIERARCHICAL_v5.md` (draft handout text in v5 series)

Status/guidance:
- v5.x documents mixed corrected and uncorrected narratives during transition.
- Prefer the August 2025 corrected LaTeX sections in `current/docs/CURRENT_2025_08_08_LATEX_corrections.tex`.

## Cross-Series Guidance
- Volatility interpretation:
  - Legacy v4.x/v5.x docs may conflate cross-sectional variability with temporal volatility. The corrected standard is variance of yearly means (v2.9w+).
- Statistical baselines:
  - Prefer v2.9w+ trend/interactions/mixed-effects for current claims.
- Provenance:
  - Keep v4.x/v5.x for methodological history; mark “legacy” in presentations if used for context.

## Pointers to Current (Authoritative) Materials
- Latest figures: `current/outputs/CURRENT_2025_08_08_FIGURES_conference/*`
- Corrected LaTeX sections: `current/docs/CURRENT_2025_08_08_LATEX_corrections.tex`
- Latest trends/mixed-effects data: `outputs/v2_9w_plus_*.csv`

## Actionable Notes
- If a v4.x/v5.x figure is needed for narrative contrast, accompany with a “Legacy (pre-correction)” label and a corrected counterpart from v2.9w+.
- If any v4.x/v5.x file is updated, add a dated “CURRENT_YYYY_MM_DD_*” counterpart rather than renaming the original.
