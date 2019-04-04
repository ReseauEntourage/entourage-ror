module DigestEmailConfig
  CITIES = {
    Paris:    75,
    Lyon:     69,
    Rennes:   35,
    Grenoble: 38,
    Lille:    59,
  }

  SCHEDULE = {
    day: :sunday,
    time: 9,
    min_interval: 2.weeks
  }

  def self.cities
    CITIES
  end

  def self.schedule
    @schedule ||= OpenStruct.new(SCHEDULE)
  end
end
