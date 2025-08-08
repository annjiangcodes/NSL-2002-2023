# QUICK REFERENCE GUIDE - NSL Immigration Attitudes Project

## 🚀 For New Users/Future Researchers

### **Start Here (Latest Authoritative Files):**
```bash
# Latest dataset (95.7% generation coverage)
data/latest/comprehensive_immigration_attitudes.csv

# Latest analysis script (enhanced with mixed-effects)  
scripts/latest/enhanced_weighted_master.R

# Latest findings summary
docs/latest/bug_fixes_and_coverage.md
```

### **Key Numbers to Remember:**
- **Total Observations**: 37,496 (35,871 with generation labels = 95.7%)
- **Time Span**: 2002-2022 (20 years, 4 presidential administrations)
- **Best Coverage Measure**: Restrictionism Index (62.7%, 9 years)
- **Generation Distribution**: 1st (51.4%), 2nd (34.5%), 3rd+ (14.0%)

## 📊 Current Status (2025-01-15)

### **Main Finding: Generational Differentiation**
1. **1st Generation**: Liberal + VOLATILE (variance = 0.0351)
2. **2nd Generation**: Moderate + STABLE (variance = 0.0124) 
3. **3rd+ Generation**: Conservative + Moderate volatility (variance = 0.0222)

### **Statistical Significance:**
- **Liberalism trends**: 1st gen ↗️ (p=0.019*), 2nd gen ↘️ (p=0.009**)
- **Gen×Year interaction**: p<0.001*** (highly significant)
- **Legalization support**: ALL generations declining (p<0.01)

## 🔧 Technical Implementation

### **Analysis Pipeline:**
1. **Data**: `data/latest/comprehensive_immigration_attitudes.csv`
2. **Run**: `scripts/latest/enhanced_weighted_master.R` 
3. **Results**: Automatically saved to `outputs/2025_01_15/`
4. **Figures**: Enhanced plots with confidence intervals

### **Statistical Methods:**
- Mixed-effects models (lme4/lmerTest)
- Weighted analysis (survey weights detected in raw data)
- 95% confidence intervals on all estimates
- Robust standard errors

## 📁 New File Organization

### **Naming Convention:**
- `TYPE_YYYY_MM_DD_description.ext`
- Types: DATA_, ANALYSIS_, VIZ_, REPORT_, UTIL_

### **Directory Structure:**
```
*/latest/     <- Symlinks to current authoritative versions
*/archive/    <- All dated versions preserved
```

### **Working with Files:**
```r
# Always use latest/ for current analysis
df <- read_csv("data/latest/comprehensive_immigration_attitudes.csv")

# When creating new files, use today's date
write_csv(results, "data/archive/DATA_2025_01_16_new_analysis.csv")
# Then update symlink in latest/
```

## 🐛 Major Issues Resolved

### **v2.9c Fixes:**
- ✅ Data version conflicts (scripts loading wrong files)
- ✅ CV calculation issues (misleading volatility measures)
- ✅ Column name mismatches (generation_label vs generation_recovered)

### **Interpretation Corrections:**
- ❌ Old: "2nd generation most volatile" 
- ✅ New: "2nd generation most stable"
- Based on actual variance calculations, not misleading CV

## 📋 For Future Development

### **Adding New Analysis:**
1. Use current date: `ANALYSIS_YYYY_MM_DD_description.R`
2. Reference latest/ data files
3. Save outputs to dated folder: `outputs/YYYY_MM_DD/`
4. Update VERSION_HISTORY.md
5. Create new symlinks if this becomes authoritative

### **Data Updates:**
1. Name: `DATA_YYYY_MM_DD_description.csv`
2. Place in `data/archive/`
3. Update symlink in `data/latest/`
4. Document changes in VERSION_HISTORY.md

### **Quality Checks:**
- Generation coverage should be >95%
- Sample sizes >1000 per generation for robust results
- Always include confidence intervals
- Document any methodological changes

## 🎯 Conference/Publication Ready

### **Key Deliverables Available:**
- Publication-quality figures with confidence bands
- Comprehensive statistical results (linear + mixed-effects)
- Full methodology documentation
- Replication files with clear naming

### **Main Message:**
"Generational differentiation in Latino immigration attitudes: 1st generation shows volatile liberalization, 2nd generation exhibits stable democratic integration, 3rd+ generation maintains conservative baseline."

---

**Last Updated:** 2025-01-15  
**Next Review:** Update when new major analysis completed  
**Contact:** Check VERSION_HISTORY.md for analysis provenance
