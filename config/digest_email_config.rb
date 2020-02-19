module DigestEmailConfig
  CITIES = {
    Paris:    75,
    Lyon:     69,
    'Hauts-de-Seine' => 92,
    Lille:    59,
    Rennes:   35,
  }

  SCHEDULE = {
    day: :sunday,
    time: 9,
    min_interval: 2.months
  }

  def self.cities
    CITIES
  end

  def self.schedule
    @schedule ||= OpenStruct.new(SCHEDULE)
  end
end
