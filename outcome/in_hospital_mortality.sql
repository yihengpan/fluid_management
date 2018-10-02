select ad.subject_id,ad.hadm_id,dischtime,deathtime,dod_hosp,
case when ad.dischtime>=pt.dod_hosp then 1
else 0 end as in_hospital_mortality 
from mimiciii.admissions ad

left join mimiciii.patients pt
on ad.subject_id=pt.subject_id
