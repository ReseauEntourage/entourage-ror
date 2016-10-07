namespace :fake_data do

  desc "create test users account"
  task test_accounts: :environment do
    tecknoworks = Organization.where(name: "tecknoworks", phone: "+401234567", description: "tecknoworks", address: "foobar").first_or_create!
    User.where(phone: ["+40742224359", "+33740884267", "+40743044174", "+33623456789", "+40724591112", "+40724591113", "+40724591114", "+40723199641"]).destroy_all
    User.create!(phone: "+40742224359", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "brindusa.duma@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+33740884267", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "chip+1@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40743044174", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "mihai.ionescu@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+33623456789", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "entourage@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40724591112", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.corde54@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40724591113", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.corde6@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40724591114", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.corde7@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
    User.create!(phone: "+40723199641", user_type: "pro", sms_code: "123456", organization: tecknoworks, email: "vasile.cordea@tecknoworks.com", token: SecureRandom.hex(8), first_name: "foo", last_name: "bar")
  end


  desc "create users"
  task :users, [:number_of_users] => [:environment] do |t, args|
    number_of_users = args[:number_of_users].to_i

    values = Proc.new do |index|
      array = [DateTime.now,
               DateTime.now,
               "#{SecureRandom.uuid}@mail.com",
               "+336#{99999999-index}"].map {|val| "'#{val}'"}
                  .join(",")
      "(#{array})"
    end

    insert_batch(table: "users",
                 keys: "(created_at, updated_at, email, phone)",
                 number: number_of_users,
                 &values)

    puts "Done"
  end

  def insert_elements(table:, keys:, previous_index:, number_to_insert:, &block)
    puts "Creating #{number_to_insert} #{table}"
    values = (1..number_to_insert).map do |index|
      block.call(index + previous_index)
    end.join(",")

    sql = "INSERT INTO #{table} #{keys} VALUES #{values}"
    ActiveRecord::Base.connection.execute(sql)
  end

  #TODO => extract to a gem, see https://github.com/jamis/bulk_insert
  MAX_INSERTS=100_000
  def insert_batch(table:, keys:, number:, number_by_iterations: MAX_INSERTS, &block)
    raise "CANNOT INSERT 0 ROWS, CHECK YOUR PARAMATERS" if number==0
    if number > number_by_iterations
      iterations = (number / number_by_iterations.to_f).floor
      number_to_insert = number_by_iterations
    else
      iterations = 1
      number_to_insert = number
    end

    ActiveRecord::Base.transaction do
      iterations.times do |iteration|
        insert_elements(table: table, keys: keys, previous_index: number_to_insert*iteration, number_to_insert: number_to_insert, &block)
      end

      remaining = number - (number_to_insert * iterations)
      insert_elements(table: table, keys: keys, previous_index: number_to_insert*iterations, number_to_insert: remaining, &block) unless remaining==0
    end
  end

  require 'set'
  def rand_n(n, max)
    randoms = Set.new
    loop do
      randoms << rand(max)
      return randoms.to_a if randoms.size >= n
    end
  end
end
