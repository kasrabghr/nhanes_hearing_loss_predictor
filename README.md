# Hearing Loss Risk Prediction from Routine Health Indicators (NHANES 2015–2016)

> **Predicting the presence of clinical hearing impairment using demographic, occupational, and systemic health data from the CDC's National Health and Nutrition Examination Survey (NHANES) — without requiring an audiometric exam.**

---

## Why This Project

As a clinical audiologist transitioning into computer science, this project represents an effort to bridge healthcare domain knowledge with predictive machine learning. 

Hearing loss is one of the most widespread chronic sensory impairments worldwide, yet it remains significantly underdiagnosed. Standard diagnosis requires specialized acoustic equipment, sound-isolated testing booths, and trained clinicians. Consequently, millions of adults with progressive hearing loss remain undetected until their communication and quality of life are substantially degraded.

At the same time, the primary etiological drivers of hearing impairment—aging, occupational and recreational noise history, cardiovascular vitals, and metabolic disorders like diabetes—are routinely gathered during standard primary-care visits and electronic health record (EHR) screenings. This project explores whether routine health indicators can serve as an accessible, cost-effective screening tool: flagging individuals at elevated risk of hearing loss and recommending them for timely, diagnostic audiometric evaluations.

---

## Data

The dataset is derived from the **CDC NHANES 2015–2016 cycle**, integrating eight distinct survey modules:
- **Demographics (`DEMO_I`)**: Age, biological sex, educational attainment, income-to-poverty ratio, military service.
- **Audiometry Exam (`AUX_I`)**: Pure-tone air-conduction hearing thresholds (500 Hz to 8000 Hz) measured in a dedicated sound booth.
- **Audiological Questionnaire (`AUQ_I`)**: Self-reported exposure to occupational noise, firearm discharge, and hearing protection usage.
- **Blood Pressure (`BPX_I`)**: Mean systolic blood pressure measurements.
- **Body Measures (`BMX_I`)**: Body Mass Index (BMI).
- **Laboratory Biomarkers (`PBCD_I`)**: Blood lead and cadmium concentrations.
- **Medical Conditions (`MCQ_I`)**: Self-reported history of coronary heart disease, heart attack, stroke, and cancer.
- **Diabetes (`DIQ_I`)**: Doctor-diagnosed diabetes status.

The raw SAS transport files (`.XPT`) are downloaded directly from CDC servers, loaded into a local containerized PostgreSQL database, and consolidated into an analytical master table through structured SQL transformations.

### Target Definition
- **`hl_presence` (Primary Target)**: A binary classification target derived from gold-standard pure tone averages (PTA). Following clinical audiological guidelines, the worse-ear PTA across 0.5, 1, 2, and 4 kHz was calculated. A threshold of **PTA > 25 dB HL** defines the presence of clinically significant hearing loss (`1`), while $\le 25\text{ dB HL}$ indicates normal hearing (`0`).
- **`hl_severity` (Extended Outcome)**: Stratified into four clinical tiers: *Normal* ($\le 25\text{ dB}$), *Mild* ($26\text{–}40\text{ dB}$), *Moderate* ($41\text{–}60\text{ dB}$), and *Severe* ($> 60\text{ dB}$). While preserved for future multiclass modeling, current predictive experiments focus on binary screening (`hl_presence`).

Detailed schema and column descriptions: [`sql/data_dictionary.md`](sql/data_dictionary.md)

---

## Pipeline

The end-to-end data pipeline is structured for full reproducibility across engineering, exploration, and modeling phases:

| Step | Action (Script / Notebook) | Input | Output | Description |
| :--- | :--- | :--- | :--- | :--- |
| **1. Ingestion** | `src/raw_data_downloader.py` | CDC Web Server | `data/raw/*.XPT` | Automated download of 8 survey modules |
| **2. Database Load** | `src/raw_data_to_postgress_loader.py` | `data/raw/*.XPT` | PostgreSQL Database | Ingests raw XPT files into PostgreSQL tables |
| **3. Query & ETL** | `sql/nhanes_master_table_query.sql`<br>(via `src/processed_sql_to_csv.py`) | PostgreSQL Database | `data/processed/raw_master_table.csv` | Joins survey modules, recodes survey logic, calculates PTA |
| **4. Exploration** | `notebooks/eda.ipynb` | `raw_master_table.csv` | `post_eda_master_table.parquet` | Distribution checks, missingness correlation, feature analysis |
| **5. Cleaning & Split** | `notebooks/cleaning.ipynb` | `post_eda_master_table.parquet` | `cleaned_train.parquet`<br>`cleaned_test.parquet` | Structural imputation, biomarker experiments, stratified 80/20 split |
| **6. Modeling** | `notebooks/feature_preparing.ipynb` | `cleaned_train/test.parquet` | Final Model Pipeline | Feature scaling, 5-fold CV benchmark, $F_2$ threshold tuning |

