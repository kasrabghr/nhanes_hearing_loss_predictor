# NHANES Master Table Data Dictionary

### Demographics
- **seqn**: Respondent sequence number (Identifier)
- **sex**: Biological sex
  - `0`: Male
  - `1`: Female
- **age**: Age in years at screening (Continuous)
- **military_service**: Active duty military service
  - `0`: No
  - `1`: Yes
- **education**: Education level
  - `1`: Below High School
  - `2`: High School
  - `3`: College or Above
- **income_poverty_ratio**: Ratio of family income to poverty line (Continuous)

### Occupational & Firearm Noise
- **firearm_and_protection**: Firearm usage and protection frequency
  - `1`: No Gun
  - `2`: Gun with >50% Protection
  - `3`: Gun with <=50% Protection
- **firearm_exposure_level**: Total firearm exposure volume
  - `1`: No Gun
  - `2`: Small Exposure
  - `3`: Medium Exposure
  - `4`: A Lot Exposure
- **loud_noise**: Loud noise at work
  - `1`: No Exposure
  - `2`: Low Exposure
  - `3`: High Exposure
- **very_loud_noise**: Very loud noise at work
  - `1`: No Exposure
  - `2`: Low Exposure
  - `3`: High Exposure

### Vitals & Biomarkers
- **bmi**: Body Mass Index (kg/m²)
- **blood_pressure**: Mean systolic BP (mmHg)
- **lead**: Blood lead concentration (ug/dL)
- **cadmium**: Blood cadmium concentration (ug/L)

### Medical Conditions (0 = No, 1 = Yes)
- **heart_disease**: Coronary heart disease
- **heart_attack**: Myocardial infarction
- **stroke**: Stroke
- **cancer**: Any malignancy
- **diabetes**: Doctor-diagnosed diabetes

### Target Outcomes
- **hl_presence**: Hearing Loss Indicator (WPTA > 25 dB)
  - `0`: No Hearing Loss (<= 25 dB)
  - `1`: Hearing Loss (> 25 dB)
- **hl_severity**: Hearing Loss Severity
  - `0`: Normal (<= 25 dB)
  - `1`: Mild (26–40 dB)
  - `2`: Moderate (41–60 dB)
  - `3`: Severe (> 60 dB)