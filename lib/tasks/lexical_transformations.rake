namespace :lexical_transformations do
  desc "Vectorizes last not performed lexical transformation"
  task perform_last: :environment do
    lexical_transformation_id = LexicalTransformation.where(performed: false).last.id

    BertJob.perform_later(lexical_transformation_id, :name)
    BertJob.perform_later(lexical_transformation_id, :description)
  end

  desc "Vectorizes all not performed lexical transformation"
  task perform_all: :environment do
    LexicalTransformation.where(performed: false).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, :name)
      BertJob.new.perform(lexical_transformation.id, :description)

      sleep 60
    end
  end

  desc "Initiate all lexical_transformations for neighborhoods"
  task initiate_for_neighborhoods: :environment do
    initiate_lexical_transformations_for('Neighborhood', 'neighborhoods')
  end

  desc "Initiate all lexical_transformations for resources"
  task initiate_for_resources: :environment do
    initiate_lexical_transformations_for('Resource', 'resources')
  end

  desc "Initiate all lexical_transformations for contributions"
  task initiate_for_contributions: :environment do
    additional_conditions = <<-SQL
      AND entourages.group_type = 'action'
      AND entourages.entourage_type = 'contribution'
      AND entourages.created_at > '2024-01-01'
    SQL

    initiate_lexical_transformations_for('Entourage', 'entourages', additional_conditions)
  end

  desc "Initiate all lexical_transformations for solicitations"
  task initiate_for_solicitations: :environment do
    additional_conditions = <<-SQL
      AND entourages.group_type = 'action'
      AND entourages.entourage_type = 'ask_for_help'
      AND entourages.created_at > '2024-01-01'
    SQL

    initiate_lexical_transformations_for('Entourage', 'entourages', additional_conditions)
  end

  def initiate_lexical_transformations_for(instance_type, table_name, additional_conditions = nil)
    sql = <<-SQL
      INSERT INTO lexical_transformations (instance_type, instance_id, name, description, performed, created_at, updated_at)
      SELECT
        '#{instance_type}',
        #{table_name}.id,
        NULL,
        NULL,
        false,
        NOW(),
        NOW()
      FROM
        #{table_name}
      WHERE
        NOT EXISTS (
          SELECT 1
          FROM lexical_transformations
          WHERE lexical_transformations.instance_type = '#{instance_type}'
          AND lexical_transformations.instance_id = #{table_name}.id
        )
        #{additional_conditions}
    SQL

    ActiveRecord::Base.connection.execute(sql)
    puts "LexicalTransformations initiated for #{instance_type.pluralize} where they didn't already exist."
  end
end
