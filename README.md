# Leakage-Aware Sepsis Prediction from Hourly ICU Data (MIMIC-IV)

**Focus:** methodology, leakage detection, evaluation, and reproducibility — not metric chasing.

---

## Overview
This repository presents an applied machine learning project on **early sepsis prediction** using hourly ICU data from the **MIMIC-IV** database.

The core goal is not to achieve maximal performance, but to demonstrate how to build a **leakage-aware, reproducible modeling pipeline** that would remain credible in a real clinical setting.

Key themes:
- SQL-first feature engineering and labeling
- Immutable, stay-level train/validation/test splits
- Baseline validation before nonlinear modeling
- Precision–Recall and calibration-focused evaluation
- Explicit discovery and correction of data leakage

---

## Reproducibility
- SQL feature generation and labeling are deterministic
- Train/validation/test splits are fixed and documented
- Modeling scripts mirror each other for fair comparison

---

## Reproduce locally (end-to-end)

### 0) Install dependencies
```bash
pip install -r requirements.txt
```

---

### 1) Build the derived tables (SQL)
This project assumes you have a local MIMIC-IV PostgreSQL instance with the required base and derived tables available.

Run the SQL scripts in roughly this order:

1. `sql/hourly/` — hourly concept tables  
2. `sql/labels/` — sepsis onset and 6-hour labeling  
3. `sql/features/` — model feature matrix  
4. `sql/splits/` — fixed train / validation / test split  
5. `sql/exports/` — export view for machine learning  

(Exact filenames may vary depending on your local setup.)

---

### 2) Export the ML table/view to CSV
`ml_export_6h.sql` defines a view used for model training. From `psql`, run:

```sql
\copy (
  SELECT * FROM mimiciv_derived.ml_export_6h
) TO 'ml_export_6h.csv' CSV HEADER;
```

Place `ml_export_6h.csv` in the **repository root** (same directory as `README.md`).

---

### 3) Train baseline models
From the repository root:

```bash
python scripts/train_logreg.py
python scripts/train_xgboost.py
```

This produces:
- `results/predictions_logreg.csv`
- `results/predictions_xgb.csv`
- `results/metrics_logreg.json`
- `results/metrics_xgb.json`

---

### 4) Evaluate models and generate figures
```bash
python scripts/evaluate.py
```

This generates:
- ROC curves → `results/figures/roc_*.png`
- Precision–Recall curves → `results/figures/pr_*.png`
- Calibration plots → `results/figures/calibration_*.png`

---

### 5) Expected output structure
After a successful run, your repository should contain:

```
results/
├── figures/
│   ├── roc_logreg.png
│   ├── roc_xgb.png
│   ├── pr_logreg.png
│   ├── pr_xgb.png
│   ├── calibration_logreg.png
│   └── calibration_xgb.png
├── predictions_logreg.csv
├── predictions_xgb.csv
├── metrics_logreg.json
└── metrics_xgb.json
```

---

## Problem Statement
Sepsis is a leading cause of ICU morbidity and mortality. Early detection is challenging because physiologic deterioration evolves gradually and is tightly coupled to clinician actions.

**Task:** Predict sepsis onset within a **6-hour horizon** using routinely available ICU data, while avoiding temporal and label leakage.

---

## Dataset
- **Source:** MIMIC-IV (PhysioNet)
- **Population:** Adult ICU stays
- **Resolution:** Hourly
- **Outcome:** `label_sepsis_6h`
- **Prevalence:** ~3%

All feature engineering, labeling, and data splitting were completed in SQL prior to modeling. Once exported, the database was treated as **immutable**.

No raw patient data are included in this repository.

---

## Dependencies

This project assumes that the official MIMIC-IV derived tables
from the `mimiciv-code` repository have already been created.

Specifically, the following tables are required:

- vitals_hourly
- labs_hourly_ml
- gcs_hourly
- urine_hourly
- icustay_static

These tables are generated using the official scripts from:
https://github.com/MIT-LCP/mimiciv-code

---

## Feature Engineering (SQL-First)
- Hourly aggregation aligned to ICU admission
- No backward-looking or future-aware features at prediction time
- Sparse labs retained with explicit *measured* indicators
- Fixed, stay-level data splits to prevent patient leakage

The final dataset contains **one row per `(stay_id, hour)`** with a fixed schema used by all models.

---

## Modeling Strategy

*No extensive hyperparameter tuning was performed; defaults were chosen to emphasize robustness over peak performance.*  
*The goal was to demonstrate correct modeling and evaluation practices rather than to optimize metrics through parameter search.*

### Baseline: Logistic Regression
**Purpose:**
- Sanity-check labels and splits
- Establish a calibrated reference
- Detect leakage early

**Approach:**
- L2-regularized logistic regression
- Median imputation
- Standard scaling

**Test performance (approximate):**
- AUROC ≈ 0.87
- AUPRC ≈ 0.22

Calibration and Precision–Recall curves showed plausible, clinically interpretable behavior.

---

### Nonlinear Model: XGBoost
**Purpose:**
- Capture nonlinear interactions
- Improve Precision–Recall performance
- Stress-test the pipeline for hidden leakage

Initial XGBoost results were unrealistically strong (AUROC ≈ 0.99, AUPRC ≈ 0.95), triggering a leakage audit.

---

## Leakage Discovery and Correction
Feature importance analysis revealed **temporally invalid features**, including:
- Explicit sepsis onset timing
- Future-looking SOFA aggregates

These features are **not available at prediction time** and constituted *hard leakage*. They were removed **at the modeling stage** (without modifying the database).

**Leak-free XGBoost results (test set, approximate):**
- AUROC ≈ 0.87
- AUPRC ≈ 0.28

This represents a meaningful improvement over the logistic baseline in a low-prevalence setting, without inflated discrimination.

---

## Evaluation
Primary evaluation focused on:
- **AUPRC** (preferred for low-prevalence outcomes)
- **AUROC** (secondary)
- **Calibration curves**
- **Precision–Recall curves**

Key observations:
- AUROC saturated early and remained stable across models
- AUPRC improved with nonlinear modeling
- Logistic regression showed the best calibration

---

## Lessons Learned
- Baseline models are diagnostic tools, not just benchmarks
- “Too-good-to-be-true” results should trigger audits, not celebration
- Nonlinear models amplify data leakage if present
- Feature legality matters more than feature importance
- AUPRC and calibration are more actionable than AUROC in clinical ML
- Freezing the data pipeline simplifies validation and reasoning

---

## Limitations
- Single prediction horizon (6 hours)
- No external validation cohort
- No prospective or deployment evaluation

---

## Possible Extensions
- Extend to 12h and 24h horizons
- Post-hoc calibration of tree-based models
- Translate thresholds into alert burden (e.g., alerts per 100 ICU-hours)

---

## Disclaimer
This project is for **research and educational purposes only** and is not intended for clinical deployment.
