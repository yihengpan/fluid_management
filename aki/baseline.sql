DROP MATERIALIZED VIEW IF EXISTS baseline;
CREATE MATERIALIZED VIEW baseline AS

with co as(
select sofa_pan.subject_id, sofa_pan.hadm_id,gender,
ROUND( (CAST(adm.admittime AS DATE) - CAST(pt.dob AS DATE))  / 365.242, 4) AS age,
ethnicity,
sofa_pan.icustay_id,day,sofa,creatinine_max
from sofa_pan left join mimiciii.patients pt
on sofa_pan.subject_id = pt.subject_id
left join mimiciii.admissions adm
on sofa_pan.hadm_id = adm.hadm_id
and sofa_pan.subject_id = adm.subject_id
),
c1 as(
select subject_id, hadm_id, icustay_id,day,creatinine_max,
case when gender = 'M' and lower(ethnicity) like '%black%' and age>=20 and age <=24 then 1.5
when gender = 'M' and lower(ethnicity) like '%black%' and age>=25 and age <=29 then 1.5
when gender = 'M' and lower(ethnicity) like '%black%' and age>=30 and age <=39 then 1.4
when gender = 'M' and lower(ethnicity) like '%black%' and age>=40 and age <=65 then 1.3
when gender = 'M' and lower(ethnicity) like '%black%' and age>65then 1.2

when gender = 'M' and lower(ethnicity) not like '%black%' and age>=20 and age <=24 then 1.3
when gender = 'M' and lower(ethnicity) not like '%black%' and age>=25 and age <=29 then 1.2
when gender = 'M' and lower(ethnicity) not like '%black%' and age>=30 and age <=39 then 1.2
when gender = 'M' and lower(ethnicity) not like '%black%' and age>=40 and age <=54 then 1.1
when gender = 'M' and lower(ethnicity) not like '%black%' and age>=55 and age <=65 then 1.1
when gender = 'M' and lower(ethnicity) not like '%black%' and age>65 then 1.0

when gender = 'F' and lower(ethnicity)  like '%black%' and age>=20 and age <=24 then 1.2
when gender = 'F' and lower(ethnicity)  like '%black%' and age>=25 and age <=29 then 1.1
when gender = 'F' and lower(ethnicity)  like '%black%' and age>=30 and age <=39 then 1.1
when gender = 'F' and lower(ethnicity)  like '%black%' and age>=40 and age <=54 then 1.0
when gender = 'F' and lower(ethnicity)  like '%black%' and age>=55 and age <=65 then 1.0
when gender = 'F' and lower(ethnicity)  like '%black%' and age>65 then 0.9

when gender = 'F' and lower(ethnicity) not like '%black%' and age>=20 and age <=24 then 1.0
when gender = 'F' and lower(ethnicity) not like '%black%' and age>=25 and age <=29 then 1.0
when gender = 'F' and lower(ethnicity) not like '%black%' and age>=30 and age <=39 then 0.9
when gender = 'F' and lower(ethnicity) not like '%black%' and age>=40 and age <=54 then 0.9
when gender = 'F' and lower(ethnicity) not like '%black%' and age>=55 and age <=65 then 0.8
when gender = 'F' and lower(ethnicity) not like '%black%' and age>65 then 0.8

end as baseline
from co
),
baseline as(

select c1.*, creatinine_max/(baseline*1.0)as times from c1
)
select baseline.*,
case when times >= 3 then 3
when creatinine_max >= 4 then 3
when times>= 2 then 2
when creatinine_max>=baseline+0.3 then 1
when times>= 2.5 then 1
when creatinine_max is null then null
when times is null then null
else 0 end as aki_stage_creat
from baseline