BEGIN;

SET synchronous_commit = off;
SET work_mem = '256MB';
SET maintenance_work_mem = '2GB';
SET temp_buffers = '512MB';
SET enable_nestloop = off;

DROP TABLE IF EXISTS mimiciv_derived.labs_hourly_ml;

CREATE UNLOGGED TABLE mimiciv_derived.labs_hourly_ml AS
SELECT
    ie.stay_id,
    DATE_TRUNC('hour', le.charttime) AS hr,
    le.itemid,

    AVG(le.valuenum)  AS avg_valuenum,
    MIN(le.valuenum)  AS min_valuenum,
    MAX(le.valuenum)  AS max_valuenum,
    COUNT(*)          AS n_obs

FROM mimiciv_icu.icustays ie
JOIN mimiciv_hosp.labevents le
  ON le.subject_id = ie.subject_id
 AND le.charttime >= ie.intime
 AND le.charttime <= ie.outtime

WHERE
    le.valuenum IS NOT NULL

    -- Sepsis-relevant labs only
    AND le.itemid IN (
        50813, -- lactate
        50912, -- creatinine
        50971, -- potassium
        50983, -- sodium
        50902, -- chloride
        50882, -- bicarbonate
        50931, -- glucose
        50868, -- anion gap
        50885, -- bilirubin
        51265, -- platelets
        51301, -- WBC
        51222, -- hemoglobin
        -- optional adds:
        51221, -- hematocrit
        50960, -- magnesium
        50893  -- calcium
    )

    -- Prevent label leakage + reduce size
    AND le.charttime < ie.intime + INTERVAL '48 hour'

GROUP BY
    ie.stay_id,
    DATE_TRUNC('hour', le.charttime),
    le.itemid;

CREATE INDEX idx_labs_hourly_ml_stay_hr
ON mimiciv_derived.labs_hourly_ml (stay_id, hr);

CREATE INDEX idx_labs_hourly_ml_itemid
ON mimiciv_derived.labs_hourly_ml (itemid);

ANALYZE mimiciv_derived.labs_hourly_ml;

COMMIT;
