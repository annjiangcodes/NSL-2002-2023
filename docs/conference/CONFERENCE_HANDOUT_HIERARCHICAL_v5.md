# Immigrants Against Immigrants?
**Mapping Generational Trends in Anti-Immigration Attitudes among U.S. Hispanics, 2002–2023**

Ann Jiang, UC San Diego | annjiang@ucsd.edu

---

## I. MOTIVATION & PUZZLE

• **Core Observation**
  - Media narratives: Growing Hispanic support for restrictionist candidates
  - Electoral data: Latino Trump vote share increased 2016→2020
  - Theoretical puzzle: Why would immigrants support anti-immigration policies?

• **Research Questions**
  - **Prevalence**: How common are restrictionist attitudes among Hispanic immigrants?
  - **Temporal**: How have these attitudes evolved 2002-2023?
  - **Generational**: Do patterns differ by immigrant generation?
  - **Mechanisms**: What explains variation in attitudes?

---

## II. DATA & METHODOLOGICAL DECISIONS

### A. Data Foundation
• **Source**: National Survey of Latinos (NSL/Pew Research)
  - 14 survey waves: 2002-2023
  - N = 37,496 Hispanic respondents
  - Repeated cross-sectional design (not panel)

• **Key Analytical Decisions**
  - **v2.7**: Corrected generation coding using Portes framework
  - **v2.8**: Added survey weights (71% coverage)
  - **v3.0**: Maximum data utilization approach
  - **v4.0**: Enhanced temporal analysis with period effects
  - **v4.3**: Disaggregated subvariable analysis

### B. Variable Construction Evolution

• **Initial Approach (v2.0-v2.6): Single Index**
  - Combined all immigration items into one scale
  - Problem: Masked important heterogeneity

• **Three-Index Approach (v2.7+)**
  - **Immigration Policy Liberalism**
    * Components: legalization support, DACA support
    * Coverage: 61% of observations, 8 years
  - **Immigration Policy Restrictionism**
    * Components: border wall, deportation, "too many immigrants"
    * Coverage: 64% of observations, 9 years
  - **Deportation Concern**
    * Components: personal worry about deportation
    * Coverage: 22% of observations, 4 years

• **Alternative Indices Tested (v4.2)**
  - **Enforcement Index**: deportation, border security, wall
  - **General Attitudes**: legalization, DACA, immigration levels
  - Finding: High correlation with original indices (r > 0.93)

• **Disaggregated Analysis (v4.3-v4.4)**
  - Examined each subvariable independently
  - Key discovery: Subvariables don't always move together

### C. Generation Coding Decisions

• **Original Problem**: Inconsistent nativity/generation variables across years

• **Solution Implemented**:
  - 1st Generation: Foreign-born
  - 2nd Generation: U.S.-born with ≥1 foreign-born parent
  - 3rd+ Generation: U.S.-born with U.S.-born parents

• **Coverage After Fix**:
  - 2002-2007: 85-90% generation coverage
  - 2008-2023: 95%+ generation coverage

### D. Statistical Approach

• **Trend Analysis**
  - Linear regression with year as continuous
  - Robust standard errors
  - Generation-stratified models

• **Weighting Strategy**
  - Survey weights where available (10/14 years)
  - Unweighted sensitivity analysis
  - Minimal differences in substantive findings

• **Missing Data**
  - Overall: 59% missing across all variables
  - Strategy: Complete case analysis
  - Rationale: Imputation risky with changing questions

---

## III. KEY FINDINGS: EVOLUTION ACROSS VERSIONS

### A. Aggregated Index Findings (v2.7-v3.0)

• **Overall Hispanic Population**
  - Remarkably stable attitudes over 20 years
  - No significant trends in any index
  - Slight decrease in deportation concern (p=0.019)

