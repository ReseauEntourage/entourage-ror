from sentence_transformers import SentenceTransformer
import psycopg2
import json
import os
from urllib.parse import urlparse

model = SentenceTransformer('distiluse-base-multilingual-cased')

def get_embeddings(text):
    return model.encode([text]).tolist()[0]

url = urlparse(ENV['DATABASE_URL'])

conn = psycopg2.connect(
    dbname=url.path[1:],
    user=url.username,
    password=url.password,
    host=url.hostname,
    port=url.port
)
cur = conn.cursor()

cur.execute("SELECT id, name FROM neighborhoods where created_at > '2023-01-01'")
rows = cur.fetchall()

for row in rows:
    id, name = row
    name = get_embeddings(name) if name else []

    # Vérifier si un enregistrement existe déjà pour ce instance_id
    cur.execute("SELECT 1 FROM lexical_transformations WHERE instance_type = 'Neighborhood' and instance_id = %s", (id,))
    exists = cur.fetchone()

    if exists:
        cur.execute("""
            UPDATE lexical_transformations
            SET name = %s, updated_at = NOW()
            WHERE instance_type = 'Neighborhood' and instance_id = %s
        """, (json.dumps(name), id))
    else:
        cur.execute("""
            INSERT INTO lexical_transformations (instance_type, instance_id, name, created_at, updated_at)
            VALUES ('Neighborhood', %s, %s, NOW(), NOW())
        """, (id, json.dumps(name)))

conn.commit()
cur.close()
conn.close()