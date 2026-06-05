---
name: workflow-generator
description: This skill should be used when the user asks to "create workflow", "generate workflow for [model name]", "create ML workflow", "build model documentation", "generate documentation for [model]", or mentions "workflow generation". Creates comprehensive ML model workflow documentation following standardized 13-section template with mermaid diagrams and table of contents.
version: 0.6.0
tools: Read, Glob, Grep, Edit, Write, WebFetch, Bash
changelog:
  - v0.6.0 (2026-04-03) - Parallel Sub-Agents A+B for research phase (Steps 2-3 moved out of main context; main context only compiles Step 4 from sub-agent returns)
  - v0.5.0 (2026-02-11) - Added Research Context Summary passing to Task Agent (fixes bloat issue where Task Agent had no access to research results, assessment, and Theory Bloat Watchlist)
  - v0.4.0 - Autonomous generation via Task Agent (sections 2-13)
  - v0.3.0 - Refined proportionality formula for hyperparameter tuning
---

# Workflow Generator Skill

Generate comprehensive ML model workflow documentation following standardized 13-section template.

## When to Invoke

Trigger this skill when user requests:
- "Create workflow for [model name]"
- "Generate ML workflow documentation"
- "Build workflow file for KNN/SVM/Random Forest/etc."
- "Document [model name] workflow"

## Required Arguments

Parse user's request to extract:
- **Model name** (e.g., "KNN", "Logistic Regression", "Naive Bayes")
- **Lab file path** (optional - will search if not provided)
- **Destination path** (optional - will use default: `workflows/{model_name_lowercase}_workflow.md`)
- **General workflow path** (optional - default: `ml_pipeline_complete_map.md`)

Example invocations:
- "Create workflow for KNN" → Auto-search for lab file, use default paths
- "Generate SVM workflow from labs/module3/svm.ipynb" → Use specified lab
- "Build Naive Bayes workflow at workflows/nb.md" → Use specified destination

## Core Workflow

### CRITICAL PRINCIPLES (Read Before Starting)

**This skill requires AUTONOMOUS, RESEARCH-DRIVEN work:**

1. **Think Critically, Don't Just Copy:**
   - Filter user's notes for AI Engineering relevance (not academic theory dumps)
   - Research thoroughly to fill gaps (sklearn docs, best practices)
   - Make independent decisions about workflow structure based on model complexity
   - DO NOT ask user for obvious answers that research can provide

2. **Research Is MANDATORY, Not Optional:**
   - Fetch sklearn documentation (verify ALL parameters, defaults, ranges)
   - Web search production best practices (authoritative sources)
   - Research workflow decisions (training algorithms, deployment optimizations)
   - Fact-check everything - NO HALLUCINATION

3. **Let Complexity Determine Scope:**
   - Simple model (LinearRegression, LogisticRegression) = fewer hyperparameters, shorter tuning section
   - Complex model (XGBoost, Neural Networks) = many hyperparameters, longer tuning section
   - DO NOT mechanically match other workflows' lengths or set arbitrary line count targets
   - **Ignore line count entirely** - focus ONLY on production-relevant content
   - Quality = usefulness for deployment, NOT document length

4. **Filter For AI Engineering Relevance:**
   - KEEP: Content helping deploy/tune/debug models in production
   - REMOVE: Pure math derivations without practical application
   - KEEP: Selective math that informs decisions (R² formula, gradient descent concept)
   - REMOVE: Formula proofs, derivative calculations, convergence proofs

