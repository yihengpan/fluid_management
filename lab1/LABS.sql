
DROP MATERIALIZED VIEW IF EXISTS labs1 CASCADE;
create materialized view labs1 as
SELECT
  pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.day

  , max(CASE WHEN label = 'LACTATE' THEN valuenum ELSE null END) as LACTATE_max
  , max(CASE WHEN label = 'SODIUM' THEN valuenum ELSE null END) as SODIUM_max
  , max(CASE WHEN label = 'Potassium' THEN valuenum ELSE null END) as Potassium_max
  , max(CASE WHEN label = 'ALBUMIN' THEN valuenum ELSE null END) as ALBUMIN_max
  , min(CASE WHEN label = 'BICARBONATE' THEN valuenum ELSE null END) as BICARBONATE_min
  , max(CASE WHEN label = 'CREATININE' THEN valuenum ELSE null END) as CREATININE_max
  , max(CASE WHEN label = 'CHLORIDE' THEN valuenum ELSE null END) as CHLORIDE_max
  , max(CASE WHEN label = 'GLUCOSE' THEN valuenum ELSE null END) as GLUCOSE_max
  , min(CASE WHEN label = 'HEMOGLOBIN' THEN valuenum ELSE null END) as HEMOGLOBIN_min
  , min(CASE WHEN label = 'PLATELET' THEN valuenum ELSE null END) as PLATELET_min
  , min(CASE WHEN label = 'Potassium' THEN valuenum ELSE null END) as POTASSIUM_min
  , max(CASE WHEN label = 'INR' THEN valuenum ELSE null END) as INR_max
  , max(CASE WHEN label = 'BUN' THEN valuenum ELSE null end) as BUN_max
  , max(CASE WHEN label = 'WBC' THEN valuenum ELSE null end) as WBC_max
  , min(CASE WHEN label = 'BILIRUBIN, TOTAL' THEN valuenum ELSE null end) as BILIRUBIN_min
  , min(CASE WHEN label = 'CALCIUM, TOTAL' THEN valuenum ELSE null end) as CALCIUM_TOTAL_min
  , min(CASE WHEN label = 'CALCIUM, IONIZED' THEN valuenum ELSE null end) as CALCIUM_IONIZED_min
  , max(CASE WHEN label = 'AST(SGOT)' THEN valuenum ELSE null end) as AST_SGOT_max
  , max(CASE WHEN label = 'AMYLASE' THEN valuenum ELSE null end) as AMYLASE_max  
  , max(CASE WHEN label = 'LIPASE' THEN valuenum ELSE null end) as LIPASE_max 
  , max(CASE WHEN label = 'C-REACTIVE PROTEIN' THEN valuenum ELSE null end) as C_REACTIVE_PROTEIN_max  
  