---

## Results

### 1. Exploratory Data Analysis (EDA)

The post-query study cohort contains **3,248 adult participants** aged 20–69 with complete audiometric exams, evaluated across **22 candidate predictors**. All exploratory figures are cataloged in [`images/eda_results/`](images/eda_results/).

#### Missingness Architecture & Survey Logic
Missing data analysis confirmed that missingness in NHANES is non-random and largely structural:
- **Skip-Logic Missingness**: Questions regarding very loud occupational noise (`very_loud_noise`) and firearm protection frequency (`firearm_and_protection`) were skipped for participants answering "No" to parent screening questions, causing ~67% structural nulls that represent genuine non-exposure rather than missing records.
- **Biomarker Subsampling**: Heavy metals (`lead` and `cadmium`) were absent in ~55% of respondents because NHANES tests toxicological panels only on a designated random laboratory subsample.

![Figure 1: Missingness Correlation Heatmap](images/eda_results/Figure%201%20-%20Correlation%20Heatmap%20for%20NULL%20Values.png)

#### Feature Distributions
- **Continuous Variables**: Age shows a balanced, uniform distribution across adult age brackets due to survey sampling design. BMI and systolic blood pressure follow approximately normal curves with mild right skewness, while blood heavy metals (lead, cadmium) are heavily right-skewed.
- **Ordinal & Categorical Features**: The majority of survey respondents report minimal or no occupational noise exposure and no firearm handling. College-level education represents the most frequent educational tier. Binary medical comorbidities (heart disease, stroke, cancer) are low-prevalence in this non-institutionalized sample.

![Figure 2: Distribution of Continuous Features](images/eda_results/Figure%202%20-%20Distribution%20of%20Continuous%20Features.png)
![Figure 3: Distribution of Ordinal Features](images/eda_results/Figure%203%20-%20Distribution%20of%20Ordinal%20Features.png)
![Figure 4: Prevalence of Binary Features](images/eda_results/Figure%204%20-%20Prevalence%20%26%20Percentage%20of%20binary%20features.png)

#### Target Prevalence & Class Imbalance
Within the analytical cohort, **19.5%** of participants presented with clinical hearing loss (PTA > 25 dB HL), while **80.5%** exhibited normal hearing. This ~4:1 class imbalance confirmed that standard accuracy would provide misleading evaluation, requiring **Precision-Recall AUC (PR-AUC)** for model comparison and **$F_2$ scoring** for operational threshold selection.

![Figure 5: Target Prevalence](images/eda_results/Figure%205%20-%20Prevalence%20of%20our%20target%20variable%20%28Hearing%20loss%29.png)

#### Relationships with Hearing Impairment
- **Continuous Predictors**: Age exhibits a striking separation between groups: participants with hearing loss are markedly older, matching clinical presbycusis trajectories. Systolic blood pressure and BMI show slight upward shifts in the impaired cohort, while income-to-poverty ratios are lower.
- **Categorical & Behavioral Predictors**: Hearing loss prevalence scales monotonically with increasing levels of occupational noise and firearm exposure. Higher rates are evident among males, individuals with prior military service, and patients diagnosed with diabetes or cardiovascular disease.
- **Inter-Feature Collinearity**: Pairwise correlation analysis revealed modest correlations between age, blood pressure, and lead, with low overall multicollinearity across features.

![Figure 6: Continuous Features stratified by Hearing Loss](images/eda_results/Figure%206%20-%20Continuous%20features%20against%20HL.png)
![Figure 8: Categorical Features stratified by Hearing Loss](images/eda_results/Figure%208%20-%20Categorical%20features%20against%20HL.png)
![Figure 7: Correlation Matrix for Continuous Features](images/eda_results/Figure%207%20-%20Correlation%20Matrix%20for%20Continuous%20Features.png)

---

### 2. Model Training & Evaluation

