BEGIN;

SET work_mem = '256MB';
SET maintenance_work_mem = '2GB';
SET synchronous_commit = off;

DROP TABLE IF EXISTS mimiciv_derived.features_hourly_base;

CREATE TABLE mimiciv_derived.features_hourly_base AS
SELECT
    ih.stay_id,
    ih.hr AS hour,

    l.lactate_avg,
    l.lactate_max,
    l.lactate_measured,

    l.creatinine_avg,
    l.creatinine_max,
    l.creatinine_measured,

    l.potassium_avg,
    l.potassium_max,
    l.potassium_measured,

    l.sodium_avg,
    l.sodium_max,
    l.sodium_measured,

    l.chloride_avg,
    l.chloride_max,
    l.chloride_measured,

    l.bicarbonate_avg,
    l.bicarbonate_max,
    l.bicarbonate_measured,

    l.glucose_avg,
    l.glucose_max,
    l.glucose_measured,

    l.aniongap_avg,
    l.aniongap_max,
    l.aniongap_measured,

    l.bilirubin_avg,
    l.bilirubin_max,
    l.bilirubin_measured,

    l.platelets_avg,
    l.platelets_max,
    l.platelets_measured,

    l.wbc_avg,
    l.wbc_max,
    l.wbc_measured,

    l.hemoglobin_avg,
    l.hemoglobin_max,
    l.hemoglobin_measured

FROM mimiciv_derived.icustay_hourly ih
LEFT JOIN mimiciv_derived.labs_hourly_ml_wide l
  ON ih.stay_id = l.stay_id
 AND ih.hr = l.hour

WHERE ih.hr BETWEEN 0 AND 47;

CREATE INDEX idx_features_hourly_base_stay_hour
ON mimiciv_derived.features_hourly_base (stay_id, hour);

ANALYZE mimiciv_derived.features_hourly_base;

COMMIT;
