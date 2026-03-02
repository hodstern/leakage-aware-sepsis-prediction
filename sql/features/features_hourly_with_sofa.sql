BEGIN;

SET work_mem = '256MB';
SET maintenance_work_mem = '2GB';
SET synchronous_commit = off;

DROP TABLE IF EXISTS mimiciv_derived.features_hourly_with_sofa;

CREATE TABLE mimiciv_derived.features_hourly_with_sofa AS
SELECT
    f.stay_id,
    f.hour,

    f.lactate_avg,
    f.lactate_max,
    f.lactate_measured,

    f.creatinine_avg,
    f.creatinine_max,
    f.creatinine_measured,

    f.potassium_avg,
    f.potassium_max,
    f.potassium_measured,

    f.sodium_avg,
    f.sodium_max,
    f.sodium_measured,

    f.chloride_avg,
    f.chloride_max,
    f.chloride_measured,

    f.bicarbonate_avg,
    f.bicarbonate_max,
    f.bicarbonate_measured,

    f.glucose_avg,
    f.glucose_max,
    f.glucose_measured,

    f.aniongap_avg,
    f.aniongap_max,
    f.aniongap_measured,

    f.bilirubin_avg,
    f.bilirubin_max,
    f.bilirubin_measured,

    f.platelets_avg,
    f.platelets_max,
    f.platelets_measured,

    f.wbc_avg,
    f.wbc_max,
    f.wbc_measured,

    f.hemoglobin_avg,
    f.hemoglobin_max,
    f.hemoglobin_measured,

    f.heart_rate,
    f.mbp,
    f.resp_rate,
    f.temperature,
    f.spo2,

    f.gcs_total,

    s.sofa_24hours        AS sofa_total_24h,

    s.respiration         AS sofa_respiration,
    s.coagulation         AS sofa_coagulation,
    s.liver               AS sofa_liver,
    s.cardiovascular      AS sofa_cardiovascular,
    s.cns                 AS sofa_cns,
    s.renal               AS sofa_renal

FROM mimiciv_derived.features_hourly_with_gcs f
LEFT JOIN mimiciv_derived.sofa s
  ON f.stay_id = s.stay_id
 AND f.hour    = s.hr;

CREATE INDEX idx_features_hourly_with_sofa_stay_hour
ON mimiciv_derived.features_hourly_with_sofa (stay_id, hour);

ANALYZE mimiciv_derived.features_hourly_with_sofa;

COMMIT;
