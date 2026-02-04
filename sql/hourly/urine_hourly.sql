DROP TABLE IF EXISTS mimiciv_derived.urine_hourly;

CREATE TABLE mimiciv_derived.urine_hourly AS
SELECT
  h.stay_id,
  h.hr,

  -- 6-hour rolling urine output rate (mL/kg/hr)
  MAX(u.uo_mlkghr_6hr) AS uo_mlkghr_6hr

FROM mimiciv_derived.icustay_hourly h
LEFT JOIN mimiciv_derived.urine_output_rate u
  ON u.stay_id = h.stay_id
 AND u.charttime <= h.endtime

GROUP BY h.stay_id, h.hr;

CREATE INDEX ON mimiciv_derived.urine_hourly (stay_id, hr);
