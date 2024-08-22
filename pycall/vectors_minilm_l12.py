import os
import requests
import sys
import json

# Configuration des headers pour la requête
headers = {
    'Authorization': f'Bearer {os.getenv("HUGGINGFACE_API_TOKEN_2")}',
    'Content-Type': 'application/json'
}

# URL de l'API de Hugging Face pour le modèle 'sentence-transformers/all-MiniLM-L6-v2'
api_url = 'https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'

def get_embeddings(sentence):
    data = {'inputs': sentence}
    response = requests.post(api_url, headers=headers, json=data)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Erreur: {response.status_code}", file=sys.stderr)
        return []

if __name__ == "__main__":
    # Récupérer la phrase passée en argument
    if len(sys.argv) > 1:
        sentence = sys.argv[1]
        embeddings = get_embeddings(sentence)
        # Retourner le résultat sous forme de JSON
        print(json.dumps(embeddings))
    else:
        print("No sentence provided", file=sys.stderr)
