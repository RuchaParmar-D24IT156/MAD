"""
CSV Loader Module
Loads and processes CSV files from the files directory
"""
import os
import pandas as pd
from typing import List

def load_csv_files(files_dir: str = "files") -> str:
    """Load all CSV files and convert to text format"""
    if not os.path.exists(files_dir):
        return ""
    
    all_text = []
    
    # Get all CSV files
    csv_files = [f for f in os.listdir(files_dir) if f.endswith('.csv')]
    
    for csv_file in csv_files:
        file_path = os.path.join(files_dir, csv_file)
        try:
            # Read CSV file, skip first 5 rows (header rows)
            df = pd.read_csv(file_path, encoding='utf-8', skiprows=5)
            
            # Extract category from filename
            category = csv_file.replace('.csv', '').replace(' - Sheet', ' - ')
            
            # Process each row
            for _, row in df.iterrows():
                # Skip empty rows
                if pd.isna(row.get('SCHEME NAME', '')) or str(row.get('SCHEME NAME', '')).strip() == '':
                    continue
                
                # Build text representation
                scheme_name = str(row.get('SCHEME NAME', '')).strip()
                description = str(row.get('DESCRIPTION', '')).strip()
                status = str(row.get('STATUS', '')).strip()
                services = str(row.get('SERVICES', '')).strip()
                documents = str(row.get('DOCUMENTS NEEDED', '')).strip()
                
                # Create text chunk
                text_chunk = f"""
Category: {category}
Scheme Name: {scheme_name}
Description: {description}
Status: {status}
Services: {services}
Documents Needed: {documents}
""".strip()
                
                if text_chunk:
                    all_text.append(text_chunk)
                    
        except Exception as e:
            print(f"Error reading {csv_file}: {e}")
            continue
    
    return "\n\n".join(all_text)

