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

--only keep the duration is in final day icustay and look at its each day sofa score.
c3 as
(
select c2.*,day,sofa from c2 left join sofa_pan
on c2.icustay_id = sofa_pan.icustay_id
where intime < final_day
order by subject_id,hadm_id,icustay_id,day),

--find each later icustay's valid day.
c4 as
(
select c3.*, (DATE_PART('day', final_day::timestamp - intime::timestamp) + 1) as valid_day
from c3 where occurrence > 1),

--keep later icustay stay which in valid duration
c5 as(
select subject_id,hadm_id,icustay_id,intime,outtime,count(*) as sofa_day,occurrence,final_day,first_in
from c4 
where sofa > 0 and day < valid_day 
group by subject_id,hadm_id,icustay_id,intime,outtime,occurrence,final_day,first_in
order by subject_id,hadm_id,icustay_id
),

--find the first icu stay information
c6 as(
select co.*,intime + interval '28 day' as final_day,intime as first_in from co where occurrence = 1),

--combine all the useful icustay information into one table.
c7 as(select * from c5 union select * from c6),

--get patient date of death.
c8 as(
select c7.*,dod from c7 left join mimiciii.patients as pt
on c7.subject_id = pt.subject_id
order by hadm_id,intime
),

c9 as
(select c8.* ,
case when dod < final_day then DATE_PART('day', dod::timestamp - first_in::timestamp) + 1
else 28 end
as per
from c8 ),

c10 as
(select subject_id,hadm_id,sum(sofa_day) as sofa_day,per from c9
group by subject_id,hadm_id,per)

select subject_id,hadm_id,(per - sofa_day) as odf
from c10
