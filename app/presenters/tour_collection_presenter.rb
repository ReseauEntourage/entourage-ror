class TourCollectionPresenter
  include Enumerable
  include ActionView::Helpers

  def initialize(tours:)
    @tours = tours
  end

  def each
    tours.each {|tour| yield(TourPresenter.new(tour: tour)) }
  end

  def latest_tours
    @latest_tours ||= tours.order('tours.updated_at DESC').limit(8).group_by { |t| t.updated_at.to_date }
  end

  def week_tours
    @week_tours ||= tours.where("tours.updated_at >= ?", DateTime.now.monday)
  end

  def total_length
    number_to_human(week_tours.sum(:length), precision: 4, units: {unit: "m", thousand: "km"})
  end

  def encounter_count
    @encounter_count ||= Encounter.where(tour: week_tours).count
  end

  def tourer_count
    week_tours.select(:user_id).distinct.count
  end

  private
  attr_reader :tours
end