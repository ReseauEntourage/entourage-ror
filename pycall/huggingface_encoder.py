import os
import requests

# Configuration des headers pour la requête
headers = {
    'Authorization': f'Bearer {os.getenv("HUGGINGFACE_API_TOKEN")}',
    'Content-Type': 'application/json'
}

# URL de l'API de Hugging Face pour le modèle 'sentence-transformers/all-MiniLM-L6-v2'
api_url = 'https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2'

def get_embeddings(sentence):
    data = {'inputs': sentence}
    response = requests.post(api_url, headers=headers, json=data)
    if response.status_code == 200:
        return response.json()[0]
    else:
        print(f"Erreur: {response.status_code}")
        return []

