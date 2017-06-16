namespace :data_migration do

  task set_entourage_score: :environment do
    start = Time.now
    puts "start at #{start}"
    Entourage.find_each do |entourage|
      entourage_start = Time.now
      puts "Start compute score for entourage #{entourage.id} at #{entourage_start}"
      User.find_each do |user|15593
        puts "Start compute score for user #{user.id} at #{entourage_start}"
        EntourageServices::ScoreCalculator.new(entourage: entourage, user: user).calculate
      end
      entourage_stop = Time.now
      puts "Stop computing score for entourage #{entourage.id} in #{entourage_stop - entourage_start} at #{entourage_stop}"
    end
    stop = Time.now
    puts "stop in #{stop.to_i - start.to_i} at #{stop}"
  end

end
