import os
from pathlib import Path
import pandas as pd
from dotenv import load_dotenv
import pyreadstat 
from sqlalchemy import create_engine 

project_dir = Path(__file__).resolve().parents[1]   
raw_data_dir = project_dir / "data" / "raw"

load_dotenv(project_dir / ".env")

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_NAME = os.getenv("DB_NAME", "nhanes")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

DB_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(DB_URI)

DATASETS = [
    "AUQ_I",
    "AUX_I",
    "BMX_I",
    "BPX_I",
    "DEMO_I",
    "DIQ_I",
    "MCQ_I",
    "PBCD_I",
]

def load_raw_to_postgres():
    for dataset in DATASETS:
        file_path = raw_data_dir / f"{dataset}.XPT"

        if not file_path.exists():
            print(f"File {file_path} does not exist. Skipping.")
            continue

        print(f"Loading {file_path} into PostgreSQL...")
        df, meta = pyreadstat.read_xport(file_path)

        df.columns = [col.lower() for col in df.columns]

        table_name = f"{dataset.lower()}_raw"

        df.to_sql(
            name = table_name,
            con = engine,
            if_exists = "replace",
            index = False,
            chunksize = 10000,
            method = "multi"
        )

        print(f"Successfully loaded {file_path} into table {table_name}.")


if __name__ == "__main__":
    load_raw_to_postgres()



