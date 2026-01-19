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

## Reproducibility
- SQL feature generation and labeling are deterministic
- Train/validation/test splits are fixed and documented
- Modeling notebooks mirror each other for fair comparison

---

## Disclaimer
This project is for **research and educational purposes only** and is not intended for clinical deployment.
