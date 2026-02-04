DROP TABLE IF EXISTS mimiciv_derived.icustay_static;

CREATE TABLE mimiciv_derived.icustay_static AS
SELECT
  i.stay_id,
  p.gender,

  -- Correct age calculation in MIMIC-IV
  (p.anchor_age + EXTRACT(YEAR FROM i.intime) - p.anchor_year) AS age,

  a.admission_type,
  a.race
FROM mimiciv_icu.icustays i
JOIN mimiciv_hosp.admissions a
  ON i.hadm_id = a.hadm_id
JOIN mimiciv_hosp.patients p
  ON i.subject_id = p.subject_id;

UPDATE mimiciv_derived.icustay_static
SET age = NULL
WHERE age < 0 OR age > 120;

CREATE INDEX ON mimiciv_derived.icustay_static (stay_id);
