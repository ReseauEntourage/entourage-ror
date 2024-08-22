namespace :lexical_transformations do
  #
  # Compute vectors
  #

  # compute not performed
  desc "Vectorizes all not performed L6 lexical transformation"
  task perform_all_not_performed_l6: :environment do
    LexicalTransformation.where(vectors_minilm_l6: nil).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L12 lexical transformation"
  task perform_all_not_performed_l12: :environment do
    LexicalTransformation.where(vectors_minilm_l12: nil).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L6 lexical transformation for neighborhoods"
  task perform_all_not_performed_neighborhoods_l6: :environment do
    LexicalTransformation.where(vectors_minilm_l6: nil, instance_type: :Neighborhood).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L12 lexical transformation for neighborhoods"
  task perform_all_not_performed_neighborhoods_l12: :environment do
    LexicalTransformation.where(vectors_minilm_l12: nil, instance_type: :Neighborhood).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L6 lexical transformation for resources"
  task perform_all_not_performed_resources_l6: :environment do
    LexicalTransformation.where(vectors_minilm_l6: nil, instance_type: :Resource).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L12 lexical transformation for resources"
  task perform_all_not_performed_resources_l12: :environment do
    LexicalTransformation.where(vectors_minilm_l12: nil, instance_type: :Resource).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L6 lexical transformation for pois"
  task perform_all_not_performed_pois_l6: :environment do
    LexicalTransformation.where(vectors_minilm_l6: nil, instance_type: :Poi).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L12 lexical transformation for pois"
  task perform_all_not_performed_pois_l12: :environment do
    LexicalTransformation.where(vectors_minilm_l12: nil, instance_type: :Poi).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L6 lexical transformation for actions"
  task perform_all_not_performed_actions_l6: :environment do
    LexicalTransformation.where(vectors_minilm_l6: nil, instance_type: :Entourage).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all not performed L12 lexical transformation for actions"
  task perform_all_not_performed_actions_l12: :environment do
    LexicalTransformation.where(vectors_minilm_l12: nil, instance_type: :Entourage).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  # compute not performed and performed
  desc "Vectorizes all lexical transformation"
  task perform_compute_all: :environment do
    LexicalTransformation.find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all lexical transformation neighborhoods"
  task perform_compute_all_neighborhoods: :environment do
    LexicalTransformation.where(instance_type: :Neighborhood).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all lexical transformation resources"
  task perform_compute_all_resources: :environment do
    LexicalTransformation.where(instance_type: :Resource).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all lexical transformation pois"
  task perform_compute_all_pois: :environment do
    LexicalTransformation.where(instance_type: :Poi).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  desc "Vectorizes all lexical transformation actions"
  task perform_compute_all_actions: :environment do
    LexicalTransformation.where(instance_type: :Entourage).find_each do |lexical_transformation|
      BertJob.new.perform(lexical_transformation.id, false)

      sleep 30
    end
  end

  #
  # Initiate lexical_transformations
  #
  desc "Initiate all lexical_transformations for neighborhoods"
  task initiate_for_neighborhoods: :environment do
    initiate_lexical_transformations_for('Neighborhood', 'neighborhoods')
  end

  desc "Initiate all lexical_transformations for resources"
  task initiate_for_resources: :environment do
    initiate_lexical_transformations_for('Resource', 'resources')
  end

  desc "Initiate all lexical_transformations for pois"
  task initiate_for_pois: :environment do
    additional_conditions = <<-SQL
      -- filter on pois from Entourage (exclude Soliguide)
      AND pois.source = 0
    SQL

    initiate_lexical_transformations_for('Poi', 'pois', additional_conditions)
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
      INSERT INTO lexical_transformations (instance_type, instance_id, vectors_minilm_l6, vectors_minilm_l12, created_at, updated_at)
      SELECT
        '#{instance_type}',
        #{table_name}.id,
        NULL,
        NULL,
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
