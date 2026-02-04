CREATE OR REPLACE VIEW mimiciv_derived.ml_export_6h AS
SELECT
    f.*,
    s.split AS data_split
FROM mimiciv_derived.ml_features_hourly_clean f
JOIN mimiciv_derived.ml_stay_splits s
  ON f.stay_id = s.stay_id;
