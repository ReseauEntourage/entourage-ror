namespace :lexical_transformations do
  desc "Vectorizes last not performed lexical transformation"
  task perform_last: :environment do
    lexical_transformation_id = LexicalTransformation.where(performed: false).last.id

    BertJob.perform_later(lexical_transformation_id, :name)
    BertJob.perform_later(lexical_transformation_id, :description)
  end
end
