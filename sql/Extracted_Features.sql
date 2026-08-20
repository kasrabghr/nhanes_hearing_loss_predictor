-- Audiological questionnaire

-- clean bmi_i features (BMI)
with clean_bmi as (
select seqn, bmxbmi
from bmx_i_raw
) 

-- clean demo_i features (Gender, Age, Military, Education L, Income to Poverty)
with clean_demo as (
select seqn, riagendr, ridageyr, dmqmiliz, dmd
from bmx_i_raw
) 

-- clean bpx_i features (Blood Pressure)
with clean_bpx as(
select seqn, COALESCE((bpxsy2 + bpxsy3) / 2.0, bpxsy2, bpxsy3) AS bpxsy_AVG
from bpx_i_raw
)

-- clean pbcd_i features (Lead, Cadmium)
with clean_pbcd as(
select seqn, lbxbpb, lbxbcd
from pbcd_i_raw
)

-- clean mcq_i features(Heart Disease/Attack, Stroke, Cancer)
with clean_mcq as(
select seqn, mcq160c, mcq160e, mcq160f, mcq220
from mcq_i_raw
)

-- clean diq_i features (Diabetes)
with clean_diq as(
select seqn, diq010
from diq_i_raw
)
