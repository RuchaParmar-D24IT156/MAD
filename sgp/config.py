"""
Configuration file for the RAG system
"""
import os

# --- Configuration ---
CONFIG = {
    "MODEL_NAME": "gemma3:1b",  # Using your available smaller model
    "EMBED_MODEL_NAME": "mxbai-embed-large:latest",
    "FILES_DIR": "./files",
    "VDB_DIR": "./vdb",
    "CHUNK_SIZE": 200,  # words per chunk
    "CHUNK_OVERLAP": 50,  # words overlap between chunks
    "FAISS_K": 3,  # Number of relevant chunks to retrieve
    "MAX_TOKENS": 1000,  # Maximum tokens for response
}

# Ensure directories exist
os.makedirs(CONFIG["VDB_DIR"], exist_ok=True)
