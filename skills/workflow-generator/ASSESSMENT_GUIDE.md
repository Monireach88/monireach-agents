# Workflow Generator Skill - Assessment Guide

**Purpose:** Guide future assessors (including future me) on how to evaluate generated workflows and continue improving the skill.

**Version:** 1.0 (for skill v0.2.0+)
**Last updated:** 2026-02-10

---

## Quick Start

When a new workflow is generated, follow this checklist:

1. **Run Automated Checks** (5 minutes) → See Section 2
2. **Manual Spot Check** (10 minutes) → See Section 3
3. **Compare to Baseline** (5 minutes) → See Section 4
4. **Document Findings** (5 minutes) → See Section 5

**Total time:** ~25 minutes per workflow

---

## 1. When to Assess

### Mandatory Assessment

Run full assessment when:
- ✅ New workflow generated (KNN, Logistic Regression, XGBoost, etc.)
- ✅ Skill updated to new version (v0.2.1, v0.3.0, etc.)
- ✅ User reports "theory bloat" or "irrelevant content"
- ✅ Workflow length exceeds expected range by >20%

### Optional Assessment

Quick check when:
- ⚠️ User happy with workflow but want to track metrics
- ⚠️ Periodic quality audit (monthly, quarterly)

---

## 2. Automated Checks (5 Minutes)

### 2.1 Red Flag Search

Run these grep commands on the generated workflow:

```bash
WORKFLOW_FILE="/path/to/generated_workflow.md"

echo "🔍 Searching for red flags..."
echo ""

# Check 1: "rare" mentions
echo "1. Checking for 'rare':"
grep -in "rare" "$WORKFLOW_FILE" | wc -l
grep -in "rare" "$WORKFLOW_FILE" | head -5
echo ""

# Check 2: "edge case" mentions
echo "2. Checking for 'edge case':"
grep -in "edge case" "$WORKFLOW_FILE" | wc -l
grep -in "edge case" "$WORKFLOW_FILE" | head -5
echo ""

# Check 3: "for completeness" mentions
echo "3. Checking for 'for completeness':"
grep -in "for completeness" "$WORKFLOW_FILE" | wc -l
grep -in "for completeness" "$WORKFLOW_FILE" | head -5
echo ""

# Check 4: Line count
echo "4. File length:"
wc -l "$WORKFLOW_FILE"
```

**Expected results (v0.2.0+):**
- "rare": **0 matches** (any match = violation)
- "edge case": **0-1 matches** (only if production-justified)
- "for completeness": **0 matches** (any match = violation)
- Line count: Within expected range (see Section 2.3)

---

### 2.2 Generic Content Duplication Check

Check if generic content is referenced vs duplicated:

```bash
# Check for versioning duplication
echo "5. Checking for generic versioning content:"
grep -i "version control\|rollback\|git tag" "$WORKFLOW_FILE" | grep -v "ml_pipeline_complete_map" | wc -l
# Expected: 0 (should all reference general file)

# Check for scaling duplication
echo "6. Checking for generic scaling content:"
grep -i "load balanc\|kubernetes\|docker swarm\|auto-scaling" "$WORKFLOW_FILE" | grep -v "ml_pipeline_complete_map" | wc -l
# Expected: 0-1 (mention is OK, detailed explanation is not)

# Check for monitoring duplication
echo "7. Checking for generic monitoring content:"
grep -i "prometheus\|grafana\|datadog" "$WORKFLOW_FILE" | grep -v "ml_pipeline_complete_map" | wc -l
# Expected: 0 (should reference general file)
```

**Expected results:** All checks return **0 or 1** (brief mentions OK, detailed explanations = violation)

---

### 2.3 Length Compliance Check

Compare actual length to expected range:

