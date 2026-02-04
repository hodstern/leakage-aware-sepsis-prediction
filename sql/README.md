# SQL Pipeline (MIMIC-IV Sepsis Prediction — 6h Horizon)

This directory contains all SQL required to reproduce the dataset used for
6-hour sepsis prediction from MIMIC-IV, including:

- sepsis onset and labeling logic
- hourly feature assembly
- deterministic train/validation/test splits
- final ML-ready export

Only project-specific SQL is included. Upstream concept code from
`mimiciv-code` is referenced but not copied.

---

## Directory layout

indexing/indexes.sql
  - optional performance indexes

labels/sepsis_onset.sql
  - defines sepsis onset per ICU stay

labels/sepsis_labels_6h.sql
  - generates hourly labels for 6h prediction horizon

hourly/icustay_static.sql
  - static ICU-stay level features

hourly/vitals_hourly.sql
  - hourly vital sign features

hourly/gcs_hourly.sql
  - hourly neurological features

hourly/urine_hourly.sql
  - hourly urine output features

hourly/labs_hourly_ml.sql
  - hourly laboratory features for ML

features/features_hourly_base.sql
  - base hourly time spine for modeling

features/features_hourly_with_vitals.sql
  - adds vital sign features

features/features_hourly_with_gcs.sql
  - adds GCS features

features/features_hourly_with_sofa.sql
  - adds SOFA-derived features (optional / exploratory)

features/ml_features_hourly.sql
  - consolidated hourly feature table

features/clean_ml_features_hourly.sql
  - final cleaned feature table used for modeling

splits/create_ml_splits.sql
  - deterministic train/val/test splits

splits/create_ml_splits_sanity.sql
  - verifies split integrity and leakage

exports/ml_export_6h.sql
  - final ML-ready dataset export

---

## Upstream dependency (not included)

This pipeline assumes the presence of standard derived tables commonly created
using the MIT-LCP `mimiciv-code` repository. These scripts are not vendored here
to preserve provenance and compatibility.

Expected upstream tables (or equivalents):

- vitals_hourly
- gcs_hourly
- urine_hourly
- labs_hourly_ml
- icustay_static

If these tables already exist in your database, you can proceed directly to
feature assembly.

---

## Execution order

### 0) Optional indexing

indexing/indexes.sql

Creates indexes to speed up joins and aggregations. Strongly recommended for
iterative development.

---

### 1) Labels

labels/sepsis_onset.sql  
Defines sepsis onset timing per ICU stay.

labels/sepsis_labels_6h.sql  
Generates hourly labels for a 6-hour prediction horizon.

---

### 2) Hourly inputs

hourly/

These scripts create or reference hourly and static input tables used for
feature engineering. All tables should align on stay_id and, for hourly tables,
on hr.

---

### 3) Feature assembly

features/features_hourly_base.sql  
Establishes the hourly time spine for modeling.

features/features_hourly_with_vitals.sql  
Adds vital sign features.

features/features_hourly_with_gcs.sql  
Adds neurological (GCS) features.

features/features_hourly_with_sofa.sql  
Adds SOFA-derived features (optional / exploratory).

features/ml_features_hourly.sql  
Produces a consolidated hourly feature table.

features/clean_ml_features_hourly.sql  
Final cleaned feature table used for modeling. Leakage-prone or post-onset
variables are removed here.

---

### 4) Train / validation / test splits

splits/create_ml_splits.sql  
Creates deterministic data splits (typically by patient).

splits/create_ml_splits_sanity.sql  
Verifies split sizes and checks for patient leakage.

---

### 5) Final ML export

exports/ml_export_6h.sql  

Joins final features, labels, and splits and produces the dataset consumed by
downstream Python ML code. This script defines the final contract between SQL
and modeling.

---

## What is considered final?

Final feature table:
- features/clean_ml_features_hourly.sql

Final dataset export:
- exports/ml_export_6h.sql

All modeling results should be reproducible from these outputs.

---

## Minimal run (assuming hourly inputs already exist)

1. labels/sepsis_onset.sql
2. labels/sepsis_labels_6h.sql
3. features/features_hourly_base.sql
4. features/features_hourly_with_vitals.sql
5. features/features_hourly_with_gcs.sql
6. features/clean_ml_features_hourly.sql
7. splits/create_ml_splits.sql
8. exports/ml_export_6h.sql
