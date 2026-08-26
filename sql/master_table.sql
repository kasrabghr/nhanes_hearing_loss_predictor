-- Audiological questionnaire
with auq as (
	select 
		seqn,
		
		-- Firearm usage and protection
		case 
			when auq300 = 2 then 1 -- NO GUN
			when auq300 = 1 and auq320 in (1, 2) then 2 -- GUN WITH > 50% PROTECTION
			when auq300 = 1 and auq320 in (3, 4, 5) then 3 -- GUN WITH =< 50% PROTECTION
			else null
		end as firearm_and_protection,

		-- Exposure to firearms
		case 
			when auq300 = 2 then 1 -- NO GUN
			when auq300 = 1 and auq310 = 1 then 2 -- SMALL EXPOSURE
			when auq300 = 1 and auq310 in (2, 3) then 3 -- MEDIUM EXPOSURE
			when auq300 = 1 and auq310 in (4, 5) then 4 -- A LOT EXPOSURE
			else null
		end as firearm_exposure_level,

		-- Loud noise at work
		case 
			when auq331 in (2, 3) or auq340 = 1 then 1 -- NO EXPOSURE
			when auq331 = 1 and auq340 in (2, 3, 4) then 2 -- LOW EXPOSURE
			when auq331 = 1 and auq340 in (5, 6, 7) then 3 -- HIGH EXPOSURE
			else null
		end as loud_noise,

		-- Very loud noise at work
		case 
			when auq350 = 2 or auq361 in (1, 8) then 1 -- NO EXPOSURE
			when auq350 = 1 and auq361 in (2, 3, 4) then 2 -- LOW EXPOSURE
			when auq350 = 1 and auq361 in (5,6,7) then 3 -- HIGH EXPOSURE
			else null
		end as very_loud_noise

from auq_i_raw
),


-- BMI
bmi as (
	select 
		seqn, 
		bmxbmi as bmi
from bmx_i_raw
), 


-- DEMO 
demo as (
	select 
		seqn, 
		riagendr as sex, -- 1 = MALE, 2 = FEMALE
		ridageyr as age, -- AGE
		
		-- Military service
		case 
			when DMQMILIZ = 2 then 1 -- NO MILITARY
			when DMQMILIZ = 1 then 2 -- YES MILITARY
			else null
		end as military_service,
		
		-- Education Level
		case 
			when DMDEDUC2 in (1, 2) then 1 -- BELOW HIGH SCHOOL
			when DMDEDUC2 = 3 then 2 -- HIGH SCHOOL
			when DMDEDUC2 in (4, 5) then 3 -- COLLEGE OR ABOVE
			else null
		end as education,

		--Income to Poverty Ratio
		INDFMPIR as income_poverty_ratio 
from demo_i_raw
), 


-- Systolic blood Pressure
bpx as(
	select 
		seqn, 
		COALESCE((bpxsy2 + bpxsy3) / 2.0, bpxsy2, bpxsy3) AS blood_pressure
from bpx_i_raw
),


-- Lead, Cadmium
pbcd as(
	select 
		seqn, 
		lbxbpb as lead, 
		lbxbcd as cadmium
from pbcd_i_raw
),


-- Heart Disease/Attack, Stroke, Cancer
mcq as(
	select 
		seqn, 
		case
			when mcq160c = 2 then 1 -- NO CORONARY
			when mcq160c = 1 then 2 -- YES CORONARY
			else null
		end as heart_disease,
		case
			when mcq160e = 2 then 1 -- NO HEART ATTACK
			when mcq160e = 1 then 2 -- YES HEART ATTACK
			else null
		end as heart_attack,
		case
			when mcq160f = 2 then 1 -- NO STROKE
			when mcq160f = 1 then 2 -- YES STROKE
			else null
		end as stroke,
		case
			when mcq220 = 2 then 1 -- NO CANCER
			when mcq220 = 1 then 2 -- YES CANCER
			else null
		end as cancer
from mcq_i_raw
),


