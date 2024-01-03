class RenameAllToursTables < ActiveRecord::Migration[6.1]
  def up
    sql = <<-SQL
      ALTER TABLE answers RENAME TO old_answers;
      ALTER TABLE encounters RENAME TO old_encounters;
      ALTER TABLE organizations RENAME TO old_organizations;
      ALTER TABLE registration_requests RENAME TO old_registration_requests;
      ALTER TABLE simplified_tour_points RENAME TO old_simplified_tour_points;
      ALTER TABLE tours RENAME TO old_tours;
      ALTER TABLE tour_areas RENAME TO old_tour_areas;
      ALTER TABLE tour_points RENAME TO old_tour_points;
      -- ALTER TABLE tours_entourages RENAME TO old_tours_entourages;
    SQL

    execute(sql)
  end

  def down
    sql = <<-SQL
      ALTER TABLE old_answers RENAME TO answers;
      ALTER TABLE old_encounters RENAME TO encounters;
      ALTER TABLE old_organizations RENAME TO organizations;
      ALTER TABLE old_registration_requests RENAME TO registration_requests;
      ALTER TABLE old_simplified_tour_points RENAME TO simplified_tour_points;
      ALTER TABLE old_tours RENAME TO tours;
      ALTER TABLE old_tour_areas RENAME TO tour_areas;
      ALTER TABLE old_tour_points RENAME TO tour_points;
      -- ALTER TABLE old_tours_entourages RENAME TO tours_entourages;
    SQL

    execute(sql)
  end
end
