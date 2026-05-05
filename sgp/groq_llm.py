"""
Groq LLM Module
Uses Groq API for reasoning
"""
import requests
import os
from dotenv import load_dotenv

load_dotenv()

GROQ_API_KEY = os.environ.get("GROQ_API_KEY")

def groq_answer(question: str, context: str) -> str:
    """Get answer from Groq LLM using question and context"""
    if not GROQ_API_KEY:
        return "Error: GROQ_API_KEY not set in environment variables"
    
    prompt = f"""Use the context below to answer the question. 
Think step by step and give a clear human-like answer.

CONTEXT:
{context}

QUESTION:
{question}

ANSWER:
"""

    try:
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0.7,
            "max_tokens": 1024
        }
        
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code != 200:
            error_detail = response.text
            return f"Error calling Groq API ({response.status_code}): {error_detail}"
        
        result = response.json()
        return result["choices"][0]["message"]["content"].strip()
    except requests.exceptions.RequestException as e:
        return f"Error calling Groq API: {str(e)}"
    except KeyError as e:
        return f"Error parsing Groq API response: {str(e)}"
    except Exception as e:
        return f"Unexpected error: {str(e)}"