```bash
LINE_COUNT=$(wc -l < "$WORKFLOW_FILE")
MODEL_NAME="<extracted from filename>"

# Expected ranges (from SKILL.md Step 5.5)
# Simple models (LR, Logistic): 2,000-3,000 lines
# Medium models (SVM, Random Forest): 2,500-3,500 lines
# Complex models (XGBoost, Neural Networks): 4,000-6,000 lines

# If Linear Regression + Ridge/Lasso/ElasticNet: 3,000-3,500 lines

# Example calculation for Linear Regression:
EXPECTED_MIN=2000
EXPECTED_MAX=3000
TOLERANCE=0.20  # 20% tolerance

MIN_ACCEPTABLE=$((EXPECTED_MIN - EXPECTED_MIN * TOLERANCE / 100))
MAX_ACCEPTABLE=$((EXPECTED_MAX + EXPECTED_MAX * TOLERANCE / 100))

if [ $LINE_COUNT -lt $MIN_ACCEPTABLE ]; then
    echo "⚠️ WARNING: Too short ($LINE_COUNT < $MIN_ACCEPTABLE)"
elif [ $LINE_COUNT -gt $MAX_ACCEPTABLE ]; then
    echo "⚠️ WARNING: Too long ($LINE_COUNT > $MAX_ACCEPTABLE)"
else
    echo "✅ Length OK ($LINE_COUNT within $MIN_ACCEPTABLE-$MAX_ACCEPTABLE)"
fi
```

---

### 2.4 Automated Check Summary

Create a summary report:

```bash
echo "═══════════════════════════════════════════════════════"
echo "Automated Check Summary: $MODEL_NAME"
echo "═══════════════════════════════════════════════════════"
echo "File: $WORKFLOW_FILE"
echo "Length: $LINE_COUNT lines"
echo ""
echo "Red Flags:"
echo "  - 'rare': <count> matches (expected: 0)"
echo "  - 'edge case': <count> matches (expected: 0-1)"
echo "  - 'for completeness': <count> matches (expected: 0)"
echo ""
echo "Generic Duplication:"
echo "  - Versioning: <count> lines (expected: 0)"
echo "  - Scaling: <count> lines (expected: 0-1)"
echo "  - Monitoring: <count> lines (expected: 0)"
echo ""
echo "Length Compliance:"
echo "  - Expected: $EXPECTED_MIN-$EXPECTED_MAX lines"
echo "  - Actual: $LINE_COUNT lines"
echo "  - Status: <OK / Too Short / Too Long>"
echo "═══════════════════════════════════════════════════════"
```

**Pass criteria:** All checks pass → Proceed to manual spot check

---

## 3. Manual Spot Check (10 Minutes)

### 3.1 Random Section Sampling

Select 3 random sections to review in detail:

1. **§ Model Training** (always check - most likely to have theory bloat)
2. **§ Hyperparameter Tuning** (always check - can have rare parameters)
3. **Random section** (pick any from remaining 11 sections)

---

### 3.2 Formula/Derivation Check

**For EVERY mathematical formula in the sampled sections:**

Ask: "Does this formula inform a production decision?"

**Examples from Linear Regression (use as templates):**

| Formula Found | Informs Decision? | Verdict | Rationale |
|:--------------|:------------------|:--------|:----------|
| θ = (X^T X)^(-1) X^T y | ❌ NO | **VIOLATION** | sklearn does it, doesn't help choose algorithm |
| R² = 1 - (SS_res / SS_tot) | ✅ YES | **OK** | Helps understand when to trust model (R² < 0.5 = poor fit) |
| Normal Equation vs Gradient Descent table | ✅ YES | **OK** | Helps choose LinearRegression (<10K features) vs SGDRegressor (>10K) |
| Time complexity O(n × p²) | ⚠️ MAYBE | **BORDERLINE** | Explains why to switch algorithms, but could be briefer |

**Pass criteria:**
- ✅ All formulas inform decisions (choose algorithm, tune hyperparameter, diagnose failure)
- ⚠️ Borderline formulas are concise (1-2 lines) and in context
- ❌ Any derivation (step-by-step math) = VIOLATION

---

### 3.3 Parameter Documentation Check

**For EVERY sklearn parameter documented:**

Ask: "Is this parameter used in >10% of production projects?"

**Examples from Linear Regression:**

