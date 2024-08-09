class AddFunctionCosineSimilarity < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
    CREATE OR REPLACE FUNCTION cosine_similarity(vec1 float8[], vec2 float8[])
      RETURNS float8 AS $$
      DECLARE
          dot_product float8 := 0;
          magnitude1 float8 := 0;
          magnitude2 float8 := 0;
          similarity float8 := 0;
      BEGIN
          -- Vérifier que les deux vecteurs ont la même taille
          IF array_length(vec1, 1) != array_length(vec2, 1) THEN
              RAISE EXCEPTION 'Les vecteurs doivent avoir la même longueur';
          END IF;

          -- Calculer le produit scalaire et les magnitudes
          FOR i IN 1 .. array_length(vec1, 1) LOOP
              dot_product := dot_product + (vec1[i] * vec2[i]);
              magnitude1 := magnitude1 + (vec1[i] * vec1[i]);
              magnitude2 := magnitude2 + (vec2[i] * vec2[i]);
          END LOOP;

          -- Calculer les magnitudes finales
          magnitude1 := sqrt(magnitude1);
          magnitude2 := sqrt(magnitude2);

          -- Éviter la division par zéro
          IF magnitude1 = 0 OR magnitude2 = 0 THEN
              RETURN 0;
          END IF;

          -- Calculer la similarité cosinus
          similarity := dot_product / (magnitude1 * magnitude2);
          RETURN similarity;
      END;
      $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION cosine_similarity;
    SQL
  end
end
