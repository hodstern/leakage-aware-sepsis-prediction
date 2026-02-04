DROP TABLE IF EXISTS mimiciv_derived.gcs_hourly;

CREATE TABLE mimiciv_derived.gcs_hourly AS
SELECT
  h.stay_id,
  h.hr,

  -- worst (lowest) GCS in the past hour
  MIN(g.gcs) AS gcs

FROM mimiciv_derived.icustay_hourly h
LEFT JOIN mimiciv_derived.gcs g
  ON g.stay_id = h.stay_id
 AND g.charttime > h.endtime - INTERVAL '1 hour'
 AND g.charttime <= h.endtime

GROUP BY h.stay_id, h.hr;

CREATE INDEX ON mimiciv_derived.gcs_hourly (stay_id, hr);
