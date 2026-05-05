"""
Vector Store Module
Uses ChromaDB for vector storage and search
"""
import chromadb
from chromadb.config import Settings

_client = None
_collection = None

def _get_collection():
    """Initialize and return ChromaDB collection"""
    global _client, _collection
    if _collection is None:
        _client = chromadb.Client(Settings(anonymized_telemetry=False))
        _collection = _client.get_or_create_collection(name="rag_chunks")
    return _collection

def add_chunk(chunk_id: str, text: str, vector: list):
    """Add a chunk with its embedding to ChromaDB"""
    collection = _get_collection()
    collection.add(
        ids=[chunk_id],
        documents=[text],
        embeddings=[vector]
    )

def search(query_vector: list, n: int = 3) -> list:
    """Search for similar chunks"""
    collection = _get_collection()
    results = collection.query(
        query_embeddings=[query_vector],
        n_results=n
    )
    
    if not results['ids'] or len(results['ids'][0]) == 0:
        return []
    
    chunks = []
    for i in range(len(results['ids'][0])):
        chunks.append({
            'id': results['ids'][0][i],
            'text': results['documents'][0][i],
            'distance': results['distances'][0][i] if results['distances'] else 0.0
        })
    return chunks
