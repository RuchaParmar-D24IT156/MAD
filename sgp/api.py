import os
import sys

# Ensure sgp directory is in path so csv_processor can be imported
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from rag_system import ask
from csv_processor import CSVProcessor

app = FastAPI(title="SakshmSeva Gujarat API")

# Allow Flutter (and any local origin) to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_FILES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "files")


@app.on_event("startup")
async def startup_ingest():
    """Load and ingest all CSV data into the vector store on startup.
    ChromaDB is in-memory so this must run every time the server starts."""
    import asyncio
    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _do_ingest)


def _do_ingest():
    from csv_loader import load_csv_files
    from rag_system import ingest
    print("[startup] Loading CSV files ...")
    text_data = load_csv_files("files")
    if text_data.strip():
        n = ingest(text_data)
        print(f"[startup] Ingested {n} chunks into vector store. Chatbot ready!")
    else:
        print("[startup] WARNING: No CSV data found — chatbot will have no context.")


# ── Chatbot endpoint ─────────────────────────────────────────────────────────

@app.post("/ask")
def ask_api(query: str):
    return {"answer": ask(query)}


# ── Schemes data endpoints ────────────────────────────────────────────────────

@app.get("/schemes")
def get_schemes():
    """Return all government schemes parsed from the CSV files."""
    processor = CSVProcessor(_FILES_DIR)
    data = processor.load_csv_files()
    return data


@app.get("/schemes/categories")
def get_categories():
    """Return the list of distinct scheme categories."""
    processor = CSVProcessor(_FILES_DIR)
    data = processor.load_csv_files()
    seen = []
    for item in data:
        cat = item.get("category", "")
        if cat and cat not in seen:
            seen.append(cat)
    return seen
