BEGIN;

SET work_mem = '256MB';
SET maintenance_work_mem = '2GB';
SET synchronous_commit = off;

DROP TABLE IF EXISTS mimiciv_derived.ml_features_hourly_clean;

CREATE TABLE mimiciv_derived.ml_features_hourly_clean AS
SELECT *
FROM mimiciv_derived.ml_features_hourly
WHERE sepsis_onset_hour IS NULL
   OR sepsis_onset_hour > 0;

-- Index for modeling / export
CREATE INDEX idx_ml_features_hourly_clean_stay_hour
ON mimiciv_derived.ml_features_hourly_clean (stay_id, hour);

ANALYZE mimiciv_derived.ml_features_hourly_clean;

COMMIT;
