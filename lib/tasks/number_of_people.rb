module NumberOfPeople
  def self.on_differing_rows(model_class)
    batch_size = ENV['BATCH_SIZE'] || 100

    model_class.find_each(batch_size: batch_size) do |model|
      current_number_of_people = model.number_of_people
      expected_number_of_people = model.join_requests.where(status: 'accepted').count

      next unless current_number_of_people != expected_number_of_people

      yield(model, current_number_of_people, expected_number_of_people) if block_given?
    end
  end

  def self.check_number_of_people(model_class)
    on_differing_rows(model_class) do |model, current_number_of_people, expected_number_of_people|
      puts "#{model_class.name} #{model.id} has" \
        " current number_of_people of value #{current_number_of_people}" \
        " expected number_of_people of value #{expected_number_of_people}"
    end
  end

  def self.fix_number_of_people(model_class)
    on_differing_rows(model_class) do |model, _, expected_number_of_people|
      model.update_column(:number_of_people, expected_number_of_people)
    end
  end
end