Five candidate algorithms were benchmarked using **5-fold stratified cross-validation** on the training split, evaluated primarily on **PR-AUC**:
1. **Logistic Regression (Class-Weighted)**: Best overall performer (mean CV PR-AUC: **0.475**).
2. **Random Forest**: Mean CV PR-AUC: ~0.44.
3. **XGBoost**: Mean CV PR-AUC: ~0.43.
4. **K-Nearest Neighbors (KNN)**: Mean CV PR-AUC: ~0.38.
5. **Gaussian Naive Bayes**: Mean CV PR-AUC: ~0.36.

Logistic Regression outperformed non-linear and ensemble tree methods because the dominant predictive signals (age and noise-exposure ordinals) exhibit predominantly linear and monotonic relationships with hearing loss log-odds, without high-order interaction effects.

#### Test Set Performance Summary

To function effectively as a medical screening tool, the classification decision threshold was optimized on out-of-fold cross-validation probabilities to maximize the **$F_2$ score** (prioritizing recall over precision):

| Metric | 5-Fold Cross-Validation | Held-Out Test Set (20%) |
| :--- | :---: | :---: |
| **PR-AUC** | **0.475** | **0.454** |
| **$F_2$ Score** | **0.637** | **0.602** |
| **Recall (Sensitivity)** | — | **0.759** |
| **Precision (PPV)** | — | **0.329** |

The final model successfully detects **~76% of all true hearing impairment cases** in the unseen test cohort. In a preventive screening scenario, this false-alarm trade-off is clinically preferred: the cost of a confirmatory audiogram for an over-flagged patient is minimal, whereas an undetected hearing impairment leaves the patient without intervention.

![Confusion Matrix](images/model_training_results/Confusion_Matrix.png)
![Precision-Recall Curve](images/model_training_results/PR_Curve.png)
![Model Coefficients](images/model_training_results/Coefficients.png)

#### Clinical Feature Interpretation
- **Age (Dominant Positive Predictor)**: Age is the single strongest factor, reflecting the cumulative physiological progression of sensorineural degeneration (presbycusis).
- **Acoustic Trauma Indicators**: Occupational noise exposure and firearm discharge history add independent, positive log-odds weight.
- **Systemic Health & Demographics**: Doctor-diagnosed diabetes and male biological sex show clear positive associations with hearing impairment risk.
- **Education Level (Negative Predictor)**: Higher education correlates with lower hearing loss risk, serving as an effective socioeconomic proxy for reduced occupational noise environments and better health maintenance.

---

## Key Design & Analytical Decisions

1. **Differentiating Structural vs. Stochastic Missingness**  
   Missing values in survey data cannot be treated uniformly. Rather than applying broad statistical imputation, questions skipped due to survey logic (e.g., specific workplace noise tiers) were deterministically recoded to "No Exposure" based on parent questions. Only genuinely missing values were handled using median and mode imputation.

2. **Handling Clinical Edge-Cases in Audiometry Data**  
   Raw NHANES audiometric thresholds contained two distinct non-numeric sentinel codes:
   - `666`: Participant was tested at maximum audiometer output (~100–120 dB HL) with no perceptual response. Dropping these rows would have systematically excluded the most severe hearing loss cases in the survey. These were recoded to the audiometer ceiling threshold.
   - `888`: Examination could not be completed (e.g., equipment malfunction, ear canal obstruction, refusal). These represent true missingness and were handled as invalid readings.

3. **Empirical Evaluation of Heavy Metal Biomarkers**  
   Blood lead and cadmium were absent for 55% of participants due to NHANES lab subsampling. Before deciding whether to retain or discard them, an empirical test was run: missing values were modeled using `IterativeImputer` conditioned on age and blood pressure, and cross-validated PR-AUC was compared between models with and without the biomarkers. Neither linear nor tree models exhibited measurable improvement, leading to their clean exclusion to avoid unnecessary dimensionality and noise.

4. **Threshold Tuning via $F_2$ Optimization on Out-of-Fold Predictions**  
   Standard 0.5 decision cutoffs are poorly suited for imbalanced clinical screening tasks. The decision threshold was tuned strictly on out-of-fold cross-validation probabilities using the $F_2$ metric ($\beta=2$), ensuring that sensitivity was prioritized without causing data leakage into the final test evaluation.

---

## Limitations

- **Cross-Sectional Architecture**: NHANES surveys capture a single temporal snapshot. Observed associations reflect predictive statistical risk factors rather than confirmed causal mechanisms.
- **Unweighted Sample Estimation**: NHANES utilizes a complex, multi-stage stratified sampling frame with oversampling of specific demographic subgroups. This project analyzes relationships within the observed sample without survey weight adjustment, meaning metrics describe sample performance rather than weighted national point prevalence.
- **Effect Size Concentration**: Beyond chronological age, individual behavioral and clinical risk factors possess comparatively modest effect sizes, requiring combined multi-variable scoring to achieve screening utility.

