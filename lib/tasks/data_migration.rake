namespace :data_migration do

  task set_entourage_category: :environment do
    Entourage.find_each do |entourage|
      puts "update entourage #{entourage.id}"
      text = "#{entourage.title} #{entourage.description}"
      category = EntourageServices::CategoryLexicon.new(text: text).category
      next unless category
      entourage.update(category: category)
    end
  end
end