| Parameter | Usage Estimate | Verdict | Rationale |
|:----------|:---------------|:--------|:----------|
| fit_intercept=False | <1% | **VIOLATION** | Rare edge case (physical laws) |
| n_jobs=-1 | >50% | **OK** | Common parallelization |
| copy_X=False | <5% | **VIOLATION** | Premature optimization |
| alpha (Ridge/Lasso) | >80% | **OK** | Critical hyperparameter |
| positive=True | ~10% | **BORDERLINE** | Domain constraint (frequencies, counts) |

**How to estimate usage:**
1. Check sklearn docs examples (how often is it shown?)
2. Web search "{parameter} usage production ML" (how many results?)
3. Ask: "Would most AI Engineers know when to use this?"

**Pass criteria:**
- ✅ All documented parameters have >10% usage OR are sklearn defaults
- ⚠️ Borderline parameters (5-15% usage) have brief mention only (not full section)
- ❌ Rare parameters (<5% usage) with detailed explanation = VIOLATION

---

### 3.4 Actionability Check

**For 5 random paragraphs in sampled sections:**

Apply the 4 Filter Tests:

1. **Removal Test:** "If I remove this, will an AI Engineer fail to deploy {model}?"
2. **Usage Threshold:** "Is this used in >10% of production projects?"
3. **Decision Test:** "Does this help choose between algorithms/hyperparameters/approaches?"
4. **Frequency Test:** "Is this widely known among mid-level AI Engineers?"

**Example application:**

**Paragraph:** "The Normal Equation solves for θ via matrix inversion. sklearn uses SVD for numerical stability when the matrix is nearly singular."

