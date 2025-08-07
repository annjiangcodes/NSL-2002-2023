# LaTeX Handout Compilation Instructions

## Files Created
- `CONFERENCE_HANDOUT_HIERARCHICAL_v5.tex` - Main LaTeX document
- `CONFERENCE_HANDOUT_HIERARCHICAL_v5.md` - Original markdown version

## Compilation Options

### Option 1: Local LaTeX Installation
If you have LaTeX installed locally:
```bash
cd /Users/ajiang/Documents/NSL/NSL-2002-2023/docs/conference
pdflatex CONFERENCE_HANDOUT_HIERARCHICAL_v5.tex
pdflatex CONFERENCE_HANDOUT_HIERARCHICAL_v5.tex  # Run twice for cross-references
```

### Option 2: Overleaf (Recommended)
1. Go to [Overleaf.com](https://www.overleaf.com)
2. Create a new project and upload the `.tex` file
3. Upload all referenced figures from `../../outputs/` to the project:
   - `figure_v4_4_main_generation_trends.png`
   - `figure_v4_4_generation_gap.png`
   - `figure_v4_4_disaggregated_components.png`
   - `figure_v4_4_net_liberalism.png`
   - `figure_v4_4_period_effects.png`
   - `figure_v4_2_dimensions_scatter_robust.png`
4. Adjust image paths in the `.tex` file to match Overleaf structure
5. Compile to PDF

### Option 3: Install LaTeX on macOS
```bash
# Install MacTeX distribution
brew install --cask mactex
# or download from: https://www.tug.org/mactex/
```

## Document Features
- Hierarchical bullet point structure
- Professional formatting with proper sectioning
- Embedded visualizations (6 key figures)
- Hyperlinked references and URLs
- Conference-ready layout with headers
- Mathematical notation support
- Publication-quality formatting

## Figure Requirements
The document references figures in the `outputs` directory. Ensure these files exist:
- `figure_v4_4_main_generation_trends.png`
- `figure_v4_4_generation_gap.png` 
- `figure_v4_4_disaggregated_components.png`
- `figure_v4_4_net_liberalism.png`
- `figure_v4_4_period_effects_CORRECTED.png` (Updated: Fixed color coding issue)
- `figure_v4_2_dimensions_scatter_robust.png`

## Recent Updates
- **Period Effects Visualization Fixed**: The original `figure_v4_4_period_effects.png` had incorrect color coding where increases were marked red regardless of whether they were pro-immigration or anti-immigration increases. The corrected version `figure_v4_4_period_effects_CORRECTED.png` properly shows:
  - Green colors for liberalism/pro-immigration changes
  - Red colors for restrictionism/anti-immigration changes
  - Color intensity reflects magnitude and direction of change

## Customization
- Page margins: 1 inch (configurable in `\usepackage[margin=1in]{geometry}`)
- Font size: 11pt (configurable in `\documentclass[11pt,letterpaper]{article}`)
- List formatting: Customized with bullet points, circles, and dashes
- Headers: "ASA 2025" and "Jiang | Immigrants Against Immigrants?"