• **By Generation (Weighted v2.8)**
  - **1st Generation**:
    * Liberalism: +0.019/year (p=0.021*)
    * Restrictionism: +0.011/year (p=0.004**)
    * Pattern: Simultaneous increase in BOTH
  - **2nd Generation**:
    * Liberalism: -0.005/year (ns)
    * Restrictionism: -0.015/year (ns)
    * Pattern: Converging toward middle
  - **3rd+ Generation**:
    * Liberalism: -0.016/year (ns)
    * Restrictionism: -0.002/year (ns)
    * Pattern: Stable, most restrictive baseline

### B. Disaggregated Findings (v4.3-v4.4)

• **Major Discovery: The Border Wall Paradox**
  - 1st Generation: Decreasing support over time
  - 2nd Generation: Increasing support over time
  - 3rd+ Generation: Stable high support
  - Contradicts simple assimilation theories

• **Four Variables Show Divergent Generational Patterns**
  1. Border Wall Support
  2. DACA Support
  3. Border Security
  4. Support for Legalization

• **Heterogeneity Within Indices**
  - Variables within same index don't always correlate
  - Example: Border wall negatively correlates with border security (r=-0.44)
  - Suggests attitudes are fragmented, not monolithic

### C. Period Effects Analysis (v4.0)

• **Historical Periods Identified**
  - Early Bush Era (2002-2004)
  - Immigration Debates (2006-2007)
  - Economic Crisis (2008-2010)
  - Obama Era (2011-2015)
  - Trump Era (2016-2018)
  - COVID & Biden Era (2021-2023)

• **Key Period × Generation Interactions**
  - Trump Era: 1st generation defensive liberalization
  - Economic Crisis: All generations more restrictive
  - Obama Era: Peak liberalism for 1st/2nd generation

---

## IV. THEORETICAL IMPLICATIONS

### A. Attitude Structure
• **Not Unidimensional**: Immigration attitudes contain distinct modules
  - Humanitarian concerns (DACA, legalization)
  - Security/enforcement preferences
  - Personal threat perception
  - Economic competition beliefs

• **Fragmentation Pattern**
  - Can support legalization AND enforcement
  - Can oppose wall but support deportation
  - Personal concern ≠ policy preferences

### B. Assimilation Dynamics
• **Classical Assimilation**: Partial support
  - 3rd+ generation most "American" in attitudes
  - But process isn't linear

• **Segmented Assimilation**: Strong support
  - Multiple pathways evident
  - 2nd generation shows highest variance

• **Reactive Ethnicity**: Confirmed
  - 1st generation mobilizes during threat
  - Defensive response to Trump rhetoric

### C. The "Immigrants Against Immigrants" Phenomenon
• **Not a Paradox But Logical Outcome**
  - Integration → Adoption of American political divisions
  - Generational distancing from immigrant identity
  - Intragroup boundary-making processes

• **Mechanisms**
  - **Identity**: "We are different from new immigrants"
  - **Competition**: Economic/social resource concerns
  - **Assimilation**: Proving American belonging
  - **Context**: Period-specific political pressures

---

## V. METHODOLOGICAL TRANSPARENCY

### A. Strengths
• **Temporal Coverage**: 21 years, multiple administrations
• **Sample Size**: Large N allows generation stratification
• **Variable Evolution**: Tracked question wording changes
• **Multiple Approaches**: Tested various index constructions

### B. Limitations
• **Missing Data**: High missingness, especially concern index
• **Question Changes**: Some items not asked consistently
• **Cross-Sectional**: Cannot track individual change
• **Self-Report**: Potential social desirability bias

### C. Analytical Choices & Rationale
• **Why Three Indices?**
  - Empirical: Low negative correlation between liberalism/restrictionism
  - Theoretical: Captures attitude complexity
  - Practical: Better handles missing data

• **Why Disaggregate?**
  - Discovery: Indices masked important variation
  - Border wall finding wouldn't emerge otherwise
  - More honest about what we're measuring

• **Why Not Impute?**
  - Questions changed across years
  - Imputation assumptions questionable
  - Complete case more conservative

---

## VI. IMPLICATIONS FOR CONFERENCE DISCUSSION