**Filter application:**
- Removal Test: ❌ NO (AI Engineer doesn't need to know SVD internals to deploy)
- Decision Test: ❌ NO (Doesn't help choose algorithm or tune hyperparameter)
- **Verdict:** **VIOLATION** - This is theory, not actionable guidance

**Paragraph:** "Use Ridge (alpha=1.0) when VIF > 10 to handle multicollinearity. Prevents unstable coefficients."

**Filter application:**
- Removal Test: ✅ YES (Need to know when to switch from LR to Ridge)
- Usage Threshold: ✅ YES (>50% of LR projects hit multicollinearity)
- Decision Test: ✅ YES (Helps choose Ridge over LinearRegression)
- Frequency Test: ✅ YES (VIF is standard diagnostic tool)
- **Verdict:** **OK** - Actionable production guidance

**Pass criteria:**
- ✅ 4/5 paragraphs pass ALL 4 tests → Section is clean
- ⚠️ 3/5 paragraphs pass → Borderline, review entire section
- ❌ <3/5 paragraphs pass → VIOLATION, section needs rework

---

### 3.5 Manual Spot Check Summary

```
═══════════════════════════════════════════════════════
Manual Spot Check Summary: <Model Name>
═══════════════════════════════════════════════════════
Sections Reviewed:
  1. § Model Training
  2. § Hyperparameter Tuning
  3. § <Random Section>

Formula Check:
  - Total formulas found: <count>
  - Formulas informing decisions: <count> / <total>
  - Violations: <list any derivations>

Parameter Check:
  - Total parameters documented: <count>
  - Parameters with >10% usage: <count> / <total>
  - Violations: <list rare parameters>

Actionability Check:
  - Paragraphs sampled: 5
  - Paragraphs passing all 4 tests: <count> / 5
  - Violations: <list paragraphs failing tests>

Overall Section Quality:
  - § Model Training: <PASS / BORDERLINE / FAIL>
  - § Hyperparameter Tuning: <PASS / BORDERLINE / FAIL>
  - § <Random Section>: <PASS / BORDERLINE / FAIL>
═══════════════════════════════════════════════════════
```

---

## 4. Compare to Baseline (5 Minutes)

### 4.1 Historical Comparison

Compare current workflow to previous workflows:

| Metric | Linear Regression (v0.1.0) | Current Workflow | Improvement |
|:-------|:---------------------------|:-----------------|:------------|
| **Total lines** | 3,704 | <count> | <calculation> |
| **Violations** | 170 lines (5-7%) | <count> | <calculation> |
| **"rare" mentions** | 3 | <count> | <calculation> |
| **"edge case" mentions** | 2 | <count> | <calculation> |
| **Rare parameters** | 2 (fit_intercept=False, copy_X) | <count> | <calculation> |
| **Generic duplication** | 80 lines | <count> | <calculation> |

**Expected improvements (v0.2.0+):**
- Violations: <0.5% (down from 5-7%)
- "rare" mentions: 0 (down from 3)
- Rare parameters: 0 (down from 2)
- Generic duplication: 0 (down from 80 lines)

---

### 4.2 Skill Version Tracking

Track metrics across skill versions:

```
Workflow: <Model Name>
Skill Version: v0.2.0
Date Generated: <YYYY-MM-DD>

Metrics:
  - Length: <lines> (expected: <min>-<max>)
  - Violations: <count> (<percentage>%)
  - Formula violations: <count>
  - Parameter violations: <count>
  - Generic duplication: <lines>

Pass/Fail: <PASS / FAIL>
Notes: <any observations>
```

**Archive this data for trend analysis.**

---

## 5. Document Findings (5 Minutes)

### 5.1 Create Assessment Report

Use this template:

```markdown
# Workflow Assessment Report

**Model:** <Model Name>
**Skill Version:** <version>
**Date:** <YYYY-MM-DD>
**Assessor:** <Your name or "Automated">

---

## Executive Summary

**Overall Verdict:** <PASS / FAIL / BORDERLINE>

**Key Findings:**
- <Bullet point summary>
- <Bullet point summary>
- <Bullet point summary>

**Violations Found:** <count> (<percentage>% of content)

---

## Automated Checks

<Paste automated check summary from Section 2.4>

---

## Manual Spot Check

<Paste manual spot check summary from Section 3.5>

---

## Comparison to Baseline

<Paste historical comparison from Section 4.1>

---

## Recommendations

**For this workflow:**
- [ ] <Action item if violations found>
- [ ] <Action item if violations found>

**For skill improvement:**
- [ ] <Suggested fix if pattern detected>
- [ ] <Suggested fix if pattern detected>

---

## Next Steps

**If PASS:**
1. Archive this report
2. Continue testing on next model
3. Track metrics for trend analysis

**If FAIL:**
1. Document specific violations
2. Identify root cause (skill issue vs agent issue)
3. Implement fix (see Section 6)
4. Re-test on same model

---

**Report completed:** <YYYY-MM-DD>
```

---

### 5.2 Archive Location

Save assessment reports here:

```
~/.claude/skills/workflow-generator/assessments/
├── 2026-02-10_linear_regression_v0.1.0.md  (baseline)
├── 2026-02-11_knn_v0.2.0.md                (test 1)
├── 2026-02-12_logistic_regression_v0.2.0.md (test 2)
└── 2026-02-15_xgboost_v0.2.0.md            (test 3)
```

**Naming convention:** `YYYY-MM-DD_<model_name>_v<skill_version>.md`

---

## 6. How to Fix Violations

### 6.1 If Violations Found in Generated Workflow

**Quick fix (for current workflow):**

1. Identify violation category:
   - Red flag mentions ("rare", "edge case") → Delete content
   - Formula without decision → Delete or replace with actionable alternative
   - Rare parameter (<10% usage) → Delete detailed documentation
   - Generic duplication → Replace with ml_pipeline_complete_map.md reference

2. Edit workflow file:
   ```bash
   # Remove violation
   Edit(
       file_path="<workflow_path>",
       old_string="<content with violation>",
       new_string="<actionable alternative OR removal>"
   )
   ```

3. Re-run automated checks (Section 2)

4. Document fix in assessment report

---

### 6.2 If Pattern Detected Across Multiple Workflows

**Skill fix (for future workflows):**

If same violation appears in 2+ workflows, skill needs improvement.

**Diagnosis:**

1. **Check if Fix 1 (Filter at Writing Time) was applied:**
   - Read SKILL.md Step 4.1
   - Verify filter enforcement exists
   - Check if agent's transcript shows filter application

2. **Check if Fix 2 (Final Review) was applied:**
   - Read SKILL.md Step 8.5
   - Verify agent ran content review
   - Check if violations were caught in Step 8.5

3. **Identify which fix failed:**

| Violation Type | Fix Failed | Action |
|:---------------|:-----------|:-------|
| Formula derivation | Fix 1 (writing time) | Strengthen red flags in Step 4.1 |
| Rare parameter | Fix 3 (concrete tests) | Add example to Step 2.4.1 |
| Generic duplication | Fix 5 (reference table) | Add to table in Step 5.1 template |
| Theory bloat for specific model | Fix 4 (watchlist) | Add to examples in Step 3.6 |
| Section too long | Fix 6 (depth guidance) | Adjust ranges in Step 5.5 |
| Missed in final review | Fix 2 (review step) | Add check to Step 8.5 |

**Implement fix:**

1. Edit SKILL.md
2. Update version number (e.g., v0.2.0 → v0.2.1)
3. Document in CHANGELOG.md
4. Re-test on same model that showed violation
5. If fixed, continue testing on new models

---

## 7. Continuous Improvement

### 7.1 After Every 3-5 Workflows

**Aggregate analysis:**

1. Calculate average violation rate across all tested workflows
2. Identify most common violation type
3. Check if trend is improving (v0.2.0 better than v0.1.0?)
4. Document in skill improvement backlog

**Expected trajectory:**

```
v0.1.0 baseline:
- Linear Regression: 5-7% violations (170 lines)

v0.2.0 (Fixes 1-6):
- KNN: <0.5% violations (expected)
- Logistic Regression: <0.5% violations (expected)
- XGBoost: <0.5% violations (expected)

v0.3.0 (future):
- <0.1% violations (target)
```

---

### 7.2 Skill Improvement Backlog

Track improvement ideas here:

```markdown
# Skill Improvement Backlog

## Planned (v0.3.0)
- [ ] Automated violation scoring script
- [ ] Progressive disclosure (move templates to references/)
- [ ] Model complexity classifier

## Proposed (v0.4.0)
- [ ] Filter test examples library (20+ examples per model family)
- [ ] Watchlist templates for common models
- [ ] Section depth auto-validation

## Icebox
- [ ] Integration with linter (flag violations in editor)
- [ ] User feedback loop (thumbs up/down per section)
```

---

### 7.3 When to Stop Testing

**Sufficient confidence achieved when:**

1. ✅ Tested on 5+ diverse models (simple, medium, complex)
2. ✅ Average violation rate <0.5% across all workflows
3. ✅ Zero repeat violations (same issue in 2+ workflows)
4. ✅ User satisfaction: No theory bloat complaints for 5+ workflows

**At this point:**
- Archive testing data
- Mark skill as "production-ready"
- Switch to periodic audits (monthly or quarterly)

---

## 8. Quick Reference

### Assessment Checklist (Use This Every Time)

```
Workflow: _________________
Date: _________________
Assessor: _________________

AUTOMATED CHECKS (5 min):
[ ] Red flag search (rare, edge case, for completeness)
[ ] Generic duplication check (versioning, scaling, monitoring)
[ ] Length compliance check

MANUAL SPOT CHECK (10 min):
[ ] Formula check (3 sections)
[ ] Parameter check (3 sections)
[ ] Actionability check (5 random paragraphs)

COMPARISON (5 min):
[ ] Compare to baseline (Linear Regression v0.1.0)
[ ] Track metrics for skill version

DOCUMENTATION (5 min):
[ ] Create assessment report
[ ] Archive report
[ ] Update improvement backlog if violations found

OVERALL VERDICT:
[ ] PASS - No violations, proceed to next model
[ ] FAIL - Violations found, fix and re-test
```

---

## 9. Contact & Support

**Questions about this guide:**
- Check CHANGELOG.md for recent fixes
- Check SKILL.md for current filter implementation
- Review Linear Regression assessment (baseline) in debate files

**Updating this guide:**
- Add new violation patterns as discovered
- Add new model-specific examples
- Update expected metrics as skill improves

---

**Guide version:** 1.0
**Last updated:** 2026-02-10
**Next review:** After testing 3-5 workflows (KNN, Logistic Regression, XGBoost)
