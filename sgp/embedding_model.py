"""
Embedding Model Module
Uses SentenceTransformer for local embeddings
"""
from sentence_transformers import SentenceTransformer

_model = None

def get_embedding(text: str) -> list:
    """Get embedding vector for a text"""
    global _model
    if _model is None:
        _model = SentenceTransformer('all-MiniLM-L6-v2')
    return _model.encode(text).tolist()

