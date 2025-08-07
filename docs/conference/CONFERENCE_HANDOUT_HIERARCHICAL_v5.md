# Immigrants Against Immigrants? Mapping Generational Trends in Anti-Immigration Attitudes among U.S. Hispanics, 2002–2023

**Ann Jiang, UC San Diego** | annjiang@ucsd.edu | [github.com/annjiangcodes](https://github.com/annjiangcodes)

---

## I. Central Puzzle & Research Questions

### Motivation

- **Media narratives**: Growing Hispanic support for restrictionist candidates
- **Electoral data**: Latino Trump vote share increased 2016→2020  
- **Theoretical puzzle**: Why would immigrants support anti-immigration policies?

### Core Research Question

**Puzzle:** Why do some Hispanic immigrants, who have benefited from immigration, support restrictionist immigration policies? This contradicts simple group solidarity theories and aligns with growing media narratives of a conservative shift.

### Specific Research Questions

1. **Prevalence:** How common are restrictionist views among U.S. Hispanics?
2. **Trends:** How have these attitudes changed over the last 20 years?
3. **Generations:** How do attitudes differ between 1st, 2nd, and 3rd+ generation Hispanics?
4. **Mechanisms:** What explains these differences?

---

## II. Data & Methodology

### Data Source

**Pew Research Center's National Survey of Latinos (NSL)**

- **Scope:** 14 survey waves from 2002–2023  
- **Sample:** 37,496 respondents across 21 years
- **Coverage:** 4 presidential administrations (Bush, Obama, Trump, Biden)
- **Survey weights:** Integrated for 10 out of 14 years (71% coverage)
- **Generation recovery:** v3.1 enhancement recovered ~6,200 additional observations

### Methodological Innovation: Moving Beyond Single "Pro/Anti" Scale

**Initial Problem:** Single-index approach masked crucial differences in attitudes.

**Solution:** Three distinct indices constructed to capture attitude complexity:

1. **Immigration Policy Liberalism** 
   - Components: Support for legalization, DACA support
   - Coverage: 8+ years, 61% of observations
   - Interpretation: Higher = more liberal immigration policies

2. **Immigration Policy Restrictionism**
   - Components: Border wall support, deportation policy support, "too many immigrants"  
   - Coverage: 9+ years, 64% of observations
   - Interpretation: Higher = more restrictionist immigration policies

3. **Deportation Concern**
   - Components: Personal deportation worry
   - Coverage: 4+ years, 22% of observations
   - Interpretation: Higher = greater deportation concerns

### Analytical Approach

- **Longitudinal design:** Fixed-effects on survey year
- **Generation stratification:** Portes framework implementation
- **Survey weighting:** Representative population estimates
- **Statistical testing:** Linear regression with robust standard errors
- **Missing data:** Complete case analysis (16,327 cases, 43.5%)

### Generational Coding

- **1st Generation:** Foreign-born
- **2nd Generation:** U.S.-born, at least one foreign-born parent  
- **3rd+ Generation:** U.S.-born, U.S.-born parents

*Figure: Two dimensions capture different aspects of immigration attitudes* (Available as `figure_v4_2_dimensions_scatter_robust.png`)

---

## III. Key Findings

### A. The Illusion of Stability

Across the total Hispanic population, aggregate attitudes on immigration appear **remarkably stable** over 20 years. However, **this stability masks significant and diverging trends between immigrant generations.**

### B. Generational Divergence (Core Finding)

#### Statistical Evidence (Survey-Weighted v2.8)

**First Generation:**
- **Liberalism:** +0.019 per year (p=0.021*)  
- **Restrictionism:** +0.011 per year (p=0.004**)
- **Pattern:** Becoming simultaneously **more liberal AND more restrictionist**

**Second Generation:**  
- **Liberalism:** -0.005 per year (p=0.488, ns)
- **Restrictionism:** -0.015 per year (p=0.056, ns)
- **Pattern:** Attitudes **converging toward the middle**

**Third+ Generation:**
- **Liberalism:** -0.016 per year (p=0.158, ns)  
- **Restrictionism:** -0.002 per year (p=0.908, ns)
- **Pattern:** Remain **most consistently restrictionist**, stable over time

*Figure: Generational Trends in U.S. Hispanic Immigration Attitudes (2002-2023)* (Available as `figure_v4_4_main_generation_trends.png`)

### C. The "Border Wall Paradox" (Disaggregated Analysis Discovery)

Looking at individual policy components reveals dynamics hidden by aggregate indices:

**Border Wall Support:**
- **1st Generation:** Support **decreased** over time
- **2nd Generation:** Support **increased** over time  
- **3rd+ Generation:** Support remains **stably high**

**Key insight:** This finding directly contradicts linear assimilation theories and demonstrates that border wall attitudes are distinct from other enforcement measures (correlation with border security: r = -0.44).

#### Heterogeneity Within Indices

- Variables within same index don't always correlate
- **Enforcement attitudes are NOT monolithic** - different measures elicit different responses
- Immigration attitudes contain distinct modules:
  - Humanitarian concerns (DACA, legalization)
  - Security/enforcement preferences  
  - Personal threat perception
  - Symbolic concerns (border wall)

*Figure: Disaggregated Immigration Attitude Components* (Available as `figure_v4_4_disaggregated_components.png`)

### D. The Power of Context: Period Effects

Attitudes are shaped by political moments:

- **Trump Era (2016-18):** Triggered "defensive liberalization" among 1st generation immigrants
- **Economic Crisis (2008-10):** All generations became temporarily more restrictionist  
- **Obama Era:** Peak liberalism for 1st/2nd generation

**Key Period × Generation Interactions:**
- Trump Era: 1st generation defensive liberalization
- Economic Crisis: All generations more restrictive
- Obama Era: Peak liberalism for 1st/2nd generation

*Figure: Net Immigration Policy Attitudes by Generation* (Available as `figure_v4_4_net_liberalism.png`)

*Figure: The Generation Gap: First vs Third+ Generation Differences* (Available as `figure_v4_4_generation_gap.png`)

---

## IV. Central Argument: The Paradox Isn't a Paradox

### Theoretical Reframing

The phenomenon of "immigrants against immigrants" is **not** hypocrisy or false consciousness. It represents the **logical outcome of political assimilation** into a polarized American society.

### Mechanisms

1. **Identity Signaling:** "We are different from new immigrants"
2. **Resource Competition:** Economic/social resource concerns  
3. **Assimilation Pressure:** Proving American belonging
4. **Political Integration:** Adopting American political divisions

### Attitude Structure Complexity

**Immigration attitudes are genuinely multidimensional:**
- Can support legalization AND enforcement
- Can oppose border wall but support deportation  
- Personal concern ≠ policy preferences
- Humanitarian and security concerns can coexist

---

## V. Theoretical & Political Implications

### A. Assimilation Theory Implications

#### Classical Assimilation: Partial Support
- 3rd+ generation most "American" in attitudes
- But process isn't linear across all dimensions

#### Segmented Assimilation: Strong Support  
- Multiple pathways evident across generations
- 2nd generation shows highest variance and complexity

#### Reactive Ethnicity: Confirmed
- 1st generation mobilizes during threat periods
- Defensive response to Trump-era rhetoric
- Context-dependent attitude shifts

### B. Political Implications

**For Electoral Politics:**
- The "Latino vote" is not monolithic
- Political messaging must be segmented by generation
- Generational replacement will shift baseline attitudes

**For Policy:**
- Support for enforcement ≠ being "anti-immigrant"
- Many individuals hold coexisting humanitarian and security concerns
- Policy frameworks must account for attitude complexity

### C. Methodological Implications

**For Immigration Research:**
- Single indices mask crucial variation
- Disaggregated analysis essential for understanding
- Temporal analysis required for immigration scholarship
- Survey weights critical for representative findings

---

## VI. The "Immigrants Against Immigrants" Phenomenon

### Not a Paradox: A Logical Outcome

**Integration Process:**
- Adoption of American political divisions
- Generational distancing from immigrant identity  
- Intragroup boundary-making processes

**Contextual Factors:**
- Period-specific political pressures
- Border security discourse effects
- Economic competition narratives

**Identity Negotiation:**
- 1st Generation: Pragmatic - support pathways AND enforcement
- 2nd Generation: Reactive - responds to political climate
- 3rd+ Generation: Selective - adopts mainstream views differentially

---

## VII. Data Quality & Methodological Strengths

### Publication-Quality Standards

- **Temporal Coverage:** 21 years across 4 presidential administrations
- **Sample Size:** 37,496+ observations with generation recovery enhancement
- **Representative Sampling:** Pew Research Center's rigorous methodology  
- **Survey Weights:** Population-representative estimates
- **Missing Data Analysis:** Comprehensive assessment (59.12% overall missing, within normal range)
- **Statistical Rigor:** Robust standard errors, sensitivity analysis

### Generation Recovery Enhancement (v3.1)

- **Problem:** Years 2008, 2009, 2015, 2018 had 0% generation coverage
- **Solution:** Variable mapping correction recovered ~6,200 observations
- **Impact:** Increased generation coverage from 60% to 75%+
- **Result:** Enhanced statistical power and temporal representation

---

## VIII. Conclusion: A Story of Political Incorporation

### Central Finding

"Immigrants against immigrants" reflects **successful political assimilation**, not betrayal or false consciousness. It reveals how group boundaries shift across generations as populations integrate into polarized American political landscape.

### Methodological Lesson

- **Aggregation obscures reality** - single indices hide crucial variation
- **Fragmented attitudes require nuanced measurement**
- **Temporal analysis essential** for immigration scholarship
- **Survey weights critical** for representative population-level findings

### Broader Implications

1. **Political incorporation involves adopting societal divisions**
2. **Generational replacement will continue shifting baseline attitudes** 
3. **Immigration attitudes contain multiple, distinct dimensions**
4. **Support exists for both humanitarian AND enforcement approaches**

### Future Research Directions

1. **Qualitative follow-up:** Understanding mechanisms behind border wall attitudes
2. **Experimental studies:** Testing framing effects on different measures
3. **Regional analysis:** Geographic variation in generational patterns
4. **Comparative perspective:** Including non-Hispanic populations

---

## Technical Appendix

### Key Output Files

- **Statistical Results:** `generation_weighted_trends_v2_8.csv`
- **Population Estimates:** `weighted_year_means_v2_8.csv`  
- **Data Quality Metrics:** `missing_data_by_variable_v2_8.csv`
- **Generation Recovery Analysis:** `generation_coding_test_results_corrected.csv`

### Visualization Portfolio

- **Main Trends:** `figure_v4_4_main_generation_trends.png`
- **Disaggregated Components:** `figure_v4_4_disaggregated_components.png`  
- **Net Attitudes:** `figure_v4_4_net_liberalism.png`
- **Generation Gap:** `figure_v4_4_generation_gap.png`
- **Period Effects:** `figure_v4_4_period_effects.png`

### Analysis Scripts

- **Core Analysis:** `IMMIGRATION_ATTITUDES_ANALYSIS_v2_8_WEIGHTS_CONTROLS_SIMPLIFIED.R`
- **Generation Recovery:** `IMMIGRATION_ATTITUDES_ANALYSIS_v3_1_GENERATION_RECOVERY.R`
- **Disaggregated Analysis:** `DISAGGREGATED_ANALYSIS_v4_3_COMPONENTS.R`
- **Visualization:** `PUBLICATION_QUALITY_VISUALIZATIONS_v4_4.R`

---

**Analysis Version:** v2.8 (Survey-weighted) + v3.1 (Generation recovery) + v4.4 (Publication visualizations)  
**Status:** Publication-ready  
**Date:** January 2025