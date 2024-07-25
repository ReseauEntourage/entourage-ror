from sentence_transformers import SentenceTransformer
import psycopg2
import json
import os
from urllib.parse import urlparse

model = SentenceTransformer('distiluse-base-multilingual-cased')

def get_embeddings(text):
    return model.encode([text]).tolist()[0]

url = urlparse(os.environ['DATABASE_URL'])

conn = psycopg2.connect(
    dbname=url.path[1:],
    user=url.username,
    password=url.password,
    host=url.hostname,
    port=url.port
)
cur = conn.cursor()

cur.execute("SELECT id, title, description FROM entourages where group_type = 'action' and created_at > '2024-01-01'")
rows = cur.fetchall()

for row in rows:
    id, title, description = row
    title_embedding = get_embeddings(title) if title else []
    description_embedding = get_embeddings(description) if description else []
    cur.execute("UPDATE entourages SET title_embedding = %s, description_embedding = %s WHERE id = %s",
                (json.dumps(title_embedding), json.dumps(description_embedding), id))

conn.commit()
cur.close()
conn.close()
