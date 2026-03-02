CREATE INDEX IF NOT EXISTS idx_labevents_subject_charttime
ON mimiciv_hosp.labevents (subject_id, charttime);

CREATE INDEX IF NOT EXISTS idx_icustays_subject_intime_outtime
ON mimiciv_icu.icustays (subject_id, intime, outtime);

CREATE INDEX IF NOT EXISTS idx_labevents_itemid
ON mimiciv_hosp.labevents (itemid);
