-- Distribution of stays
SELECT split, COUNT(*) AS n_stays
FROM mimiciv_derived.ml_stay_splits
GROUP BY split;

-- Distribution of rows
SELECT s.split, COUNT(*) AS n_rows
FROM mimiciv_derived.ml_features_hourly_clean f
JOIN mimiciv_derived.ml_stay_splits s USING (stay_id)
GROUP BY s.split;

-- Label prevalence per split
SELECT
  s.split,
  ROUND(100.0 * SUM(label_sepsis_6h) / COUNT(*), 3) AS prevalence_pct
FROM mimiciv_derived.ml_features_hourly_clean f
JOIN mimiciv_derived.ml_stay_splits s USING (stay_id)
GROUP BY s.split;
