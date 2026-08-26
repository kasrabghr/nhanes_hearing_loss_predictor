import os
from pathlib import Path
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine 

project_dir = Path(__file__).resolve().parents[1]
processed_data_dir = project_dir / "data" / "processed"

# Load environment variables from .env file to connect to postgresSQL server
load_dotenv(project_dir / '.env')

DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")
DB_NAME = os.getenv("DB_NAME", "nhanes")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")

DB_URI = f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
engine = create_engine(DB_URI)

# Create the processed data directory if it doesn't exist
processed_data_dir.mkdir(parents=True, exist_ok=True)

# Define the output file path
output_file_path = processed_data_dir / "raw_master_table.csv"

print("Connecting to the database...")

# Query the database to retrieve the data
query = "SELECT * FROM nhanes_master_table;"
df = pd.read_sql(query, con=engine)

# Drop rows without labels (hl_presence)
clean_df = df.dropna(subset=['hl_presence'])

print("Data shape after dropping rows without labels:", clean_df.shape)

clean_df.to_csv(output_file_path, index=False)
print("Cleaned data saved to: ", output_file_path)
