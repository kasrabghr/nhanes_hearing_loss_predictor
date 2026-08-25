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
		end as firearm_usage_and_protection,

		-- Exposure to firearms
		case 
			when auq300 = 2 then 1 -- NO GUN
			when auq300 = 1 and auq310 = 1 then 2 -- SMALL EXPOSURE
			when auq300 = 1 and auq310 in (2, 3) then 3 -- MEDIUM EXPOSURE
			when auq300 = 1 and auq310 in (4, 5) then 4 -- A LOT EXPOSURE
			else null
		end as exposure_to_firearms,

		-- Loud noise at work
		case 
			when auq331 in (2, 3) or auq340 = 1 then 1 -- NO EXPOSURE
			when auq331 = 1 and auq340 in (2, 3, 4) then 2 -- LOW EXPOSURE
			when auq331 = 1 and auq340 in (5, 6, 7) then 3 -- HIGH EXPOSURE
			else null
		end as loud_noise_work,

		-- Very loud noise at work
		case 
			when auq350 = 2 or auq361 in (1, 8) then 1 -- NO EXPOSURE
			when auq350 = 1 and auq361 in (2, 3, 4) then 2 -- LOW EXPOSURE
			when auq350 = 1 and auq361 in (5,6,7) then 3 -- HIGH EXPOSURE
			else null
		end as very_loud_noise_work

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

-- Blood Pressure
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
