
with uo_6hr as
(
  select
        uo.icustay_id
      -- , uo.charttime
      -- , uo.urineoutput_6hr
      , min(uo.urineoutput_6hr / uo.weight / 6.0)::numeric as uo6
	 , uo.day
	from
 kdigo_daily_uo uo
  group by uo.icustay_id,uo.day
),
uo_12hr as
(
  select
        uo.icustay_id
      -- , uo.charttime
      -- , uo.urineoutput_12hr
      , min(uo.urineoutput_12hr / uo.weight / 12.0)::numeric as uo12
	 , uo.day
	from
 kdigo_daily_uo uo
  group by uo.icustay_id,uo.day
),
uo_24hr as
(
  select
        uo.icustay_id
      -- , uo.charttime
      -- , uo.urineoutput_24hr
      , min(uo.urineoutput_24hr / uo.weight / 24.0)::numeric as uo24
	 , uo.day
	from
 kdigo_daily_uo uo
  group by uo.icustay_id,uo.day
),

-- stages for UO / creat

stage_uo as(
select uo_6hr.icustay_id,uo_6hr.day,uo6,uo12,uo24
, case 
 when UO24 < 0.3 then 3
      when UO12 = 0 then 3
      when UO12 < 0.5 then 2
      when UO6  < 0.5 then 1
      when UO6  is null then null
    else 0 end as aki_stage_uo

from 
            uo_6hr  
  left join uo_12hr on uo_6hr.icustay_id = uo_12hr.icustay_id
  					and uo_6hr.day = uo_12hr.day
  left join uo_24hr on uo_6hr.icustay_id = uo_24hr.icustay_id
  					and uo_6hr.day = uo_24hr.day
					
		
)

select sofa.icustay_id,coalesce(stage_uo.day,baseline.day) as day,uo6,uo12,uo24,
stage_uo.aki_stage_uo,baseline.aki_stage_creat
,baseline.creatinine_max,
case
      when AKI_stage_creat >= AKI_stage_uo then AKI_stage_creat
      when AKI_stage_uo > AKI_stage_creat then AKI_stage_uo
      else coalesce(AKI_stage_creat,AKI_stage_uo)
    end as AKI_stage
from sofa_pan as sofa
left join stage_uo 
on sofa.icustay_id = stage_uo.icustay_id
and sofa.day = stage_uo.day
left join baseline
on sofa.icustay_id = baseline.icustay_id
and sofa.day = baseline.day
where sofa.icustay_id in
(select icustay_id from icu_18)
order by icustay_id,day