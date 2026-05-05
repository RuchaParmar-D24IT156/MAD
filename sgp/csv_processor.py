"""
CSV Data Processing Module
Handles loading and processing of CSV files containing government schemes
"""
import pandas as pd
import os
import json
from typing import List, Dict, Any

class CSVProcessor:
    """Processes CSV files containing government schemes data"""
    
    def __init__(self, files_dir: str):
        self.files_dir = files_dir
        
    def load_csv_files(self) -> List[Dict[str, Any]]:
        """Load all CSV files and return combined data"""
        all_data = []
        
        for filename in os.listdir(self.files_dir):
            if filename.endswith('.csv'):
                file_path = os.path.join(self.files_dir, filename)
                try:
                    # Read CSV file with header starting from row 6 (index 5)
                    df = pd.read_csv(file_path, skiprows=5)
                    
                    # Clean the data - remove empty rows and columns
                    df = df.dropna(how='all')
                    df = df.dropna(axis=1, how='all')
                    
                    # Skip if no valid data
                    if df.empty:
                        continue
                        
                    # Get category from filename
                    category = filename.replace('.csv', '').replace(' - Sheet', '')
                    
                    # Process each row
                    for _, row in df.iterrows():
                        if pd.notna(row.get('SCHEME NAME', '')) and str(row['SCHEME NAME']).strip():
                            scheme_data = {
                                'category': category,
                                'scheme_name': str(row.get('SCHEME NAME', '')).strip(),
                                'description': str(row.get('DESCRIPTION', '')).strip(),
                                'status': str(row.get('STATUS', '')).strip(),
                                'services': str(row.get('SERVICES', '')).strip(),
                                'documents_needed': str(row.get('DOCUMENTS NEEDED', '')).strip(),
                                'source_file': filename
                            }
                            all_data.append(scheme_data)
                            
                except Exception as e:
                    print(f"Error processing {filename}: {e}")
                    continue
                    
        return all_data
    
    def create_text_chunks(self, data: List[Dict[str, Any]], chunk_size: int = 200, overlap: int = 50) -> List[Dict[str, Any]]:
        """Create text chunks from the scheme data"""
        chunks = []
        
        for item in data:
            # Create a comprehensive text representation
            text = f"""
            Category: {item['category']}
            Scheme Name: {item['scheme_name']}
            Description: {item['description']}
            Status: {item['status']}
            Services: {item['services']}
            Documents Needed: {item['documents_needed']}
            """.strip()
            
            # Split into words and create chunks
            words = text.split()
            for i in range(0, len(words), chunk_size - overlap):
                chunk_text = " ".join(words[i:i + chunk_size])
                if chunk_text.strip():
                    chunk = {
                        'text': chunk_text,
                        'metadata': {
                            'scheme_name': item['scheme_name'],
                            'category': item['category'],
                            'source_file': item['source_file'],
                            'chunk_index': len(chunks)
                        }
                    }
                    chunks.append(chunk)
                    
        return chunks
    
    def save_processed_data(self, data: List[Dict[str, Any]], output_path: str):
        """Save processed data to JSON file"""
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            
    def load_processed_data(self, input_path: str) -> List[Dict[str, Any]]:
        """Load processed data from JSON file"""
        with open(input_path, 'r', encoding='utf-8') as f:
            return json.load(f)
