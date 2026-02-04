DROP TABLE IF EXISTS mimiciv_derived.vitals_hourly;

CREATE TABLE mimiciv_derived.vitals_hourly AS
SELECT
  h.stay_id,
  h.hr,

  AVG(v.heart_rate)  AS heart_rate,
  AVG(v.mbp)         AS mbp,
  AVG(v.resp_rate)   AS resp_rate,
  AVG(v.temperature) AS temperature,
  AVG(v.spo2)        AS spo2

FROM mimiciv_derived.icustay_hourly h
LEFT JOIN mimiciv_derived.vitalsign v
  ON v.stay_id = h.stay_id
 AND v.charttime > h.endtime - INTERVAL '1 hour'
 AND v.charttime <= h.endtime

GROUP BY h.stay_id, h.hr;

CREATE INDEX ON mimiciv_derived.vitals_hourly (stay_id, hr);
