"""
RAG System Module
Main RAG pipeline: ingestion and querying
"""
import uuid
from embedding_model import get_embedding
from vector_store import add_chunk, search
from groq_llm import groq_answer

def ingest(text: str):
    """Split text into chunks and store in vector database"""
    # Split into chunks of ~400 characters
    chunk_size = 400
    chunks = []
    
    words = text.split()
    current_chunk = []
    current_length = 0
    
    for word in words:
        word_length = len(word) + 1  # +1 for space
        if current_length + word_length > chunk_size and current_chunk:
            chunks.append(" ".join(current_chunk))
            current_chunk = [word]
            current_length = word_length
        else:
            current_chunk.append(word)
            current_length += word_length
    
    if current_chunk:
        chunks.append(" ".join(current_chunk))
    
    # Generate embeddings and store
    for i, chunk_text in enumerate(chunks):
        chunk_id = str(uuid.uuid4())
        embedding = get_embedding(chunk_text)
        add_chunk(chunk_id, chunk_text, embedding)
    
    return len(chunks)

def ask(question: str) -> str:
    """Ask a question and get answer from RAG system"""
    # Embed query
    query_embedding = get_embedding(question)
    
    # Vector search
    results = search(query_embedding, n=3)
    
    if not results:
        return "I couldn't find relevant information to answer your question."
    
    # Combine top chunks as context
    context = "\n\n".join([chunk['text'] for chunk in results])
    
    # Get answer from Groq
    answer = groq_answer(question, context)
    
    return answer
