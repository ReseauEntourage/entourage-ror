class AddFunctionJsonbToFloat8Array < ActiveRecord::Migration[6.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION jsonb_to_float8_array(jsonb_text TEXT)
        RETURNS float8[] AS $$
        DECLARE
            result float8[];
        BEGIN
            SELECT array_agg(elem::float8)
            INTO result
            FROM jsonb_array_elements_text(jsonb_text::jsonb) AS elem;
            RETURN result;
        END;
        $$ LANGUAGE plpgsql;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION jsonb_to_float8_array;
    SQL
  end
end
