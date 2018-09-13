--find the number of days that sofa score not null for each icustay, and find the occurrence for each icustay.
with co as
(select icu.subject_id,icu.hadm_id,icu.icustay_id,intime,outtime,count(*) as sofa_day ,
ROW_NUMBER() OVER (PARTITION BY icu.hadm_id ORDER BY intime) AS occurrence
from sofa_pan
left join mimiciii.icustays icu
on sofa_pan.icustay_id = icu.icustay_id
where sofa != 0
group by icu.subject_id,icu.hadm_id,icu.icustay_id,intime,outtime),

--find the 28 days after the first icustay intime
c1 as
(select subject_id,hadm_id,intime + interval '28 day' as final_day from co where occurrence = 1 ),

c2 as
(select co.subject_id,co.hadm_id,co.icustay_id,intime, outtime,sofa_day,occurrence,final_day
from co left join c1 
on co.subject_id = c1.subject_id 
and co.hadm_id = c1.hadm_id)
/*
select c2.*,
case when occurrence = 1 then sofa_day 
     when occurrence > 1 and intime < final_day and outtime < final_day then sofa_day
	 when occurrence > 1 and intime < final_day and outtime > final_day 
	 then min((DATE_PART('day', final_day::timestamp - intime::timestamp) + 1),sofa_day) 
	 else 0 end
	 as s
from c2
where occurrence != 1
*/
c3 as
(
select c2.*,day,sofa from c2 left join sofa_pan
on c2.icustay_id = sofa_pan.icustay_id
where intime < final_day
order by subject_id,hadm_id,icustay_id,day)

select c3.*,
case when 