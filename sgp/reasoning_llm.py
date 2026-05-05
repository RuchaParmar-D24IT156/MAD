import requests
import os

GROQ_API_KEY = os.environ.get("GROQ_API_KEY")

def llm_reason(question, context):
    prompt = f"""
Use the context below to answer the question. 
Think step by step and give a clear human-like answer.

CONTEXT:

{context}

QUESTION:

{question}

ANSWER:

"""

    response = requests.post(
        "https://api.groq.com/openai/v1/chat/completions",
        headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
        json={
            "model": "llama3-8b-8192",
            "messages": [{"role": "user", "content": prompt}]
        }
    )

    return response.json()["choices"][0]["message"]["content"]

