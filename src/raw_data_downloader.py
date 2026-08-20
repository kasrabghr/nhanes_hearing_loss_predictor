from pathlib import Path
import urllib.request

Project_root = Path(__file__).resolve().parents[1]
Raw_data_dir = Project_root / 'data' / 'raw'
Raw_data_dir.mkdir(parents=True, exist_ok=True)

dataset_url = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2015/DataFiles"

files = [
    "AUQ_I.XPT",
    "AUX_I.XPT",
    "BMX_I.XPT",
    "BPX_I.XPT",
    "DEMO_I.XPT",
    "DIQ_I.XPT",
    "MCQ_I.XPT",
    "PBCD_I.XPT",
]

def downloader():
    for file_name in files:
        file_path = Raw_data_dir / file_name
        if not file_path.exists():
            url = f"{dataset_url}/{file_name}"
            print(f"Downloading {file_name}...")
            urllib.request.urlretrieve(url, file_path)
            print(f"Downloaded {file_name} to {file_path}")
        else:
            print(f"{file_name} already exists at {file_path}, skipping download.")

if __name__ == '__main__':
    downloader()