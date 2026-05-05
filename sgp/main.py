"""
Main RAG Chatbot
Simple terminal interface
"""
import os

def load_data() -> str:
    """Load data from CSV files"""
    from csv_loader import load_csv_files
    
    # Load from CSV files
    text_data = load_csv_files("files")
    
    # Also check data.txt if it exists and has content
    if os.path.exists("data.txt"):
        with open("data.txt", 'r', encoding='utf-8') as f:
            data_txt = f.read().strip()
            if data_txt:
                if text_data:
                    text_data = text_data + "\n\n" + data_txt
                else:
                    text_data = data_txt
    
    return text_data

def main():
    """Main function"""
    print("=" * 50)
    print("RAG Chatbot - Loading data from CSV files...")
    print("=" * 50)
    
    # Load data from CSV files
    text_data = load_data()
    
    if not text_data.strip():
        print("Warning: No data found in CSV files or data.txt.")
        print("The system will still work, but won't have any context to search.")
    else:
        # Ingest data
        from rag_system import ingest
        print("Ingesting data into vector store...")
        num_chunks = ingest(text_data)
        print(f"Ingested {num_chunks} chunks.")
    
    print("\n" + "=" * 50)
    print("RAG Chatbot Ready!")
    print("Type 'quit' or 'exit' to stop.")
    print("=" * 50 + "\n")
    
    # Query loop
    from rag_system import ask
    
    while True:
        try:
            question = input("You: ").strip()
            
            if not question:
                continue
            
            if question.lower() in ['quit', 'exit', 'q']:
                print("Goodbye!")
                break
            
            print("Bot: ", end="", flush=True)
            answer = ask(question)
            print(answer)
            print()
            
        except KeyboardInterrupt:
            print("\nGoodbye!")
            break
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()