5. **Be Autonomous:**
   - Research workflow decisions yourself (don't ask user)
   - Decide what to include based on research (don't ask user)
   - Assess user's code and suggest improvements (don't just copy)
   - Fill gaps from authoritative sources (don't ask user for missing info)

**If you find yourself asking "Should I include X?" or "What should the diagram show?":**
- STOP. Research the answer using WebSearch/WebFetch
- Use your judgment based on AI Engineering relevance
- Consult sklearn docs and best practices
- Make the decision autonomously

---

### PRODUCTION RELEVANCE FILTER (Zero Tolerance for Bloat)

**Golden Rule:** Only include content that production AI Engineers use regularly.

**❌ REMOVE (Exotic/Rare Techniques Nobody Uses):**
- ONNX conversion for simple models (LinearRegression, LogisticRegression)
  - Why: These models are so lightweight, ONNX conversion is overkill
  - Keep ONNX for: Neural networks, complex ensembles
- Step-by-step matrix operation code (X^T X computation details)
  - Why: sklearn handles this, engineers don't need to code it
  - Keep: High-level concept (e.g., "Normal Equation requires X^T X to be invertible")
- Obscure preprocessing techniques (ICA, t-SNE embeddings)
  - Why: Rarely used in standard pipelines
  - Keep: StandardScaler, PCA (if dimensionality is issue)
- Advanced quantization techniques
  - Why: Only relevant for neural networks on edge devices
  - For simple models: State "quantization not applicable" and move on

**✅ KEEP (Common Production Patterns):**
- REST API deployment (Flask/FastAPI)
- Batch prediction pipelines
- Serverless deployment (AWS Lambda, Cloud Functions)
- GridSearchCV/RandomizedSearchCV (standard tuning)
- Pipeline usage (prevents data leakage)
- Common metrics (R², RMSE, Precision, Recall)
- Failure diagnosis (VIF for multicollinearity, residual plots)

**Decision Framework:**
1. Research: "Is [technique] commonly used in production for [model]?"
2. If found in <5 production guides → REMOVE (too exotic)
3. If found in >10 production guides → KEEP (standard practice)
4. If unsure → Ask: "Would a mid-level AI Engineer know this?"

**Examples:**
- ✅ Include: Ridge/Lasso for LinearRegression (standard next step when LR fails)
- ❌ Remove: ONNX export for LinearRegression (overkill for 1KB model)
- ✅ Include: Stratified sampling for classification (common with imbalanced data)
- ❌ Remove: Custom loss functions for sklearn models (advanced research topic)

---

### Step 1: Parse Arguments & Initialize

Extract from user's message:
- Model name (normalize: "k-nn" → "KNN", "support vector machine" → "SVM")
- Lab file path (if provided)
- Destination path (if provided, else: `workflows/{model_name_lowercase}_workflow.md`)
- General workflow path (default: `ml_pipeline_complete_map.md`)

Display initialization message:
```
Workflow Generator - {Model Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Model: {Model Name}
Lab: {path or "Auto-search"}
Destination: {path}
General: {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Phase 1: Parallel Research (Sub-Agents A + B launching...)
```

---

### Step 2: Parallel Research — Spawn Sub-Agents A and B

Launch both in a single message (parallel execution). Steps 2 and 3 below are their respective instruction sets — do NOT execute them in main context.

**Sub-Agent A — File Research (no web calls)**
**Sub-Agent B — Web Research (no file reads)**

Pass to both sub-agents:
- Model name: `{model_name}`
- Lab file path: `{lab_file_path or "auto-search"}`
- Deliverables/project root for glob searches

---

### Step 2 (Sub-Agent A Instructions): Knowledge Assessment & AI Engineering Relevance Filter

**2.1 Search for lab file (if not provided):**

```bash
# Search for Jupyter notebooks matching model name
Glob: "**/*{model_name_lowercase}*.ipynb"
```

If multiple matches:
- List all matches with line counts
- Ask user: "Found multiple lab files. Which should I use?"
- Wait for user selection

If no matches:
- Inform user: "No lab file found. Proceeding with sklearn documentation only."
- Set lab_file = None

**2.2 Read lab file (if found):**

Extract from notebook:
- Code cells (especially model training, evaluation, hyperparameter tuning)
- Markdown cells with "New Concepts" section
- Markdown cells with "Self-Reflection" section
- Output cells showing results (accuracy scores, plots)

**2.3 Search for related knowledge files:**

```bash
# Search for "under the hood" files
Glob: "**/*{model_name_lowercase}*under*hood*.md"

# Search for model mentions in comparison files
Grep: pattern="{model_name}" path="." glob="*comparison*.md"

# Search for model mentions in key insights
Grep: pattern="{model_name}" path="." glob="*insights*.md"
```

**2.4 AI Engineering Relevance Check (MANDATORY):**

**Purpose:** Filter user's notes for content relevant to AI Engineering work, not pure academic theory.

```python
# REQUIRED: Understand AI Engineering role
WebSearch(query="AI Engineer role responsibilities production ML 2026")
WebSearch(query="{model_name} production deployment best practices")
```

**For each piece of content in user's notes, ask:**

✅ **KEEP if it helps:**
- Deploy/tune/debug models in production
- Choose right model for business problems
- Understand when model fails and why
- Optimize hyperparameters for real datasets
- Interpret model outputs for stakeholders
- Handle edge cases in production

❌ **REMOVE if it's:**
- Pure mathematical derivations without practical application (e.g., "Prove that gradient descent converges")
- Formula proofs that don't inform decisions (e.g., "Derive Normal Equation from first principles")
- Basic tutorial content ("What is regression?")
- Theory dumps without actionable workflow steps

⚠️ **NUANCED - KEEP selective math:**
- R² formula → KEEP (helps understand when to trust predictions)
- Gradient descent concept → KEEP (informs when to use vs Normal Equation)
- Kernel trick details → REMOVE (not used in daily AI Engineering unless research role)
- Derivative calculations → REMOVE (not actionable for deployment)

**Critical assessment questions:**
1. "Would an AI Engineer deploying this model in production need to know this?"
2. "Does this help choose hyperparameters, debug failures, or optimize performance?"
3. "Is this actionable or just theoretical background?"

**2.4.1 CONCRETE FILTER TESTS (Apply to EVERY piece of content):**

**Use these 4 tests for mechanical filtering:**

| Test | Question | Pass = KEEP | Fail = REMOVE |
|:-----|:---------|:------------|:--------------|
| **Removal Test** | "If I remove this, will an AI Engineer fail to deploy {model}?" | YES = KEEP | NO = REMOVE |
| **Usage Threshold** | "Is this used in >10% of production projects?" | YES = KEEP | NO = REMOVE |
| **Decision Test** | "Does this help choose between algorithms/hyperparameters/approaches?" | YES = KEEP | NO = REMOVE |
| **Frequency Test** | "Is this widely known among mid-level AI Engineers?" | YES = KEEP | NO = REMOVE |

**Application examples (use as templates):**

**Example 1: Normal Equation Formula (θ = (X^T X)^(-1) X^T y)**
- Removal Test: ❌ NO (sklearn does it automatically, user doesn't need formula to deploy)
- Decision Test: ❌ NO (doesn't help choose between LinearRegression vs Ridge)
- **Verdict:** REMOVE → Replace with "When training fails" scenarios

**Example 2: fit_intercept=False edge case**
- Usage Threshold: ❌ NO (<1% of production LR projects use this)
- Frequency Test: ❌ NO (most AI Engineers don't know when to use it)
- **Verdict:** REMOVE → Keep only default True recommendation

**Example 3: Ridge when VIF > 10**
- Removal Test: ✅ YES (diagnoses multicollinearity failure, prevents unstable coefficients)
- Usage Threshold: ✅ YES (>50% of LR projects encounter multicollinearity)
- Decision Test: ✅ YES (helps choose Ridge over LinearRegression)
- Frequency Test: ✅ YES (VIF is standard multicollinearity diagnostic)
- **Verdict:** KEEP

**Example 4: Pipeline usage for preventing data leakage**
- Removal Test: ✅ YES (prevents critical production bug)
- Usage Threshold: ✅ YES (>80% of sklearn projects use Pipelines)
- Decision Test: ✅ YES (helps choose Pipeline vs manual scaling)
- **Verdict:** KEEP

**Use these templates to evaluate EVERY paragraph you write in Step 4.**

**2.5 Assess knowledge coverage:**

Create checklist:
- ✅ **Well-covered (AI Engineering relevant):** [List topics with sources]
- ❌ **Gaps (missing production knowledge):** [List missing information]
- 🔍 **Need research:** [List areas requiring sklearn docs or web search]
- 🗑️ **Trivia to remove:** [List non-actionable theory]

Display assessment:
```
Knowledge Assessment:
✅ Well-covered (AI Engineering relevant):
  - Model training workflow (from lab)
  - Hyperparameter tuning examples (from lab)
  - Evaluation metrics (from lab)

❌ Gaps (missing production knowledge):
  - When NOT to use this model (no lab coverage)
  - Common pitfalls in production (not documented)
  - Deployment optimizations (not covered)
  - Real-world hyperparameter ranges (need sklearn docs)

🔍 Research needed:
  - sklearn hyperparameter defaults and ranges
  - Production best practices from authoritative sources
  - Model-specific deployment considerations
  - Comparison with other models (performance/speed tradeoffs)

🗑️ Trivia to remove:
  - Mathematical derivation of loss function (keep concept, remove proof)
  - Step-by-step gradient calculation (not actionable)
  - Theoretical convergence proofs (not used in practice)

Proceeding to research phase...
```

**Sub-Agent A expected return (structured):**
```
LAB FILE: {path or "not found"}
KEY CODE: {file}:{lines} — {description} (one line per example)
CODE ISSUES: {issue} → {fix} → use in § {section} (one line per issue)
USER KNOWS: {concept} — {file}:{section} (one per line)
USER MISSING: {concept} — needs explanation (one per line)
KNOWLEDGE FILES: {file} — {relevant sections found} (one per file)
```

---

### Step 3 (Sub-Agent B Instructions): Research Phase (MANDATORY - Autonomous Research Required)

**CRITICAL:** Do NOT proceed to Step 4 until ALL research tasks below are completed.

**3.1 sklearn Documentation (REQUIRED):**

```python
# MANDATORY: Fetch sklearn documentation
sklearn_docs = {
    "KNN": "https://scikit-learn.org/stable/modules/neighbors.html",
    "Logistic Regression": "https://scikit-learn.org/stable/modules/linear_model.html#logistic-regression",
    "Naive Bayes": "https://scikit-learn.org/stable/modules/naive_bayes.html",
    "Decision Tree": "https://scikit-learn.org/stable/modules/tree.html",
    "SVM": "https://scikit-learn.org/stable/modules/svm.html",
    "Random Forest": "https://scikit-learn.org/stable/modules/ensemble.html#random-forests",
    "Linear Regression": "https://scikit-learn.org/stable/modules/linear_model.html#ordinary-least-squares",
    "Ridge": "https://scikit-learn.org/stable/modules/linear_model.html#ridge-regression",
    "Lasso": "https://scikit-learn.org/stable/modules/linear_model.html#lasso",
    "XGBoost": "https://xgboost.readthedocs.io/en/stable/"
}

# REQUIRED: Extract ALL hyperparameters with defaults and ranges
WebFetch(
    url=sklearn_docs[model_name],
    prompt="""Extract and verify:
    1. ALL hyperparameters with their DEFAULT values
    2. Recommended RANGES for each hyperparameter
    3. When to use vs when NOT to use this model
    4. Common pitfalls mentioned in documentation
    5. Preprocessing requirements (scaling, encoding, etc.)
    6. Complexity/performance characteristics (training time, inference speed)
    """
)
```

**3.2 Production Best Practices (REQUIRED):**

```python
# MANDATORY: Research real-world best practices
WebSearch(query="{model_name} production deployment best practices 2026")
WebSearch(query="{model_name} hyperparameter tuning guide real world")
WebSearch(query="{model_name} common mistakes production ML")
WebSearch(query="{model_name} vs alternatives comparison performance")
```

**3.3 Workflow Decision Research (AUTONOMOUS):**

Research and answer these questions YOURSELF (do NOT ask user):

**For Model Selection (diagram):**
- What dataset size thresholds matter for this model? (e.g., ">10k samples slow", ">1M samples infeasible")
- What preprocessing is MANDATORY vs OPTIONAL? (e.g., SVM requires scaling, Random Forest doesn't)
- What are the model variants? (e.g., LinearSVC vs SVC, Ridge vs Lasso)
- When should user choose different model instead?

**For Training Phase:**
- What training algorithm choices exist? (e.g., Normal Equation vs Gradient Descent for Linear Regression)
- What loss functions are available? (e.g., MSE vs MAE, Hinge vs Squared Hinge)
- What are training time bottlenecks? (parallelization options, memory constraints)

**For Tuning Phase:**
- What are the CRITICAL hyperparameters (top 3-5 that matter most)?
- What are realistic ranges for production use? (not just "0.01 to 1000", be specific based on research)
- What's the interaction between hyperparameters? (e.g., C and gamma for SVM)

**For Deployment Phase:**
- What model-specific optimizations exist? (e.g., reduce trees for Random Forest, use LinearSVC for large datasets)
- What are inference speed characteristics?
- What are common production issues?

**Record findings:**
```
Research Findings:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Model Selection Thresholds:
  - Dataset size: [specific thresholds from research]
  - Feature count: [specific thresholds]
  - When to use alternatives: [specific scenarios]

Training Decisions:
  - Algorithm variants: [list with when to use each]
  - Loss function choices: [list with tradeoffs]
  - Performance characteristics: [time complexity, memory]

Critical Hyperparameters:
  - [Param 1]: Default=[value], Range=[values], Impact=[description]
  - [Param 2]: Default=[value], Range=[values], Impact=[description]
  - [Param 3]: Default=[value], Range=[values], Impact=[description]

Production Considerations:
  - Deployment optimizations: [list]
  - Common pitfalls: [list from research]
  - Performance tradeoffs: [findings]

Sources:
  - sklearn docs: {url}
  - Best practices: {urls}
  - Comparisons: {urls}
```

**3.4 Critical Code Assessment (REQUIRED):**

When reviewing user's lab code:
- ✅ **Validate correctness:** Check for errors, bugs, anti-patterns
- 🔧 **Suggest improvements:** Better practices, more efficient approaches (based on research above)
- 📝 **Document rationale:** Explain why original code works/doesn't work
- 🔍 **Compare with sklearn docs:** Verify parameters match documented defaults

Example:
```python
# User's code (from lab):
knn = KNeighborsClassifier(n_neighbors=5)
knn.fit(X_train, y_train)

# Assessment (based on sklearn docs + best practices research):
# ✅ Correct basic usage
# 🔧 Missing: Should use GridSearchCV to find optimal k (sklearn default n_neighbors=5 is arbitrary)
# 🔧 Missing: Should standardize features (KNN is distance-based - verified in sklearn docs)
# 📝 Improvement: Use Pipeline to prevent data leakage (best practice from research)
# 🔧 Missing: Should set n_jobs=-1 for parallelization (found in sklearn docs)
```

**3.5 Gap Filling (AUTONOMOUS):**

Compare user's notes with research findings:
- If user's notes missing hyperparameter → ADD from sklearn docs
- If user's notes missing "when NOT to use" → ADD from research
- If user's notes missing production considerations → ADD from best practices
- If user's notes have outdated info → UPDATE with current sklearn docs

**DO NOT ask user what to add. Research and decide yourself based on:**
1. What AI Engineers need for production deployment
2. What's documented in sklearn/official sources
3. What's recommended in authoritative best practices

**3.6 Model-Specific Theory Bloat Identification (NEW - CRITICAL):**

**After completing research, identify potential theory bloat for THIS specific model:**

**Purpose:** Create a "Theory Bloat Watchlist" to reference in Step 4 when writing.

**Method:** Based on sklearn docs and best practices research, identify content that:
- Appears in documentation BUT is theory-focused (not deployment-focused)
- Is mathematically interesting BUT not actionable
- Describes internals BUT doesn't inform production decisions

**Example for Linear Regression:**

```
Theory Bloat Watchlist for Linear Regression:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ AVOID (will fail filter tests):
- Normal Equation formula derivation (θ = (X^T X)^(-1) X^T y)
  → REPLACE WITH: "When training fails" scenarios (n_features ≥ n_samples → Use Ridge)
- fit_intercept=False edge cases ("physical law guarantees y=0")
  → REPLACE WITH: "Keep default fit_intercept=True for all production use cases"
- copy_X memory optimization
  → REPLACE WITH: Brief mention in parameter list only (1 line)
- SVD numerical stability details
  → REPLACE WITH: "sklearn handles this automatically"
- Matrix inversion internals
  → REPLACE WITH: Training time complexity and when to use SGDRegressor

✅ KEEP (passes filter tests):
- Normal Equation vs Gradient Descent comparison (informs algorithm choice)
- Ridge/Lasso/ElasticNet progression (production decision tree)
- VIF calculation for multicollinearity (diagnostic tool)
- Pipeline usage (prevents data leakage)
- Residual plot interpretation (diagnoses non-linearity)
```

**Generate this watchlist for {model_name} based on research:**

Ask yourself:
1. What formulas appear in sklearn docs? (check if they inform decisions or are just theory)
2. What parameters have <10% usage? (check sklearn docs examples, best practices articles)
3. What "advanced" or "edge case" sections exist in docs? (likely candidates for removal)
4. What internals are explained? (remove unless they prevent production failures)

**Document the watchlist:**
```
Theory Bloat Watchlist for {model_name}:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ AVOID:
- [Formula/concept]: [Why remove] → REPLACE WITH: [Actionable alternative]
- [Rare parameter]: [Why remove] → REPLACE WITH: [Brief mention or removal]
- [Edge case]: [Why remove] → REPLACE WITH: [Production default]

✅ KEEP:
- [Decision-focused content]: [Why keep]
- [Diagnostic tool]: [Why keep]
- [Production pattern]: [Why keep]
```

**Reference this watchlist in Step 4 before writing each section.**

**Sub-Agent B expected return (structured):**
```
SKLEARN URL: {url}
HYPERPARAMETERS: {count} total
  - {param}: default={value}, range={values}, impact={description}
  (one per line for all params)
HYPERPARAMETER INTERACTIONS: {param_a} × {param_b}: {description}
PARAM_GRID:
  '{param_1}': [{values}],
  '{param_2}': [{values}]
EXPECTED TUNING LENGTH: {n} lines (±20%)
BEST PRACTICES:
  - {url}: {practice} → use in § {section}
PITFALLS:
  - {name}: {problem} | detection: {how} | fix: {solution}
THEORY BLOAT WATCHLIST:
  REMOVE: {concept} → REPLACE WITH: {alternative}
  KEEP: {concept} — {why}
MODEL SELECTION:
  USE WHEN: {criteria}
  AVOID WHEN: {scenario} → use {alternative} instead
COMPARISONS:
  vs {Model_A}: {accuracy/speed/interpretability tradeoffs}
SOURCES: {url list}
```

---

**Checklist before proceeding to Step 4 (verify both sub-agents returned):**
- [ ] Sub-Agent A returned: lab file, code examples, user knowledge state
- [ ] Sub-Agent B returned: hyperparameters, best practices, pitfalls, Theory Bloat Watchlist

---

### Step 4: Generate Research Context Summary (v0.6.0 — Compile from Sub-Agent Outputs)

**Purpose:** Compile Sub-Agent A and B's structured returns into the Research Context Summary to pass to the Task Agent in Step 6.

**Main context only organizes — does NOT re-research anything.**

**4.1 Compile Research Context:**

```python
# Structure the research findings into a comprehensive summary
research_context_summary = f"""
## RESEARCH CONTEXT FOR TASK AGENT

**INSTRUCTIONS:** Use this context when generating sections 2-13. DO NOT re-research. All information below has been verified.

---

### 1. Lab Files & Code Examples

**Lab file path:** {lab_file_path}

**Key code to use (with line numbers):**
- Training example: {file}:{line_range} - {brief_description}
- Hyperparameter tuning: {file}:{line_range} - {brief_description}
- Evaluation: {file}:{line_range} - {brief_description}
- Visualization: {file}:{line_range} - {brief_description}

**Code improvements needed:**
- Issue 1: {description} → Fix: {improvement} → Use in: § {section_name}
- Issue 2: {description} → Fix: {improvement} → Use in: § {section_name}

---

### 2. Theory Bloat Watchlist (CRITICAL - ENFORCE DURING WRITING)

**❌ REMOVE (DO NOT WRITE THESE):**
- {Formula/concept}: {Why bloat} → REPLACE WITH: {Actionable alternative}
- {Rare parameter}: {Why bloat} → REPLACE WITH: {Brief mention or skip entirely}
- {Edge case}: {Why bloat} → REPLACE WITH: {Production default}
- {Academic method}: {Why bloat} → REPLACE WITH: {Standard production approach}

**✅ KEEP (Production-relevant content):**
- {Decision-focused content}: {Why keep} → Use in: § {section_name}
- {Diagnostic tool}: {Why keep} → Use in: § {section_name}
- {Production pattern}: {Why keep} → Use in: § {section_name}

**Examples of violations to avoid (from previous assessments):**
- ❌ ccp_alpha pruning path method (academic) → Use GridSearchCV instead
- ❌ Sequential tuning strategy "(For Understanding)" → Use combined GridSearchCV
- ❌ Hyperparameter interaction scenarios (tutorial) → GridSearchCV finds optimal combos
- ❌ Learning curve analysis (development tool) → CV scores detect overfitting

---

### 3. Hyperparameter Research (From sklearn docs - {sklearn_url})

**Total count: {hyperparameter_count} hyperparameters**

**Priority ranking:**
1. **{Param_1}** (CRITICAL)
   - Default: {value}
   - Recommended range: {values}
   - Impact: {description}
   - When to tune: {scenario}

2. **{Param_2}** (HIGH)
   - Default: {value}
   - Recommended range: {values}
   - Impact: {description}
   - When to tune: {scenario}

[Continue for all hyperparameters...]

**Hyperparameter interactions (if applicable):**
- {Param_A} × {Param_B}: {interaction_description}

**GridSearchCV param_grid (production-ready):**
```python
param_grid = {{
    '{param_1}': {values},
    '{param_2}': {values},
    # ... (comprehensive grid with realistic ranges)
}}
```

**Expected Hyperparameter Tuning section length:**
- Formula: 350 (base) + ({hyperparameter_count} × 15) = {expected_length} lines
- Acceptable range: {min_length}-{max_length} lines (±20% tolerance)

---

### 4. User's Knowledge State

**✅ User already knows (use their examples, don't re-explain):**
- {Concept_1}: Found in {file}:{section}
- {Concept_2}: Found in {file}:{section}
- {Concept_3}: Found in {file}:{section}

**❌ User missing (explain from research):**
- {Concept_1}: Source - {sklearn_docs / best_practices_url}
- {Concept_2}: Source - {sklearn_docs / best_practices_url}
- {Concept_3}: Source - {sklearn_docs / best_practices_url}

---

### 5. Production Best Practices (From research)

**Source 1: {url_1}**
- Practice: {description}
- Use in: § {section_name}

**Source 2: {url_2}**
- Practice: {description}
- Use in: § {section_name}

**Source 3: {url_3}**
- Practice: {description}
- Use in: § {section_name}

---

### 6. Common Pitfalls (Use in § Common Pitfalls section)

**From user's lab + research:**

1. **{Pitfall_1_name}**
   - Problem: {description}
   - Detection: {how_to_detect}
   - Fix: {solution}
   - Source: {user_lab / research_url}

2. **{Pitfall_2_name}**
   - Problem: {description}
   - Detection: {how_to_detect}
   - Fix: {solution}
   - Source: {user_lab / research_url}

[Continue for 5-8 pitfalls...]

---

### 7. Model Selection Criteria (Use in Mermaid diagram - Step 6)

**When to use {model_name}:**
- Dataset size: {threshold} (e.g., >1000 rows)
- Feature types: {criteria} (e.g., numeric, categorical, mixed)
- Performance needs: {criteria}
- Problem type: {regression/classification/clustering}
- Specific advantages: {list}

**When NOT to use {model_name} (exit paths in diagram):**
- Scenario 1: {description} → Use {alternative_model} instead
- Scenario 2: {description} → Use {alternative_model} instead
- Scenario 3: {description} → Use {alternative_model} instead

---

### 8. Comparison with Other Models (Use in § When to Use This Model)

**{model_name} vs {Model_A}:**
- Accuracy: {comparison}
- Training time: {comparison}
- Interpretability: {comparison}
- When to prefer {model_name}: {scenarios}
- When to prefer {Model_A}: {scenarios}

**{model_name} vs {Model_B}:**
- [Similar structure...]

---

### 9. Model-Specific Decisions (For various sections)

**Training Phase:**
- Algorithm choices: {list_with_when_to_use}
- Loss functions: {list_with_tradeoffs}
- Performance characteristics: {time_complexity, memory}

**Deployment Phase:**
- Model-specific optimizations: {list}
- Inference speed: {characteristics}
- Memory footprint: {size}

**Preprocessing Requirements:**
- MANDATORY: {list} (e.g., StandardScaler for SVM)
- OPTIONAL: {list} (e.g., PCA for dimensionality reduction)

---

### 10. Sources (Cite in § Resources section)

- sklearn documentation: {url}
- Best practices article 1: {url}
- Best practices article 2: {url}
- User's lab: {path}
- Model comparison research: {url}

---

**END OF RESEARCH CONTEXT**
"""

# Display summary
print(f"""
✅ Research Context Summary generated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Lab file: {lab_file_path}
- Hyperparameters: {hyperparameter_count}
- Pitfalls identified: {pitfall_count}
- Theory bloat items: {bloat_watchlist_count}
- Sources: {source_count}

This context will be passed to Task Agent in Step 5.
""")
```

**4.2 Validation:**

Verify research context includes:
- [ ] Lab file path and key code examples with line numbers
- [ ] Theory Bloat Watchlist (❌ REMOVE + ✅ KEEP items)
- [ ] All hyperparameters with defaults, ranges, priorities
- [ ] User's knowledge state (what they know vs missing)
- [ ] Production best practices with sources
- [ ] Common pitfalls with detection + fixes
- [ ] Model selection criteria (for diagram)
- [ ] Comparison with other models
- [ ] All sources for citations

---

### Step 5: Template Application (13 Sections)

**Template structure (from Random Forest + SVM workflows):**

1. § When to Use This Model
2. § Data Preparation (Model-Specific)
3. § Visualization (For This Model)
4. § Model Training (Model-Specific)
5. § Hyperparameter Tuning (Model-Specific)
6. § Evaluation Metrics (Model-Specific Priorities)
7. § Model Saving & Quantization
8. § Data Storage (If Model-Specific)
9. § Deployment (If Model-Specific)
10. § Common Pitfalls
11. § Quick Reference
12. § Example: Complete [Model Name] Workflow
13. § Resources

**Key patterns to follow:**

**§ When to Use This Model:**
- Data Characteristics (dataset size, feature count, data types)
- Problem Types (regression/classification/clustering)
- When [Model] Wins (✅ use cases)
- When NOT to Use [Model] (❌ anti-patterns)

**§ Data Preparation:**
- Feature Engineering (model-specific notes)
- Feature Selection (how this model handles it)
- Feature Scaling (if required)
- Handling Missing Values (if applicable)
- Categorical Encoding (if required)

**§ Hyperparameter Tuning:**
- List all important hyperparameters
- Default values
- Recommended ranges
- GridSearchCV example with comprehensive param_grid
- Impact of each parameter (with examples)

**§ Common Pitfalls:**
- List 5-10 common mistakes
- Explain why they happen
- Provide fixes

**§ Quick Reference:**
- Cheat sheet format
- One-liner commands
- Common patterns

**§ Example:**
- Complete end-to-end workflow
- Use user's lab code as base (with improvements)
- Include all steps from data loading to evaluation

---

**4.1 FILTER ENFORCEMENT AT WRITING TIME (CRITICAL - Apply to EVERY Section):**

**BEFORE writing EACH section, you MUST apply this filter:**

**The 4 Filter Tests (from Step 2.4):**

For EVERY paragraph you write, ask:

1. **Removal Test:** "If I remove this, will an AI Engineer fail to deploy {model}?"
   - If NO → DON'T WRITE IT
2. **Usage Threshold:** "Is this used in >10% of production projects?"
   - If NO → DON'T WRITE IT
3. **Decision Test:** "Does this help choose between algorithms/hyperparameters/approaches?"
   - If NO → DON'T WRITE IT
4. **Frequency Test:** "Is this widely known among mid-level AI Engineers?"
   - If NO → DON'T WRITE IT

**Red flags (instant removal - DO NOT WRITE):**

- You're about to write "rare in practice" → **STOP** - DELETE immediately
- You're about to write "edge case" → **STOP** - DELETE immediately
- You're about to write "for completeness" → **STOP** - DELETE immediately
- You're about to write mathematical derivation → **ASK:** "Does this inform a decision?" If NO → **DON'T WRITE**
- You're about to write parameter documentation → **ASK:** "Is this used >10%?" If NO → **DON'T WRITE**
- You're about to write "under the hood" explanation → **ASK:** "Does this prevent production failures?" If NO → **DON'T WRITE**

**Reference checks (before writing each section):**

- [ ] Re-read Theory Bloat Watchlist (from Step 3.6)
- [ ] Re-read Concrete Filter Tests (from Step 2.4.1)
- [ ] Check if content passes ALL 4 filter tests
- [ ] If ANY test fails → Don't write it OR find actionable alternative

**AFTER writing each section (before moving to next):**

- [ ] Re-read what you just wrote
- [ ] Apply 4 filter questions to EVERY paragraph
- [ ] Delete any paragraph that fails ANY question
- [ ] Verify no red flags present ("rare", "edge case", "for completeness")

**Example application during writing:**

```
About to write: "The Normal Equation θ = (X^T X)^(-1) X^T y is computed via SVD for numerical stability..."

Filter check:
- Removal Test: Will AI Engineer fail to deploy LR without knowing this? NO (sklearn does it)
- Decision Test: Does this help choose algorithm? NO (doesn't inform decisions)
→ VERDICT: DON'T WRITE THIS

Alternative: "Training is instant for most datasets (<10K features, <1 second). For larger datasets (>10K features), use SGDRegressor instead."

Filter check:
- Removal Test: Will AI Engineer fail to deploy? YES (need to know when to switch)
- Decision Test: Helps choose LinearRegression vs SGDRegressor? YES
→ VERDICT: WRITE THIS
```

**Enforcement discipline:**

- This is NOT optional
- This is NOT just for "theory-heavy" sections
- Apply to EVERY section, EVERY paragraph, EVERY time
- When in doubt → Apply the 4 tests

---

### Step 6: Incremental File Creation (Autonomous Agent Approach - v0.5.0)

**CRITICAL: Use Task tool for autonomous completion without repeated "Continue" prompts**

**Problem:**
- Workflows are 2,000-4,000 lines → outputting full content hits 16,384 token limit
- Manual "Continue" prompts slow down workflow generation and require constant user monitoring
- Need autonomous completion while preventing token errors

**Solution:** Create initial file with Section 1, then launch Task agent with full research context to complete remaining sections autonomously.

**v0.5.0 Improvement:** Task Agent now receives complete research context (assessment, Theory Bloat Watchlist, hyperparameters, pitfalls) from Step 4, eliminating the need to re-research.

---

**6.1 Create file with header + Section 1:**

```python
# Write initial file with complete Section 1
Write(
    file_path=destination_path,
    content=f"""# {model_name} - Complete Workflow

**Purpose:** Model-specific workflow for {model_name}. For general ML pipeline steps, see `ml_pipeline_complete_map.md`.

**What to reference vs include:**

| Content Type | Reference (generic) | Include (model-specific) |
|:-------------|:-------------------|:------------------------|
| **Versioning** | Directory structure, rollback procedures | Pipeline + metadata, model file naming |
| **Scaling** | Load balancing, auto-scaling, Kubernetes | Memory footprint, throughput, instance sizing |
| **Data Storage** | CSV vs Parquet vs database tradeoffs | Model size, parameter count, serialization |
| **Monitoring** | Prometheus, Grafana, alert rules | Latency thresholds (e.g., <1ms for LR), drift detection |
| **Deployment** | Docker, CI/CD, generic REST API patterns | Model-specific inference optimizations |

**How to reference:**
"For comprehensive versioning strategies, see `ml_pipeline_complete_map.md` → Phase 4: Deployment → Model Versioning."

---

## § When to Use This Model

[COMPLETE Section 1 content - data characteristics, when to use, when NOT to use, comparison with other models, decision tree]
"""
)
```

Display progress:
```
✅ Section 1/13 complete: When to Use This Model
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Progress: ▓▓░░░░░░░░░░░ 8%

Launching autonomous agent to complete sections 2-13...
```

---

**6.2 Launch Task agent for autonomous completion (v0.5.0 - WITH RESEARCH CONTEXT):**

```python
# Launch general-purpose agent to complete remaining 12 sections
# v0.5.0: Now includes full research context from Step 4
Task(
    subagent_type="general-purpose",
    description=f"Complete {model_name} workflow sections 2-13",
    prompt=f"""You are completing sections 2-13 of the {model_name} workflow file at: {destination_path}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{research_context_summary}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**CRITICAL: USE THE RESEARCH CONTEXT ABOVE**

- DO NOT re-search sklearn docs (already done)
- DO NOT re-read lab files (key examples provided above)
- DO NOT re-assess code (improvements listed above)
- DO NOT guess hyperparameters (verified values provided above)
- USE Theory Bloat Watchlist (section 2 above) during writing
- USE lab file path from section 1 above
- USE hyperparameter research from section 3 above
- USE common pitfalls from section 6 above

---

**Your task:**
Complete the remaining 12 sections using the Edit tool (one section per Edit call) to prevent token limit errors.

**Sections to add (in order):**
1. Section 2: § Data Preparation (Model-Specific)
   - Use preprocessing requirements from Research Context section 9
   - Use user's code examples from Research Context section 1

2. Section 3: § Visualization (For This Model)
   - Use user's visualization examples from Research Context section 1
   - Apply code improvements from Research Context section 1

3. Section 4: § Model Training (Model-Specific)
   - Use training decisions from Research Context section 9
   - Use user's training code from Research Context section 1

4. Section 5: § Hyperparameter Tuning (Model-Specific)
   - Use hyperparameters from Research Context section 3 ({hyperparameter_count} params)
   - Use GridSearchCV param_grid from Research Context section 3
   - Expected length: {expected_tuning_length} lines (±20%)

5. Section 6: § Evaluation Metrics (Model-Specific Priorities)
   - Use user's evaluation code from Research Context section 1

6. Section 7: § Model Saving & Quantization
   - Use deployment characteristics from Research Context section 9

7. Section 8: § Data Storage (If Model-Specific)
   - Reference ml_pipeline_complete_map.md for generic content

8. Section 9: § Deployment (If Model-Specific)
   - Use model-specific optimizations from Research Context section 9

9. Section 10: § Common Pitfalls
   - Use pitfalls from Research Context section 6 (already identified)
   - Format: Problem → Detection → Fix

10. Section 11: § Quick Reference
    - Cheat sheet format (concise)

11. Section 12: § Example: Complete {model_name} Workflow
    - Use user's lab code from Research Context section 1
    - Apply all improvements from Research Context section 1

12. Section 13: § Resources
    - Use sources from Research Context section 10

---

**CRITICAL REQUIREMENTS:**

1. **Token Limit Prevention:**
   - Use ONE Edit call per section (prevents hitting 16,384 token limit)
   - Each Edit adds ~200-400 lines (well under limit)
   - NEVER output section content in response text (use Edit tool only)

2. **Theory Bloat Watchlist ENFORCEMENT (Most Important):**
   - BEFORE writing ANY content, check Research Context section 2
   - If marked ❌ REMOVE → DON'T WRITE IT (use REPLACE WITH alternative)
   - If marked ✅ KEEP → Include it
   - Example violations to avoid:
     * ccp_alpha pruning path → Use GridSearchCV instead
     * Sequential tuning "(For Understanding)" → Use combined GridSearchCV
     * Hyperparameter interaction scenarios → GridSearchCV finds optimal combos
     * Learning curve analysis → CV scores detect overfitting

3. **Content Quality (Apply 4-Test Filter to EVERY paragraph):**
   - Removal Test: Will AI Engineer fail to deploy without this?
   - Usage Threshold: Used in >10% of production projects?
   - Decision Test: Helps choose between options?
   - Frequency Test: Widely known by mid-level AI Engineers?
   - If ANY test fails → DON'T WRITE IT

4. **RED FLAGS (instant removal):**
   - ❌ "rarely used" → DELETE
   - ❌ "rare in practice" → DELETE
   - ❌ "edge case" (without production justification) → DELETE
   - ❌ "for completeness" → DELETE
   - ❌ "advanced users only" → DELETE
   - ❌ "theoretical interest" → DELETE
   - ❌ Mathematical derivations that don't inform decisions → DELETE

5. **Use user's lab examples (from Research Context):**
   - Lab path: {lab_file_path} (from Research Context section 1)
   - Use examples with line numbers provided
   - Apply code improvements from section 1
   - Cite: (from your lab: {file}:{line_number})

6. **Reference generic content:**
   - Versioning strategies → Reference ml_pipeline_complete_map.md
   - Generic deployment patterns → Reference ml_pipeline_complete_map.md
   - Only include {model_name}-SPECIFIC content

7. **Section depth (follow Step 6.5 guidelines):**
   - Model Saving: 80-150 lines (simple) to 200-300 (complex)
   - Hyperparameter Tuning: {expected_tuning_length} lines (from Research Context section 3)
   - Common Pitfalls: Use exact pitfalls from Research Context section 6
   - Follow Random Forest/SVM workflow structure exactly

**Progress tracking:**
After EACH section, display:
```
✅ Section X/13 complete: [Section Name]
Progress: [progress bar] XX%
```

**When all 12 sections are complete:**
Display:
```
✅ All 13 sections complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Progress: ▓▓▓▓▓▓▓▓▓▓▓▓▓ 100%

Workflow file ready at: {destination_path}
Total lines: [count lines]

Proceeding to Step 7 (Mermaid diagram generation)...
```

**Template reference:**
Use these workflows as structure templates:
- /Users/monireach/tutorials/ai_engineering/01_Machine_Learning_with_Python/workflows/random_forest_workflow.md
- /Users/monireach/tutorials/ai_engineering/01_Machine_Learning_with_Python/workflows/svm_workflow.md

Study their structure and apply to {model_name}.

**REMEMBER:**
- You have full research context at the top of this prompt
- Don't re-research what's already provided
- Check Theory Bloat Watchlist before writing each paragraph
- Use user's code examples with line numbers provided
- Apply 4-Test Filter to everything
""",
    run_in_background=False  # Block until completion before proceeding to Step 7
)
```

---

**6.3 Agent completes sections 2-13 autonomously:**

The Task agent will:
- ✅ Use research context from Step 4 (no re-research needed)
- ✅ Check Theory Bloat Watchlist before writing each paragraph
- ✅ Add each section via separate Edit call (prevents token errors)
- ✅ Apply 4-test filter to all content (prevents violations)
- ✅ Use user's lab examples with line numbers provided
- ✅ Apply code improvements identified in research
- ✅ Reference generic content from ml_pipeline_complete_map.md
- ✅ Display progress after each section
- ✅ Complete all 12 sections without user "Continue" prompts

**User experience:**
- User sees progress updates automatically
- No need to monitor or type "Continue"
- Can do other work while agent completes workflow
- Notified when all sections complete

**Token management:**
- Main agent: Creates Section 1 (~500 tokens)
- Task agent: Adds 12 sections via 12 Edit calls (~200-400 tokens each)
- Total output per call: <500 tokens (well under 16,384 limit)
- No risk of token limit errors

**v0.5.0 Bloat Prevention:**
- Task Agent now has Theory Bloat Watchlist (catches violations during writing)
- Task Agent knows user's knowledge state (doesn't re-explain known concepts)
- Task Agent has verified hyperparameters (no guessing or hallucination)
- Task Agent has identified pitfalls (doesn't need to research common issues)
- Expected result: ±20% proportionality deviation (within tolerance)

---

**6.5 Section Depth Guidelines (Prevent Bloat):**

**Keep sections concise - 1-2 examples per concept, not exhaustive:**

**§ Model Saving & Quantization:**
- joblib vs pickle: Brief comparison table (5-10 lines)
- Pipeline saving: One example with explanation (20-30 lines)
- Metadata tracking: One example (15-20 lines)
- Compression: One benchmark IF model >10 MB (10-15 lines) OR skip if <10 MB
- Quantization: "Not applicable for simple models" (3 lines) OR full section for neural networks (50+ lines)
- Deployment example: One Flask API example (20-30 lines)
- **Total: 80-150 lines for simple models, 200-300 for complex models**

**§ Hyperparameter Tuning (CRITICAL - Refined Formula v0.4.0):**

**NEW: Refined Proportionality Formula (accounts for constant methodology overhead):**

```
Expected Length = Base Methodology + (Hyperparameter Count × Documentation Lines)

Where:
- Base Methodology = 300-400 lines (GridSearchCV, CV strategies, visualization, complete workflow)
- Documentation Lines = 10-20 lines per hyperparameter
```

**Why the refinement?**
- v0.3.0 formula (50-60 lines/param) assumed everything scales with hyperparameter count
- KNN assessment revealed: Methodology subsections (~400 lines) are relatively CONSTANT
- New formula separates constant overhead from variable hyperparameter documentation

**Reference Table (using refined formula):**

| Hyperparameter Count | Base Methodology | Param Docs | Expected Length | Example Models |
|:-------------------:|:----------------:|:-----------|:---------------:|:---------------|
| **≤5 params** | 350 lines | 5 × 15 = 75 | **425 lines** | Linear Regression, KNN |
| **6-10 params** | 350 lines | 10 × 20 = 200 | **550 lines** | Logistic Regression, Decision Tree |
| **11-15 params** | 350 lines | 15 × 15 = 225 | **575 lines** | SVM, Random Forest |
| **>15 params** | 350 lines | 20 × 20 = 400 | **750 lines** | XGBoost, Neural Networks |

**Acceptable deviation:** ±20% from expected length

**How to count hyperparameters:**
- Count ONLY parameters commonly tuned in production (>10% usage)
- Exclude: verbose, random_state, n_jobs (infrastructure, not tuning)
- Include: C, penalty, solver, max_iter, tol (affect model behavior)

**Example for Logistic Regression (10 hyperparameters):**
- C, penalty, solver, class_weight, max_iter, tol, l1_ratio, multi_class, warm_start, intercept_scaling
- Expected: 10 × 50-60 = **500-600 lines**
- Actual: 615 lines → ✅ Within acceptable range (+3% over upper bound)

**Required subsections (for comprehensive coverage):**
1. **Critical Hyperparameters (Priority Order)** - Show most important params first with ranges
2. **Hyperparameter Tuning Methods** - GridSearchCV, RandomizedSearchCV, model-specific CV
3. **Tuning for Different Goals** - Accuracy vs Precision vs Recall vs F1 vs ROC-AUC
4. **Cross-Validation Strategies** - StratifiedKFold, TimeSeriesSplit, GroupKFold (when to use each)
5. **Visualizing Tuning Results** - Validation curves, heatmaps (production-critical for diagnosing overfitting)
6. **Complete Tuning Workflow** - Pipeline integration (prevents data leakage in CV)
7. **Hyperparameter Tuning Checklist** - Quick reference for deployment

**What to exclude:**
- Parameters marked "rarely used" (Usage Threshold test)
- Parameters that don't affect production performance (e.g., verbose, warm_start)
- Solver implementation details (algorithm convergence proofs, optimizer theory)

**§ Common Pitfalls:**
- 5-8 pitfalls × 50-60 lines each = 250-480 lines total
- Each pitfall: Problem (10) + User's example (15) + Detection code (20) + Fix code (10)

**§ Deployment:**
- Simple models (LR, Logistic): 150-250 lines (already optimized, basic patterns)
- Complex models (Neural Nets, Large Ensembles): 300-500 lines (quantization, optimization)

**Guideline:** If a section exceeds these ranges, apply filter retroactively and remove bloat.

---

### Step 7: Generate Mermaid Diagram (CRITICAL - Apply Design Principles)

**🎯 GOLDEN RULE (User's Words):**

> "The chart shouldn't try to show WHAT IS INSIDE the file, instead it should show WHAT THE WORKFLOW IS with respect to the written workflow."

**What this means:**
- ✅ Diagram = Process flowchart (decisions, actions, branches, feedback loops)
- ❌ Diagram ≠ Documentation summary (don't visualize all 13 sections)

---

**7.1 MANDATORY: Start with Model Selection Decision Tree**

EVERY diagram MUST begin with model selection BEFORE model-specific workflow.

```mermaid
graph TB
    Start([ML Problem]) --> ModelSelect{Model Selection<br/>Decision Tree}

    %% Evaluate criteria - adapt per model
    ModelSelect --> DS{Large dataset?<br/>>1000 rows}
    DS -->|No| AltModel1[Consider: Logistic Regression<br/>Linear Models]
    DS -->|Yes| MixedFeat{Mixed feature types?<br/>Numeric + Categorical}

    MixedFeat -->|No, only categorical| AltModel2[Consider: Naive Bayes<br/>Decision Tree]
    MixedFeat -->|Yes| NeedInterp{Need interpretability?<br/>Feature importance}

    NeedInterp -->|No, need speed| AltModel3[Consider: XGBoost<br/>LightGBM]
    NeedInterp -->|Yes| TimeForTune{Time for tuning?<br/>Hyperparameter search}

    TimeForTune -->|No| AltModel4[Consider: Simpler Models]
    TimeForTune -->|Yes| ModelSuitable[✓ {Model Name} Suitable]

    %% Exit paths to alternative models
    AltModel1 --> EndNo([Exit: Choose Different Model])
    AltModel2 --> EndNo
    AltModel3 --> EndNo
    AltModel4 --> EndNo

    %% Continue to model-specific workflow
    ModelSuitable --> [Start of model-specific prep/training]
```

**⚡ Layout Optimization Tip:**

Define exit paths **immediately after** creating alternative model nodes for better visual positioning:

```mermaid
✅ GOOD - Immediate definition:
    DS -->|>1M samples| AltModel1[Consider: LinearSVC]
    AltModel1 --> EndNo([Exit: Choose Different Model])  ← Defined right away

    DS -->|10k-1M| NextDecision{...}  ← Continue with other paths

❌ BAD - Late definition:
    DS -->|>1M samples| AltModel1[Consider: LinearSVC]
    DS -->|10k-1M| NextDecision{...}
    ... [50 lines of other decisions]
    AltModel1 --> EndNo([Exit])  ← Defined too late = poor layout (node appears in center)
```

**Why this matters:** Mermaid's layout algorithm processes nodes sequentially. Defining exit paths immediately helps position them near their source nodes (left side), rather than in the center of the diagram.

---

**Evaluation Criteria (adapt per model):**
- Dataset size (e.g., ">1000 rows", "<1000 rows")
- Feature types (numeric, categorical, mixed)
- Interpretability needs (feature importance, black box acceptable)
- Training time constraints (hours acceptable, need real-time)
- Problem characteristics (non-linear, high-dimensional, etc.)

---

**7.2 Validate Every Fork (Critical - Avoid Pointless Forks)**

Before creating a fork, verify paths genuinely diverge.

**❌ BAD - Pointless Fork:**
```mermaid
ProbType{Problem Type?}
ProbType -->|Classification| ClassPath[Classification Path]
ProbType -->|Regression| RegPath[Regression Path]

ClassPath --> PrepClass[Data Preparation]
RegPath --> PrepReg[Data Preparation]

PrepClass --> CatEncode{Categorical Features?}  ← Both paths
PrepReg --> CatEncode{Categorical Features?}     ← do same thing, then merge
```
**Why bad:** Immediate merge after fork = no meaningful divergence.

**✅ GOOD - Meaningful Fork:**
```mermaid
ProbType{Problem Type?}
ProbType -->|Regression| LossReg[Loss: MSE + Info Gain]
ProbType -->|Classification| LossClass[Loss: Gini Index]

LossReg --> NextStep     ← Different actions
LossClass --> NextStep   ← before merging
```
**Why good:** Paths execute different actions (MSE vs Gini) before merging.

**Validation Checklist:**
- [ ] Do both paths execute different actions/operations?
- [ ] If they immediately merge, can I remove the fork entirely?
- [ ] Is the fork placed where paths ACTUALLY diverge, not earlier?

**Rule:** Fork only when paths genuinely diverge. If both do identical steps for 5 nodes, keep linear flow and fork only when they differ.

---

**7.3 Use Specific Criteria (NOT Vague Terms)**

**❌ BAD - Vague:**
- "Large dataset"
- "Many features"
- "Complex model"

**✅ GOOD - Specific:**
- "Dataset >1000 rows"
- "Features >100"
- "n_estimators: 50-500"
- "GridSearchCV (<100 combos)"
- "K-Fold CV (k=5 or 10)"

**Apply to:** Dataset size thresholds, feature count ranges, hyperparameter ranges, time/memory constraints, performance thresholds.

**⚡ Model Naming Specificity:**

When indicating model suitability, specify **exact sklearn class names**, not just family names:

```mermaid
✅ GOOD - Specific model classes:
    HighDim[✓ SVM Family Suitable<br/>High dimensions<br/>LinearSVC or SVC]

❌ VAGUE - Only family name:
    HighDim[✓ SVM handles<br/>high dimensions well]
```

**Why this matters:** Users need to know which specific sklearn classes to import and use. "SVM" is a family (LinearSVC, SVC, SVR, LinearSVR), not a single class. Be explicit about which models are suitable.

**Examples:**
- ✅ "Random Forest Family - RandomForestClassifier or RandomForestRegressor"
- ✅ "Linear Models - LinearRegression, Ridge, or Lasso"
- ❌ "Decision Trees work well" (specify: DecisionTreeClassifier or DecisionTreeRegressor)

---

**7.4 Add Feedback Loops (Optimization Patterns)**

**Standard Loop Pattern 1: Feature Importance Issues**
```mermaid
FeatImp[Feature Importance Plot] --> FeatCheck{Feature check?}
FeatCheck -->|<1% importance| RemoveWeak[Remove weak features]
FeatCheck -->|>70% dominance| InvestLeak[Investigate data leakage]

RemoveWeak --> Tuning[Hyperparameter Tuning]  ← Loop back
InvestLeak --> Tuning[Hyperparameter Tuning]   ← Loop back
```
**Why Tuning, not Training:** Fewer features may need different hyperparameters (max_features, min_samples_split).

**Standard Loop Pattern 2: Poor Performance**
```mermaid
PerfCheck{Performance?}
PerfCheck -->|Poor| Tuning[Hyperparameter Tuning]  ← Loop back
PerfCheck -->|Good| NextStep
```
**Why Tuning, not Training:** Hyperparameters are the optimization lever.

---

**7.5 Content Exclusions (Don't Visualize Documentation)**

**❌ REMOVE from diagram:**
- Common Pitfalls section
- Quick Reference section
- Example Code section
- Resources section

**✅ INCLUDE in diagram:**
- § When to Use This Model → Model Selection decision tree
- § Data Preparation → Encoding, splitting, CV decisions
- § Visualization → Pre/post training checks
- § Model Training → Parallelization, loss functions
- § Hyperparameter Tuning → All parameter decisions
- § Evaluation Metrics → Problem-type-specific metrics
- § Model Saving → Model-specific saving methods
- § Deployment → Model-specific optimizations only

---

**7.6 Apply Standard Styling**

Add at end of diagram:
```mermaid
%% Styling
style Start fill:#e1f5e1        %% Green - Entry point
style End fill:#e1f5e1          %% Green - Success endpoint
style EndNo fill:#f8d7da        %% Red - Exit/unsuitable
style ModelSuitable fill:#d4edda  %% Light green - Milestone
style ModelSelect fill:#fff3cd   %% Yellow - Critical decision
style Production fill:#d1ecf1    %% Light blue - Phase header
```

**Apply styling to:**
- All entry/exit points (Start, End, EndNo)
- Major milestones (ModelSuitable)
- Critical decision nodes (ModelSelect)
- Phase headers (Production, Evaluation, etc.)

---

**7.7 Typical Phase Structure**

**Linear vs Branching:**

1. **Model Selection** - Decision tree with exits (branching)
2. **Preparation** - Mostly linear (one decision for Stratified Sampling)
3. **Development** - Fork when problem type matters (loss functions, metrics)
4. **Visualization** - Fork for problem-type-specific plots
5. **Production** - Model-specific optimizations only

---

**7.8 Size Expectation**

**Reality:** Comprehensive decision-tree diagrams WILL overflow A4 page (likely A1 paper size).

**This is expected and acceptable** if showing all decision branches.

---

**7.9 Insert Diagram at Top of File**

```python
Read(destination_path)  # Get current content

Edit(
    file_path=destination_path,
    old_string="**Purpose:** Model-specific workflow...\n\n---\n\n## § When to Use",
    new_string="""**Purpose:** Model-specific workflow...

---

## Workflow Overview

```mermaid
[Complete diagram with all principles above]
```

---

## § When to Use"""
)
```

---

**6.10 Incremental Validation (CRITICAL)**

After generating diagram:
1. Inform user: "Diagram generated. Please render in browser and provide feedback."
2. User checks: A4 fit, logical flow, decision clarity, complexity level
3. User provides feedback
4. Fix issues (e.g., remove pointless forks, add missing connections)
5. Repeat until perfect

**Do NOT move to next workflow until current diagram is approved.**

---

### Step 8: Generate Table of Contents

**Create TOC with clickable links:**

```markdown
## Table of Contents

1. [Workflow Diagram](#workflow-diagram)
2. [When to Use This Model](#-when-to-use-this-model)
3. [Data Preparation (Model-Specific)](#-data-preparation-model-specific)
4. [Visualization (For This Model)](#-visualization-for-this-model)
5. [Model Training (Model-Specific)](#-model-training-model-specific)
6. [Hyperparameter Tuning (Model-Specific)](#-hyperparameter-tuning-model-specific)
7. [Evaluation Metrics (Model-Specific Priorities)](#-evaluation-metrics-model-specific-priorities)
8. [Model Saving & Quantization](#-model-saving--quantization)
9. [Data Storage (If Model-Specific)](#-data-storage-if-model-specific)
10. [Deployment (If Model-Specific)](#-deployment-if-model-specific)
11. [Common Pitfalls](#-common-pitfalls)
12. [Quick Reference](#-quick-reference)
13. [Example: Complete {Model Name} Workflow](#-example-complete-model-name-workflow)
14. [Resources](#-resources)
```

**Insert after mermaid diagram:**

```python
Edit(
    file_path=destination_path,
    old_string="```\n\n---\n\n## § When to Use",
    new_string="```\n\n## Table of Contents\n\n[TOC content]\n\n---\n\n## § When to Use"
)
```

---

### Step 9: General File Update Assessment

**After workflow complete:**

**9.1 Compare concepts used in this workflow vs general file:**

```python
# Read general workflow file
Read("ml_pipeline_complete_map.md")

# Check if new GENERAL concepts were discovered:
# - New preprocessing techniques used across multiple models
# - New evaluation metrics applicable to all models
# - New deployment patterns
# - New data handling strategies
```

**9.2 Identify new general concepts:**

Ask yourself:
- Is this concept MODEL-SPECIFIC or GENERAL?
- Is this already documented in general file?
- Would other models benefit from this?

Example:
- ✅ **General:** Stratified sampling (applies to all classification)
- ❌ **Model-specific:** RBF kernel tuning (SVM only)
- ✅ **General:** Pipeline pattern for preventing data leakage (all models)
- ❌ **Model-specific:** Feature importance extraction (tree models only)

**9.3 Update general file if needed:**

If new general concepts found:

```python
Edit(
    file_path="ml_pipeline_complete_map.md",
    old_string="[Relevant section]",
    new_string="[Section + new concept]"
)
```

Display update:
```
📝 General file updated:
- Added: Stratified sampling pattern
- Added: Pipeline usage for data leakage prevention
- Section: Phase 2 - Data Preparation
```

---

### Step 9.5: Content Review (MANDATORY - Before Completion)

**⚠️ CRITICAL: This step is MANDATORY. Do NOT proceed to Step 9 without completing ALL checks.**

**Purpose:** Apply filter retroactively to catch violations missed during writing.

---

**9.5.1 Automated Checks (Search for Red Flags):**

```python
# Read the entire workflow
workflow_content = Read(destination_path)

# Search for red flags with CONTEXT-AWARE patterns
red_flags = {
    "rarely_used": Grep(pattern="rarely used|rare in practice|rare, only when", path=destination_path, output_mode="content", -i=True),
    "edge_case": Grep(pattern="edge case", path=destination_path, output_mode="content", -i=True),
    "for_completeness": Grep(pattern="for completeness", path=destination_path, output_mode="content", -i=True),
}

# Display findings
for flag, matches in red_flags.items():
    if matches:
        print(f"⚠️ WARNING: Found '{flag}' in workflow - Review and likely DELETE")
        print(matches)
```

**IMPORTANT: Context-Aware Search Explained:**

We search for "rarely used|rare in practice|rare, only when" instead of just "rare" because:
- ✅ "rare categories" → NOT a violation (technical term describing data problem)
- ✅ "rare events" → NOT a violation (describes domain characteristic)
- ❌ "rarely used" → VIOLATION (marks parameter/content as infrequent)
- ❌ "rare in practice" → VIOLATION (marks content as uncommon)
- ❌ "rare, only when needed" → VIOLATION (suggests low usage)

**Action for each red flag found:**
- "rarely used" found → DELETE that content (violates Usage Threshold test)
- "rare in practice" found → DELETE that content (violates Usage Threshold test)
- "rare, only when" found → DELETE that content (violates Usage Threshold test)
- "edge case" found → DELETE that content (violates Frequency Test)
- "for completeness" found → DELETE that content (violates Removal Test)

---

**9.5.2 Manual Validation Checklist:**

**For EACH section (1-13), verify:**

```
Section-by-section validation:

§ When to Use This Model:
- [ ] No "rare use cases" mentioned
- [ ] All scenarios are common (>10% usage)
- [ ] Comparison with alternatives is actionable

§ Data Preparation:
- [ ] No rare parameters (<10% usage)
- [ ] All preprocessing steps are standard (Pipeline, StandardScaler, etc.)
- [ ] Examples are from production or user's labs

§ Model Training:
- [ ] No formula derivations (unless they inform decisions)
- [ ] No "under the hood" theory (unless prevents failures)
- [ ] Training scenarios are actionable (when to use X vs Y)

§ Hyperparameter Tuning:
- [ ] Only parameters used in >10% of projects
- [ ] All GridSearchCV examples use realistic ranges
- [ ] Each parameter section passes Decision Test (helps choose value)

§ Model Saving:
- [ ] No premature optimizations (compression for tiny models)
- [ ] Focus on Pipeline saving (critical for preprocessing)
- [ ] 1-2 examples per concept, not exhaustive

§ Deployment:
- [ ] Model-specific content only (generic references ml_pipeline_complete_map.md)
- [ ] Inference optimizations are relevant (not generic Docker/K8s)

§ Common Pitfalls:
- [ ] All pitfalls from user's labs OR common production failures
- [ ] Each includes: Problem + Detection + Fix
- [ ] No academic failure modes (<1% occurrence)
```

---

**9.5.3 Formula/Derivation Check:**

**For EVERY mathematical formula in the workflow:**

Ask: "Does this formula inform a production decision?"

**Examples:**

| Formula | Informs Decision? | Verdict |
|:--------|:------------------|:--------|
| θ = (X^T X)^(-1) X^T y | ❌ NO (sklearn does it, doesn't help choose algorithm) | **DELETE** |
| R² = 1 - (SS_res / SS_tot) | ✅ YES (helps understand when to trust model) | **KEEP** |
| Normal Equation vs Gradient Descent table | ✅ YES (helps choose algorithm) | **KEEP** |

**Action:** If formula doesn't inform a decision → DELETE or replace with actionable alternative.

---

**9.5.4 Parameter Documentation Check:**

**For EVERY sklearn parameter documented:**

Ask: "Is this parameter used in >10% of production projects?"

**Examples:**

| Parameter | Usage % | Verdict |
|:----------|:--------|:--------|
| fit_intercept=False | <1% | **DELETE** (keep only default True) |
| n_jobs=-1 | >50% | **KEEP** (common parallelization) |
| copy_X=False | <5% | **DELETE** (premature optimization) |
| alpha (Ridge/Lasso) | >80% | **KEEP** (critical hyperparameter) |

**Action:** If parameter usage <10% → DELETE detailed documentation (keep brief mention if in parameter list).

---

**9.5.5 Generic Content Check:**

**Verify all generic content is referenced, not duplicated:**

Check for these patterns and verify they reference `ml_pipeline_complete_map.md`:

- [ ] Versioning strategies → Referenced?
- [ ] Scaling patterns (load balancing, auto-scaling) → Referenced?
- [ ] Data storage formats (CSV vs Parquet) → Referenced?
- [ ] Generic monitoring (Prometheus, Grafana) → Referenced?
- [ ] Generic deployment (Docker, CI/CD) → Referenced?

**Action:** If generic content is duplicated → Edit to reference general file instead.

---

**9.5.6 Violations Found - Fix Before Proceeding:**

If ANY violations found:

```python
# Edit workflow to remove violations
Edit(
    file_path=destination_path,
    old_string="[Content with violation]",
    new_string="[Actionable alternative OR removal]"
)

# Re-run checks
# Repeat until ALL checks pass
```

**Display:**
```
⚠️ Content Review: Fixed {N} violations
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Violations fixed:
  • Removed "rare in practice" from fit_intercept section
  • Removed Normal Equation derivation (replaced with failure scenarios)
  • Referenced ml_pipeline_complete_map.md for versioning strategies
  • Deleted copy_X optimization (premature optimization)

Re-running validation checks... ✅ All checks passed
```

---

**9.5.7 Final Approval Gate:**

**ONLY proceed to Step 9 if:**

- [ ] Zero "rare" mentions found
- [ ] Zero "edge case" mentions found
- [ ] Zero "for completeness" mentions found
- [ ] All formulas inform decisions (or removed)
- [ ] All parameters have >10% usage (or removed)
- [ ] Generic content is referenced, not duplicated
- [ ] All sections pass manual validation checklist

**If ANY check fails:** Go back to Step 8.5.6 and fix violations.

**Do NOT proceed to Step 9 until this gate passes.**

---

**9.5.8 Proportionality Check (Self-Validation - v0.4.0 Refined Formula):**

**Purpose:** Verify Hyperparameter Tuning section length is proportional to hyperparameter count using refined formula.

```python
# Step 1: Count hyperparameters in "Critical Hyperparameters" subsection ONLY
# Look for numbered hyperparameters like "**1. C**", "**2. penalty**", etc.
# Use awk to extract only the Critical Hyperparameters subsection first
hyperparameter_section = Bash(
    command=f"awk '/^### Critical Hyperparameters/,/^### Hyperparameter Tuning Methods/' {destination_path}",
    description="Extract Critical Hyperparameters subsection"
)

# Count numbered items in this subsection
import re
hyperparameter_count = len(re.findall(r'^\*\*[0-9]+\.', hyperparameter_section, re.MULTILINE))

print(f"📊 Hyperparameter count detected: {hyperparameter_count}")

# Step 2: Measure Hyperparameter Tuning section length
# Use Bash to count lines between section markers
tuning_section_length = Bash(
    command=f"awk '/^## § Hyperparameter Tuning/,/^## § Evaluation Metrics/' {destination_path} | wc -l",
    description="Count lines in Hyperparameter Tuning section"
)

tuning_length = int(tuning_section_length.strip())
print(f"📏 Hyperparameter Tuning section: {tuning_length} lines")

# Step 3: Calculate expected range using REFINED FORMULA (v0.4.0)
# Formula: Base Methodology (350) + (Hyperparameter Count × 15)
base_methodology = 350
documentation_lines_per_param = 15

expected_length = base_methodology + (hyperparameter_count * documentation_lines_per_param)
min_expected = int(expected_length * 0.8)  # -20% tolerance
max_expected = int(expected_length * 1.2)  # +20% tolerance

print(f"🎯 Expected: {expected_length} lines ({min_expected}-{max_expected} with ±20% tolerance)")
print(f"   Formula: 350 (base) + ({hyperparameter_count} × 15) = {expected_length}")

# Step 4: Validate proportionality
if tuning_length < min_expected:
    print(f"⚠️ WARNING: Section is shorter than expected")
    print(f"   Current: {tuning_length} lines")
    print(f"   Expected: {min_expected}-{max_expected} lines")
    print(f"   → Check if critical hyperparameters or subsections are missing")
    print(f"   → Verify all 7 required subsections are present")
elif tuning_length > max_expected:
    print(f"⚠️ WARNING: Section is longer than expected")
    print(f"   Current: {tuning_length} lines")
    print(f"   Expected: {min_expected}-{max_expected} lines")
    print(f"   → Check for duplication or theory bloat")
    print(f"   → Apply filter tests to each subsection")
    print(f"   → Consider if parameters are 'rarely used'")
else:
    print(f"✅ Hyperparameter Tuning section length is PROPORTIONAL")
    print(f"   {tuning_length} lines for {hyperparameter_count} hyperparameters")
    print(f"   Average: {tuning_length / hyperparameter_count:.1f} lines per hyperparameter")
```

**What to do if check fails:**

**If TOO SHORT (< min_expected):**
- Verify all critical hyperparameters are documented
- Check if subsections 5-7 are missing (Visualization, Complete Workflow, Checklist)
- Add missing production-critical content

**If TOO LONG (> max_expected):**
- Re-apply filter tests (Removal, Usage Threshold, Decision, Frequency)
- Check for duplication between subsections
- Look for "rarely used" parameters and remove them
- Verify no theoretical derivations (solver convergence proofs, optimizer theory)

**Note:** This check uses refined formula (v0.4.0) that separates constant methodology (350 lines) from variable hyperparameter documentation (15 lines/param). This accounts for GridSearchCV, CV strategies, and visualization subsections that are relatively constant across models.

**v0.4.0 Refinement Rationale:**
- v0.3.0 formula (50-60 lines/param) assumed everything scales with hyperparameter count
- KNN assessment revealed: 506 lines for 5 params = 101.2 lines/param (2x expected)
- Root cause: Methodology subsections (~400 lines) are constant, not proportional
- New formula: Separates base 350 + (param_count × 15) for more accurate validation

---

### Step 10: Completion Message

Display final summary:

```
✅ Workflow Generation Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 File: {destination_path}
📊 Total sections: 13
📏 Total lines: {line_count}
🎨 Mermaid diagram: ✅ Generated
📑 Table of contents: ✅ Generated

Key features included:
  • When to use {Model Name} (with comparison to other models)
  • Complete hyperparameter tuning guide
  • Common pitfalls and fixes
  • End-to-end workflow example
  • {X} code examples from your lab

General file updates:
  • {List updates, or "None - no new general concepts"}

Sources cited:
  • User's lab: {lab_file}
  • sklearn docs: {sklearn_url}
  • {Other sources}

Next steps:
  1. Review workflow file for accuracy
  2. Test code examples in your environment
  3. Customize hyperparameter ranges for your data
```

---

## Important Guidelines

### Code Assessment Rules

**When reviewing user's lab code:**

1. **Validate correctness:**
   - Check for bugs, errors, anti-patterns
   - Verify sklearn API usage (correct parameters, methods)
   - Test logic correctness

2. **Suggest improvements:**
   - More efficient approaches
   - Better practices (Pipeline, cross-validation)
   - Missed optimizations

3. **Document rationale:**
   - Explain why original works/doesn't work
   - Explain why improvement is better
   - Provide before/after examples

4. **Preserve user's style:**
   - Keep variable names similar
   - Match code formatting
   - Maintain comment style

### Token Limit Handling

**CRITICAL: Never hit 16,384 token output limit**

Rules:
- NEVER output massive sections in response text
- ALWAYS use Write/Edit tools for content
- Keep response text to progress updates only
- Each section = one Edit call
- Response text per section < 200 tokens

Example BAD (will hit limit):
```
Section 1 complete. Here's Section 2:

[5,000 tokens of section content in response text]

Section 2 complete. Here's Section 3:

[5,000 tokens of section content in response text]
```

Example GOOD (won't hit limit):
```
✅ Section 2/13 complete: Data Preparation
Progress: ▓▓▓▓░░░░░░░░░ 15%
Type 'Continue' for next section
```

### Structural Consistency & Complexity-Driven Scope

**Follow the 13-section template structure:**

This enables pattern recognition and makes comparison easy for users.

**Template structure (consistent across all models):**
1. Workflow Overview (Mermaid diagram)
2. Table of Contents
3. § When to Use This Model
4. § Data Preparation (Model-Specific)
5. § Visualization (For This Model)
6. § Model Training (Model-Specific)
7. § Hyperparameter Tuning (Model-Specific)
8. § Evaluation Metrics (Model-Specific Priorities)
9. § Model Saving & Quantization
10. § Data Storage (If Model-Specific)
11. § Deployment (If Model-Specific)
12. § Common Pitfalls
13. § Quick Reference
14. § Example: Complete [Model Name] Workflow
15. § Resources

**Consistent formatting:**
- Same section header format (##, ###, ####)
- Same code block styles
- Same Mermaid diagram styling

**LET MODEL COMPLEXITY DETERMINE SCOPE:**

**DO NOT mechanically match other workflows' lengths or subsection counts.**

Instead, let the model's actual complexity drive the content:

**Simple models** (e.g., Linear Regression with Normal Equation):
- Fewer hyperparameters → Shorter tuning section
- Single training algorithm → Shorter training section
- May result in 2,000-3,000 lines total

**Complex models** (e.g., XGBoost, Neural Networks):
- Many hyperparameters → Longer tuning section with detailed interactions
- Multiple algorithm choices → Longer training section
- Many deployment optimizations → Longer deployment section
- May result in 4,000-6,000 lines total

**Medium complexity models** (e.g., SVM, Random Forest):
- Moderate hyperparameters → Medium tuning section
- Some variant choices (LinearSVC vs SVC) → Medium training section
- May result in 2,500-3,500 lines total

**Critical principle:**
- ✅ Length should reflect USEFUL content for AI Engineering work
- ❌ NOT based on "Random Forest is 1,800 lines, so mine should be similar"
- ✅ Depth should reflect model's ACTUAL decision points and complexity
- ❌ NOT based on arbitrary subsection count targets

**Quality indicators (from Random Forest and SVM):**
- ✅ Complete workflow diagram (all phases)
- ✅ Specific thresholds (">1000 rows" not "large dataset")
- ✅ Actionable focus (decisions, not theory)
- ✅ Concise subsections (no bloat, no redundant checklists)
- ✅ Critical filtering (AI Engineering relevant, not academic theory)
- ✅ Thorough research (sklearn docs, best practices cited)

**Differences between models:**
- Model-specific content (hyperparameters, preprocessing requirements)
- Model-specific examples (from user's lab + improvements)
- Model-specific workflow decisions (training algorithms, deployment optimizations)
- **Different section depths** based on complexity
- **Different total length** based on model's characteristics

### Citation Requirements

**Always cite sources:**

- User's lab code: `(from your lab: {file_path}:line_number)`
- sklearn docs: `(Source: sklearn docs - {url})`
- Research articles: `(Source: {title} - {url})`
- Best practices: `(Common practice in sklearn)`

### Comparison Requirements

**In "When to Use This Model" section:**

Always compare with:
- Similar models (e.g., KNN vs Logistic Regression for classification)
- Popular alternatives (Random Forest, XGBoost)
- User's lab results (if available)

Format:
```
### Comparison with Other Models

**{Model A} vs {Model B}:**
- Accuracy: 0.85 (Model A) vs 0.82 (Model B)
- Training time: 2.3s (Model A) vs 8.5s (Model B)
- When to prefer Model A: [scenarios]
- When to prefer Model B: [scenarios]
```

---

## Error Handling

### Lab File Not Found
- Inform user: "No lab file found for {model_name}"
- Offer: "Should I proceed with sklearn documentation only?"
- Wait for user confirmation

### Multiple Lab Files Found
- List all matches
- Ask user: "Which lab file should I use?"
- Wait for user selection

### Destination File Already Exists
- Inform user: "{destination_path} already exists"
- Ask: "Overwrite, rename, or cancel?"
- Wait for user decision

### General File Not Found
- Inform user: "General workflow file not found at {path}"
- Ask: "Proceed without general file updates?"
- Wait for user confirmation

---

## Quality Checklist

Before completing, verify:

**Workflow File:**
- [ ] All 13 sections present with correct headers
- [ ] User's lab code included as examples (with citations)
- [ ] Sklearn documentation researched and cited
- [ ] Hyperparameter defaults accurate (verified against sklearn)
- [ ] Comparison with other models included
- [ ] Common pitfalls section has 5-10 concrete issues
- [ ] Quick reference section is concise (cheat sheet format)
- [ ] Example section shows complete end-to-end workflow
- [ ] Resources section cites all sources
- [ ] General file updated if new concepts discovered
- [ ] Code improvements suggested (not just copied from lab)

**Mermaid Diagram (CRITICAL):**
- [ ] Starts with Model Selection decision tree (NOT assuming model chosen)
- [ ] Model Selection includes exit paths to alternative models
- [ ] All forks validated (no pointless forks that immediately merge)
- [ ] Decision criteria are specific (">1000 rows", "50-500", NOT vague terms)
- [ ] Feedback loops present (Feature Importance → Tuning, Performance → Tuning)
- [ ] Standard styling applied (Start/End green, Exit red, Milestones light green, Decisions yellow)
- [ ] Documentation sections excluded (Common Pitfalls, Quick Reference, Example, Resources)
- [ ] Diagram shows WORKFLOW (process, decisions, actions), NOT file contents
- [ ] Diagram placed at top of file (section titled "## Workflow Overview")
- [ ] User validation requested (render in browser, check fit/clarity/flow)

**Table of Contents:**
- [ ] TOC generated with clickable markdown links to all sections
- [ ] TOC placed after mermaid diagram, before first section

---

**END OF SKILL**