-- Diabetes
diq as(
	select 
		seqn, 
		case
			when diq010 in (2,3) then 1 -- NO DIABETES
			when diq010 = 1 then 2 -- YES DIABETES
			else null
		end as diabetes
	from diq_i_raw
),


-- Audiometry Recode
aux as (
	select 
	seqn,
		-- right ear recoded thresholds
		case when auxu500r = 888 then null when auxu500r = 666 then 120 else auxu500r end as r500,
		case when auxu1k1r = 888 then null when auxu1k1r = 666 then 120 else auxu1k1r end as r1000,
		case when auxu2kr = 888 then null when auxu2kr = 666 then 120 else auxu2kr end as r2000,
		case when auxu4kr = 888 then null when auxu4kr = 666 then 120 else auxu4kr end as r4000,
		-- left ear recoded thresholds
		case when auxu500l = 888 then null when auxu500l = 666 then 120 else auxu500l end as l500,
		case when auxu1k1l = 888 then null when auxu1k1l = 666 then 120 else auxu1k1l end as l1000,
		case when auxu2kl = 888 then null when auxu2kl = 666 then 120 else auxu2kl end as l2000,
		case when auxu4kl = 888 then null when auxu4kl = 666 then 120 else auxu4kl end as l4000
	from aux_i_raw
	
),


-- PTA for each ear
pta as (
	select 
	seqn,
	
	-- Right Ear PTA
	(
	-- Avoiding division by null
	(coalesce(r500, 0) + coalesce(r1000, 0) + coalesce(r2000, 0) + coalesce(r4000, 0)) 
	/ nullif(
		(case when r500 is not null then 1 else 0 end +
		 case when r1000 is not null then 1 else 0 end +
		 case when r2000 is not null then 1 else 0 end +
		 case when r4000 is not null then 1 else 0 end ), 0)
	) as rpta,
	
	-- Left Ear PTA
	(
	(coalesce(l500, 0) + coalesce(l1000, 0) + coalesce(l2000, 0) + coalesce(l4000, 0)) 
	/ nullif(
		(case when l500 is not null then 1 else 0 end +
		 case when l1000 is not null then 1 else 0 end +
		 case when l2000 is not null then 1 else 0 end +
		 case when l4000 is not null then 1 else 0 end ), 0)
	) as lpta
	from aux
),


-- Worse ear PTA
wep as (
	select 
	seqn,
	case 
		when rpta is null then lpta
		when lpta is null then rpta
		else greatest (lpta, rpta) 
	end as wpta
	from pta
),


-- Hearing loss Severity / Presence
hl as (
	select
	seqn,
	case 
		when wpta is null then null
		when wpta <= 25 then 0 -- Normal
		when wpta <= 40 then 1 -- Mild
		when wpta <= 60 then 2 -- Moderate
		else 3 -- Severe
	end as HL_severity,
	case
		when wpta is null then null
		when wpta <= 25 then 0 -- No Hearing loss
		else 1 -- Yes Hearing loss
	end as HL_presence
	from wep
)


-- One join to rule them all ...
select 
	d.seqn,
	d.sex,
	d.age,
	d.military_service,
	d.education,
	d.income_poverty_ratio,
	a.firearm_and_protection,
    a.firearm_exposure_level,
    a.loud_noise,
    a.very_loud_noise,
    b.bmi,
    bp.blood_pressure,
    p.lead,
    p.cadmium,
    m.heart_disease,
    m.heart_attack,
    m.stroke,
    m.cancer,
    dq.diabetes,
	hl.hl_presence,
    hl.hl_severity
from 
	demo d 
left join auq a on d.seqn = a.seqn
left join bmi b on d.seqn = b.seqn
left join bpx bp on d.seqn = bp.seqn
left join pbcd p on d.seqn = p.seqn
left join mcq m on d.seqn = m.seqn
left join diq dq on d.seqn = dq.seqn
left join hl on d.seqn = hl.seqn;