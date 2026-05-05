# Government Schemes RAG System

A Retrieval-Augmented Generation (RAG) system for querying government schemes data from CSV files using Ollama and FAISS.

## Features

- **CSV Data Processing**: Automatically processes multiple CSV files containing government schemes
- **Vector Search**: Uses FAISS for efficient similarity search
- **Ollama Integration**: Leverages local Ollama models for embeddings and text generation
- **Terminal Interface**: Simple command-line interface for querying
- **Modular Design**: Clean separation of concerns for easy maintenance

## Setup

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Ensure Ollama is Running**:
   ```bash
   ollama serve
   ```

3. **Verify Models**:
   The system will automatically pull required models if not available:
   - `gemma3:4b` (for text generation)
   - `mxbai-embed-large` (for embeddings)

## Usage

1. **Run the System**:
   ```bash
   python main.py
   ```

2. **Available Commands**:
   - `ask <question>` - Ask a question about government schemes
   - `rebuild` - Rebuild the knowledge base from CSV files
   - `stats` - Show knowledge base statistics
   - `help` - Show help message
   - `quit/exit` - Exit the system

## Example Queries

- "What schemes are available for farmers?"
- "How can I get financial assistance for education?"
- "What documents are needed for health schemes?"
- "Tell me about women empowerment schemes"

## File Structure

```
├── main.py              # Main terminal interface
├── rag_system.py        # Core RAG system
├── vector_store.py      # Vector database management
├── csv_processor.py     # CSV data processing
├── config.py           # Configuration settings
├── requirements.txt    # Python dependencies
├── files/              # CSV files directory
└── vdb/               # Vector database storage
```

## Configuration

Edit `config.py` to modify:
- Model names
- Chunk sizes
- Search parameters
- File paths

## Troubleshooting

- Ensure Ollama is running: `ollama serve`
- Check model availability: `ollama list`
- Verify CSV files are in the `files/` directory
- Check vector database in `vdb/` directory
