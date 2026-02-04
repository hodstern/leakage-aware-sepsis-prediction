BEGIN;

DROP TABLE IF EXISTS mimiciv_derived.ml_stay_splits;

-- One row per ICU stay
CREATE TABLE mimiciv_derived.ml_stay_splits AS
SELECT
  stay_id,
  CASE
    WHEN rnd < 0.70 THEN 'train'
    WHEN rnd < 0.85 THEN 'val'
    ELSE 'test'
  END AS split
FROM (
  SELECT
    stay_id,
    random() AS rnd
  FROM (
    SELECT DISTINCT stay_id
    FROM mimiciv_derived.ml_features_hourly_clean
  ) s
) t;

CREATE INDEX idx_ml_stay_splits_stay
ON mimiciv_derived.ml_stay_splits (stay_id);

ANALYZE mimiciv_derived.ml_stay_splits;

COMMIT;