### A. For Immigration Scholarship
• Move beyond unidimensional pro/anti framework
• Generation isn't destiny - context matters
• Need longitudinal individual-level data

### B. For Political Analysis
• "Latino vote" increasingly meaningless aggregate
• Generational replacement → attitude shift
• Coalition building requires targeted messaging

### C. For Policy Debates
• Support for enforcement ≠ anti-immigrant
• Humanitarian and security concerns coexist
• Personal threat shapes policy preferences

### D. Future Research Priorities
• **Immediate**: Add demographic controls
• **Short-term**: Regional analysis, qualitative follow-up
• **Long-term**: Panel study, comparative analysis

---

## VII. VISUALIZATION HIGHLIGHTS

### Key Figures for Presentation
1. **Overall Trends by Generation** (v4.0)
   - Shows persistent gaps
   - Highlights stability

2. **Border Wall Divergence** (v4.3)
   - Most striking finding
   - Clear visualization of paradox

3. **Period Effects** (v4.0)
   - Context matters
   - Generation × period interaction

4. **Disaggregated Components** (v4.4)
   - Reveals heterogeneity
   - Questions index approach

---

## VIII. QUESTIONS & DISCUSSION POINTS

### Anticipated Questions
• **Q: Why not combine into single scale?**
  - A: Tested it - attitudes aren't bipolar opposites
  - Evidence: Positive correlations between "opposing" items

• **Q: How handle changing questions?**
  - A: Standardized all variables
  - Documented exact wording changes
  - Sensitivity analyses

• **Q: Causal claims?**
  - A: No - descriptive trends only
  - Cross-sectional limits causal inference
  - Focus on patterns, not mechanisms

• **Q: Generalizability?**
  - A: Pew's gold-standard sampling
  - But: Hispanic heterogeneity
  - Need: Subgroup analysis by origin

### Discussion Starters
1. Is assimilation inevitable? Desirable?
2. How do we build coalitions across generations?
3. What explains the border wall paradox?
4. Role of political rhetoric in attitude formation?

---

## IX. CONCLUSION

### The Paradox That Isn't

• **Central Finding**: "Immigrants against immigrants" reflects successful assimilation
  - Not false consciousness or betrayal
  - Logical outcome of integration into polarized America
  - Reveals how group boundaries shift across generations

• **Methodological Lesson**: Aggregation obscures reality
  - Single indices hide crucial variation
  - Fragmented attitudes require nuanced measurement
  - Temporal analysis essential for immigration scholarship

### Broader Implications

• **For Theory**
  - Assimilation isn't unidirectional progress
  - Political incorporation involves adopting divisions
  - Generation interacts with historical moment
  - Identity boundaries are dynamic, not fixed

• **For Politics**
  - Hispanic political futures aren't predetermined
  - Generational replacement will shift baseline attitudes
  - Coalition building requires generation-specific strategies
  - Period effects create windows of opportunity

• **For Policy**
  - Immigration attitudes contain multiple, distinct dimensions
  - Support exists for both humanitarian AND enforcement approaches
  - Personal threat perception shapes policy preferences
  - Messaging must acknowledge attitude complexity

### The Path Forward

• **This Research Shows**
  - 20-year stability masks important heterogeneity
  - Generations diverging, not converging
  - Context (period effects) powerfully shapes attitudes
  - Simple pro/anti framework inadequate

• **Future Work Must**
  - Track individuals longitudinally
  - Examine mechanisms behind divergence
  - Include broader demographic controls
  - Compare with non-Hispanic populations

### Final Thought

The story of Hispanic immigration attitudes from 2002-2023 is not one of simple trajectory but of complex negotiation—between heritage and belonging, between solidarity and distinction, between past and future. Understanding this complexity is essential for grasping not just Hispanic political incorporation, but the evolving meaning of American identity itself in an era of unprecedented diversity and polarization.

---

**Repository**: github.com/[repository-path]  
**Contact**: annjiang@ucsd.edu  
**Acknowledgments**: Pew Research Center for data access