---

## Project Structure

```text
project/
├── data/
│   ├── raw/                           # Raw CDC NHANES .XPT files and feature documentation
│   └── processed/                     # Master feature table and cleaned train/test parquet splits
├── notebooks/
│   ├── eda.ipynb                      # Exploratory data analysis, distributions, and missingness
│   ├── cleaning.ipynb                 # Missingness recoding, biomarker testing, and train/test split
│   └── feature_preparing.ipynb        # Preprocessing pipeline, model benchmarking, and evaluation
├── images/
│   ├── eda_results/                   # Figures 1 through 8 (distributions, correlations, target)
│   └── model_training_results/        # Confusion matrix, PR curve, and coefficient rankings
├── report/
│   ├── Data_Analytics_Project_Plan.md # Comprehensive academic project report
│   └── Data_Analytics_Project_Plan.pdf# Compiled PDF deliverable
├── sql/
│   ├── nhanes_master_table_query.sql  # SQL joins, PTA calculation, and master table creation
│   └── data_dictionary.md             # Detailed variable definitions and encoding schema
├── src/
│   ├── raw_data_downloader.py         # Automated extraction of SAS XPT files from CDC
│   ├── raw_data_to_postgress_loader.py# Ingestion of raw tables into local PostgreSQL database
│   └── processed_sql_to_csv.py        # Database query export to local analytical CSV
├── .env.example                       # Template for local database credentials
├── .gitignore                         # Standard git ignore rules (data, cache, credentials)
├── docker-compose.yml                 # Multi-platform containerized PostgreSQL 16 setup
├── requirements.txt                   # Pinned project dependencies
└── README.md
```

---

## Tech Stack

- **Data Engineering & Database**: PostgreSQL 16, Docker & Docker Compose, SQLAlchemy, psycopg2, pyreadstat, pyarrow
- **Machine Learning & Statistics**: scikit-learn, XGBoost, statsmodels, SciPy, pandas, NumPy
- **Exploration & Visualization**: Matplotlib, Seaborn, missingno
- **Environment & Workflow**: Python 3.11+, JupyterLab

---

## Getting Started

### 1. Environment Setup
Clone the repository, create an isolated virtual environment, and install dependencies:
```bash
git clone https://github.com/kasrabghr/hearing-loss-prediction.git
cd hearing-loss-prediction
python -m venv .venv

# On Linux/macOS:
source .venv/bin/activate

# On Windows:
.venv\Scripts\activate

pip install -r requirements.txt
```

### 2. Database Configuration
Copy the sample environment file and configure your credentials:
```bash
cp .env.example .env
```
Default parameters in `.env.example`:
```env
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=nhanes
DB_HOST=localhost
DB_PORT=5433
```

### 3. Launch PostgreSQL
Start the local PostgreSQL container via Docker Compose:
```bash
docker compose up -d
```

### 4. Execute Data Pipeline
Run the automated downloader and database loader:
```bash
python src/raw_data_downloader.py
python src/raw_data_to_postgress_loader.py
```

### 5. Build Master Analytical Table
Execute `sql/nhanes_master_table_query.sql` in your database client (e.g., pgAdmin, DBeaver, or `psql` connected to `localhost:5433`).

Export the processed view to disk:
```bash
python src/processed_sql_to_csv.py
```

### 6. Run Analytical Notebooks
Launch JupyterLab and execute the analysis sequentially:
```bash
jupyter lab
```
1. `notebooks/eda.ipynb` — Generates distribution and correlation figures.
2. `notebooks/cleaning.ipynb` — Executes logic recoding and saves train/test splits.
3. `notebooks/feature_preparing.ipynb` — Runs model benchmark and generates evaluation plots.

### 7. Teardown
When complete, stop the container (database state is safely persisted in the Docker volume):
```bash
docker compose down
```

---

## Contact

**Kasra Bagherian**  
- Email: [kasra.bghr@gmail.com](mailto:kasra.bghr@gmail.com)  
- LinkedIn: [linkedin.com/in/kasrabagherian](https://www.linkedin.com/in/kasrabagherian/)  
- GitHub: [github.com/kasrabghr](https://github.com/kasrabghr)
