# It's a bit hard to make a SQL query for this so here's a script.
# Usage :
#   $ heroku run rails c -a entourage-back
#   irb> load 'area_user_count_estimator.rb'
#   irb> AreaUserCountEstimator.estimated_new_users_in_zones_for_range
module AreaUserCountEstimator
  DEFAULT_AREA = %w(75 92 69 38 35 59).freeze

  def self.users
    User.where(community: :entourage)
  end

  def self.new_users_for_range range
    users.where(created_at: range)
  end

  def self.new_users_with_postal_code_for_range range
    new_users_for_range(range).joins(:address)
  end

  def self.new_users_with_postal_code_in_zones_for_range range, departements=nil
    if departements.nil?
      departements = DEFAULT_AREA
    else
      departements = departements.map(&:to_s)
    end

    new_users_with_postal_code_for_range(range)
      .where("country = 'FR' and substring(postal_code for 2) in (?)", departements)
  end

  def self.ratio_of_new_users_with_postal_code_in_zones_for_range range, departements=nil
    total = new_users_with_postal_code_for_range(range).count
    return 0 if total == 0
    new_users_with_postal_code_in_zones_for_range(range, departements).count / total.to_f
  end

  def self.estimated_new_users_in_zones_for_range range=nil, departements: nil, granularity: 1.month
    first_user_at = users.minimum(:created_at).midnight
    range ||= first_user_at..Time.zone.now
    range = [first_user_at, range.first].max..[Time.zone.now, range.last].min

    # The point at which we start to have a postal code for most new users
    detailed_data_start = Time.zone.local(2018, 9)

    # The range will be split in chunks of 1 month (or `granularity` if set)
    # then for each chuck, we calculate the ratio of users that have a postal
    # code in the selected `departements`.
    # Finally we apply that ratio to the total number of new users created
    # during that chunk.
    # We create only one large chunk for the rage before `detailed_data_start`.
    ranges = []
    first = range.first
    while first < range.last
      if range.last < detailed_data_start
        last = range.last
      elsif first < detailed_data_start
        last = detailed_data_start
      else
        last = [first + granularity, range.last].min
      end
      ranges.push first...last
      first = last
    end

    estimates = ranges.map do |range|
      ratio = ratio_of_new_users_with_postal_code_in_zones_for_range(range, departements)
      count = new_users_for_range(range).count
      estimate = ratio * count
      puts "[#{range.first.strftime('%d %b %y %H:%M')} - #{range.last.strftime('%d %b %y  %H:%M')}[ : #{ratio.round(2)} ⨉ #{count} = #{estimate.round}"
      estimate
    end

    estimates.sum.round
  end
end
