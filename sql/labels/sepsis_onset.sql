DROP TABLE IF EXISTS mimiciv_derived.sepsis_onset;

CREATE TABLE mimiciv_derived.sepsis_onset AS
SELECT
    stay_id,
    GREATEST(suspected_infection_time, sofa_time) AS sepsis_onset_time
FROM mimiciv_derived.sepsis3;
