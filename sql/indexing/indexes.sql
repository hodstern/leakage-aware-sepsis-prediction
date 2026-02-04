-- Speed-critical indexes (safe to run; IF NOT EXISTS avoids duplicates)

CREATE INDEX IF NOT EXISTS idx_labevents_subject_charttime
ON mimiciv_hosp.labevents (subject_id, charttime);

CREATE INDEX IF NOT EXISTS idx_icustays_subject_intime_outtime
ON mimiciv_icu.icustays (subject_id, intime, outtime);

-- Helps filtering by itemid
CREATE INDEX IF NOT EXISTS idx_labevents_itemid
ON mimiciv_hosp.labevents (itemid);