FROM
( -- begin query that extracts the data
  SELECT ie.subject_id, ie.hadm_id, ie.icustay_id, ceiling((extract( epoch from le.charttime - ie.intime))/60/60/24) as day
  -- here we assign labels to ITEMIDs
  -- this also fuses together multiple ITEMIDs containing the same data
  , CASE
      WHEN ITEMID = 50862 THEN 'ALBUMIN' 
      WHEN ITEMID = 50882 THEN 'BICARBONATE'
      WHEN ITEMID = 50885 THEN 'BILIRUBIN, TOTAL'
      WHEN ITEMID = 50912 THEN  'CREATININE'
      WHEN ITEMID = 50902 THEN  'CHLORIDE'
      WHEN ITEMID = 50806 THEN 'CHLORIDE'
      WHEN ITEMID = 50931 THEN   'GLUCOSE'
      WHEN ITEMID = 50809 THEN  'GLUCOSE'
      WHEN ITEMID = 51222 THEN  'HEMOGLOBIN'
      WHEN ITEMID = 50811  THEN  'HEMOGLOBIN'
      WHEN ITEMID = 50813  THEN  'LACTATE'
      WHEN ITEMID = 51265  THEN  'PLATELET'
      WHEN ITEMID = 51237  THEN  'INR'
      WHEN ITEMID = 50983  THEN  'SODIUM'
      WHEN ITEMID = 50824  THEN  'SODIUM'
      WHEN ITEMID = 51006  THEN  'BUN'
      WHEN ITEMID = 51301  THEN  'WBC'
      WHEN ITEMID = 51300  THEN  'WBC'
		WHEN ITEMID = 50822  THEN  'Potassium'
		WHEN ITEMID = 50971  THEN  'Potassium'
		WHEN ITEMID = 50893  THEN  'CALCIUM, TOTAL'
		WHEN ITEMID = 50808  THEN  'CALCIUM, IONIZED'
		WHEN ITEMID = 50878  THEN  'AST(SGOT)'
		WHEN ITEMID = 50867  THEN  'AMYLASE'
		WHEN ITEMID = 50956  THEN  'LIPASE'
		WHEN ITEMID = 50889  THEN  'C-REACTIVE PROTEIN'
      ELSE null
    END AS label , valuenum
  /*
	, -- add in some sanity checks on the values
  -- the where clause below requires all valuenum to be > 0, so these are only upper limit checks
    CASE
      WHEN itemid = 50862 and valuenum >    10 THEN null -- g/dL 'ALBUMIN'
      WHEN itemid = 50868 and valuenum > 10000 THEN null -- mEq/L 'ANION GAP'
      WHEN itemid = 51144 and valuenum <     0 THEN null -- immature band forms, %
      WHEN itemid = 51144 and valuenum >   100 THEN null -- immature band forms, %
      WHEN itemid = 50882 and valuenum > 10000 THEN null -- mEq/L 'BICARBONATE'
      WHEN itemid = 50885 and valuenum >   150 THEN null -- mg/dL 'BILIRUBIN'
      WHEN itemid = 50806 and valuenum > 10000 THEN null -- mEq/L 'CHLORIDE'
      WHEN itemid = 50902 and valuenum > 10000 THEN null -- mEq/L 'CHLORIDE'
      WHEN itemid = 50912 and valuenum >   150 THEN null -- mg/dL 'CREATININE'
      WHEN itemid = 50809 and valuenum > 10000 THEN null -- mg/dL 'GLUCOSE'
      WHEN itemid = 50931 and valuenum > 10000 THEN null -- mg/dL 'GLUCOSE'
      WHEN itemid = 50810 and valuenum >   100 THEN null -- % 'HEMATOCRIT'
      WHEN itemid = 51221 and valuenum >   100 THEN null -- % 'HEMATOCRIT'
      WHEN itemid = 50811 and valuenum >    50 THEN null -- g/dL 'HEMOGLOBIN'
      WHEN itemid = 51222 and valuenum >    50 THEN null -- g/dL 'HEMOGLOBIN'
      WHEN itemid = 50813 and valuenum >    50 THEN null -- mmol/L 'LACTATE'
      WHEN itemid = 51265 and valuenum > 10000 THEN null -- K/uL 'PLATELET'
      WHEN itemid = 50822 and valuenum >    30 THEN null -- mEq/L 'POTASSIUM'
      WHEN itemid = 50971 and valuenum >    30 THEN null -- mEq/L 'POTASSIUM'
      WHEN itemid = 51275 and valuenum >   150 THEN null -- sec 'PTT'
      WHEN itemid = 51237 and valuenum >    50 THEN null -- 'INR'
      WHEN itemid = 51274 and valuenum >   150 THEN null -- sec 'PT'
      WHEN itemid = 50824 and valuenum >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
      WHEN itemid = 50983 and valuenum >   200 THEN null -- mEq/L == mmol/L 'SODIUM'
      WHEN itemid = 51006 and valuenum >   300 THEN null -- 'BUN'
      WHEN itemid = 51300 and valuenum >  1000 THEN null -- 'WBC'
      WHEN itemid = 51301 and valuenum >  1000 THEN null -- 'WBC'
    ELSE le.valuenum
    END AS valuenum
*/

FROM icu_18 ie

  LEFT JOIN mimiciii.labevents le
    ON le.subject_id = ie.subject_id AND le.hadm_id = ie.hadm_id
	
    AND le.ITEMID in

    (
      -- comment is: LABEL | CATEGORY | FLUID | NUMBER OF ROWS IN LABEVENTS
     
      50862, -- ALBUMIN | CHEMISTRY | BLOOD | 146697
      50882, -- BICARBONATE | CHEMISTRY | BLOOD | 780733
      50885, -- BILIRUBIN, TOTAL | CHEMISTRY | BLOOD | 238277
      50912, -- CREATININE | CHEMISTRY | BLOOD | 797476
      50902, -- CHLORIDE | CHEMISTRY | BLOOD | 795568
      50806, -- CHLORIDE, WHOLE BLOOD | BLOOD GAS | BLOOD | 48187
      50931, -- GLUCOSE | CHEMISTRY | BLOOD | 748981
      50809, -- GLUCOSE | BLOOD GAS | BLOOD | 196734
      51222, -- HEMOGLOBIN | HEMATOLOGY | BLOOD | 752523
      50811, -- HEMOGLOBIN | BLOOD GAS | BLOOD | 89712
      50813, -- LACTATE | BLOOD GAS | BLOOD | 187124
      51265, -- PLATELET COUNT | HEMATOLOGY | BLOOD | 778444
      51237, -- INR(PT) | HEMATOLOGY | BLOOD | 471183
      50983, -- SODIUM | CHEMISTRY | BLOOD | 808489
      50824, -- SODIUM, WHOLE BLOOD | BLOOD GAS | BLOOD | 71503
      51006, -- UREA NITROGEN | CHEMISTRY | BLOOD | 791925
      51301, -- WHITE BLOOD CELLS | HEMATOLOGY | BLOOD | 753301
      51300,  -- WBC COUNT | HEMATOLOGY | BLOOD | 2371
		50822, -- Potassium, Whole Blood | BLOOD GAS | BLOOD | 192949
		50971, -- Potassium | CHEMISTRY | BLOOD | 845737
		50893, -- CALCIUM, TOTAL | CHEMISTRY | BLOOD | 591932
		50808, -- CALCIUM, IONIZED | BLOOD GAS | BLOOD | 249110
		50878, -- AST(SGOT) | CHEMISTRY | BLOOD | 219452
		50867, -- AMYLASE | CHEMISTRY | BLOOD | 63664
		50956, -- LIPASE | CHEMISTRY | BLOOD | 65373
		50889 -- C-REACTIVE PROTEIN | CHEMISTRY | BLOOD | 6604
    )
    AND valuenum IS NOT null AND valuenum > 0 -- lab values cannot be 0 and cannot be negative
	where    le.charttime BETWEEN (ie.intime) AND (ie.outtime)
) pvt
GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, day
ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, day;


--let charttime between intime and outtime
--add day