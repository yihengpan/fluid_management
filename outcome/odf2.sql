--find the number of days that sofa score not null for each icustay, and find the occurrence for each icustay.
with co as
(select icu.subject_id,icu.hadm_id,icu.icustay_id,intime,outtime,count(*) as sofa_day ,
ROW_NUMBER() OVER (PARTITION BY icu.hadm_id ORDER BY intime) AS occurrence
from sofa_pan
left join mimiciii.icustays icu
on sofa_pan.icustay_id = icu.icustay_id
where sofa != 0
group by icu.subject_id,icu.hadm_id,icu.icustay_id,intime,outtime),


--find the first icu stay in each hospital stay 
--calculate the 28 days after the first icustay intime which is the hospital stay final time
c1 as
(select subject_id,hadm_id,intime as first_in,intime + interval '28 day' as final_day from co where occurrence = 1 ),

--find each icustay belonging to hospital stay final time
c2 as
(select co.subject_id,co.hadm_id,co.icustay_id,intime, outtime,sofa_day,occurrence,final_day,first_in
from co left join c1 
on co.subject_id = c1.subject_id 
and co.hadm_id = c1.hadm_id),

--only keep the duration is in final day icustay and look at its each day sofa score.
c3 as
(
select c2.*,day,sofa,
	ceiling((extract( epoch from final_day - intime))/60/60/24)
	as valid_day from c2 left join sofa_pan
on c2.icustay_id = sofa_pan.icustay_id
where intime < final_day
	and sofa>0 and day < ceiling((extract( epoch from final_day - intime))/60/60/24)
order by subject_id,hadm_id,icustay_id,day),

/*
--get patient date of death.
c4 as(
select c3.*,dod from c3 left join mimiciii.patients as pt
on c3.subject_id = pt.subject_id
order by hadm_id,intime
),
*/
c4 as (
select subject_id,hadm_id,icustay_id,intime,outtime,occurrence,final_day,first_in,valid_day,
count(*) as sofa_day  
from c3
group by subject_id,hadm_id,icustay_id,intime,outtime,occurrence,final_day,first_in,valid_day
),

a1 as(
select c4.*,
case when dod is not null and deathtime is not null and dod > deathtime then dod
when dod is not null and deathtime is not null and dod < deathtime then deathtime
when dod is null and deathtime is not null then deathtime
when dod is not null and deathtime is null then dod
else deathtime end as deathtime
from c4
left join mimiciii.patients pt
on c4.subject_id = pt.subject_id
left join mimiciii.admissions adm
on c4.hadm_id = adm.hadm_id

),

c5 as(
select a1.*,
case when deathtime < final_day then ceiling((extract( epoch from deathtime - first_in))/60/60/24) 
    else 28 end as per
	from a1
order by hadm_id,intime
),

c6 as
(select subject_id,hadm_id,sum(sofa_day) as sofa_day,per from c5
group by subject_id,hadm_id,per),

c7 as (
select c6.*,
case when (per - sofa_day)>0 then (per - sofa_day)
else 0 end
as odf
from c6
)

select icustay_id, c7.* from c7 left join icu_first
on c7.subject_id = icu_first.subject_id
and c7.hadm_id = icu_first.hadm_id


