BEGIN;

SET work_mem = '256MB';
SET maintenance_work_mem = '2GB';
SET synchronous_commit = off;

DROP TABLE IF EXISTS mimiciv_derived.ml_features_hourly;

CREATE TABLE mimiciv_derived.ml_features_hourly AS
SELECT
    f.*,

    CASE
      WHEN s.sepsis3 = true
       AND s.sofa_time IS NOT NULL
      THEN FLOOR(EXTRACT(EPOCH FROM (s.sofa_time - ie.intime)) / 3600)::INT
      ELSE NULL
    END AS sepsis_onset_hour,

    CASE
      WHEN s.sepsis3 = true
       AND s.sofa_time IS NOT NULL
       AND FLOOR(EXTRACT(EPOCH FROM (s.sofa_time - ie.intime)) / 3600) > f.hour
       AND FLOOR(EXTRACT(EPOCH FROM (s.sofa_time - ie.intime)) / 3600) <= f.hour + 6
      THEN 1 ELSE 0
    END AS label_sepsis_6h

FROM mimiciv_derived.features_hourly_with_sofa f
LEFT JOIN mimiciv_derived.sepsis3 s
  ON f.stay_id = s.stay_id
JOIN mimiciv_icu.icustays ie
  ON f.stay_id = ie.stay_id;

CREATE INDEX idx_ml_features_hourly_stay_hour
ON mimiciv_derived.ml_features_hourly (stay_id, hour);

ANALYZE mimiciv_derived.ml_features_hourly;

COMMIT;

