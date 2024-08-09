from sentence_transformers import SentenceTransformer
import json
import sys

model = SentenceTransformer('distiluse-base-multilingual-cased')

def get_embeddings(text):
  return model.encode([text]).tolist()[0]

embedding = get_embeddings(sys.argv[1]) if sys.argv[1] else []

print(json.dumps(embedding))
