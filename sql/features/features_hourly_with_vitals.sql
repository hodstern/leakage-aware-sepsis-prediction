BEGIN;

-- =========================
-- Performance / safety
-- =========================
SET work_mem = '256MB';
SET maintenance_work_mem = '2GB';
SET synchronous_commit = off;

-- =========================
-- Drop if exists
-- =========================
DROP TABLE IF EXISTS mimiciv_derived.features_hourly_with_vitals;

-- =========================
-- Create features + vitals
-- =========================
CREATE TABLE mimiciv_derived.features_hourly_with_vitals AS
SELECT
    f.stay_id,
    f.hour,

    -- =========================
    -- Labs
    -- =========================
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

    -- =========================
    -- Vitals (from vitals_hourly)
    -- =========================
    v.heart_rate,
    v.mbp,
    v.resp_rate,
    v.temperature,
    v.spo2

FROM mimiciv_derived.features_hourly_base f
LEFT JOIN mimiciv_derived.vitals_hourly v
  ON f.stay_id = v.stay_id
 AND f.hour    = v.hr;

-- =========================
-- Index
-- =========================
CREATE INDEX idx_features_hourly_with_vitals_stay_hour
ON mimiciv_derived.features_hourly_with_vitals (stay_id, hour);

ANALYZE mimiciv_derived.features_hourly_with_vitals;

COMMIT;
