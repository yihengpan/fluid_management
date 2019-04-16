DROP MATERIALIZED VIEW IF EXISTS kdigo_daily_uo;
CREATE MATERIALIZED VIEW kdigo_daily_uo AS
with co as(
select icu.icustay_id,charttime,value,ceiling((extract( epoch from charttime - intime))/60/60/24) as day
from urineoutput uo
left join mimiciii.icustays icu
on uo.icustay_id = icu.icustay_id
order by icustay_id, day
),

ur_stg as
(
  select io.icustay_id,  io.charttime,io.day

  -- three sums:
  -- 1) over a 6 hour period
  -- 2) over a 12 hour period
  -- 3) over a 24 hour period
  , sum(case when iosum.charttime <= io.charttime + interval '5' hour
      then iosum.VALUE
    else null end) as UrineOutput_6hr
  , sum(case when iosum.charttime <= io.charttime + interval '11' hour
      then iosum.VALUE
    else null end) as UrineOutput_12hr
  , sum(iosum.VALUE) as UrineOutput_24hr
  from co io
  -- this join gives you all UO measurements over a 24 hour period
  left join co iosum
    on  io.icustay_id = iosum.icustay_id
    and iosum.charttime >=  io.charttime
    and iosum.charttime <= (io.charttime + interval '23' hour)
  group by io.icustay_id, io.charttime,io.day
)

select
  ur.icustay_id
, ur.charttime
, ur.day
, wt.weight
, ur.UrineOutput_6hr
, ur.UrineOutput_12hr
, ur.UrineOutput_24hr
from ur_stg ur
left join wt
  on  ur.icustay_id = wt.icustay_id

order by icustay_id, charttime;
