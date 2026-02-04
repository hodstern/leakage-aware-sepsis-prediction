-- ============================================================
-- Sepsis-3 6h prediction labels (ICU-based)
-- Exclusions:
--   B) remove sepsis on or shortly after ICU admission
--   A) remove early ICU hours
-- ============================================================

DROP TABLE IF EXISTS mimiciv_derived.sepsis_labels_6h;

CREATE TABLE mimiciv_derived.sepsis_labels_6h AS
WITH sepsis_onset AS (
    SELECT
        stay_id,
        GREATEST(suspected_infection_time, sofa_time) AS sepsis_onset_time
    FROM mimiciv_derived.sepsis3
),

-- B) exclude stays septic on admission or within 6h
eligible_stays AS (
    SELECT
        o.stay_id,
        o.sepsis_onset_time
    FROM mimiciv_derived.sepsis_onset o
    JOIN mimiciv_icu.icustays i USING (stay_id)
    WHERE
        o.sepsis_onset_time > i.intime + INTERVAL '6 hour'
        OR o.sepsis_onset_time IS NULL
),

-- attach onset to hourly grid
hourly_with_onset AS (
    SELECT
        h.stay_id,
        h.hr,
        h.endtime,
        e.sepsis_onset_time
    FROM mimiciv_derived.icustay_hourly h
    JOIN eligible_stays e
      ON h.stay_id = e.stay_id
)

-- final label table
SELECT
    stay_id,
    hr,
    endtime,
    CASE
        WHEN sepsis_onset_time IS NOT NULL
         AND endtime < sepsis_onset_time
         AND sepsis_onset_time <= endtime + INTERVAL '6 hour'
        THEN 1
        ELSE 0
    END AS label
FROM mimiciv_derived.hourly_with_onset
WHERE
    -- A) remove early ICU hours
    hr >= 6
    -- never include post-onset hours
    AND (
        sepsis_onset_time IS NULL
        OR endtime < sepsis_onset_time
    );
