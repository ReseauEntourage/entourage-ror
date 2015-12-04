class TourCollectionPresenter
  include Enumerable

  def initialize(tours:)
    @tours = tours
  end

  def each
    tours.each {|tour| yield(TourPresenter.new(tour: tour)) }
  end

  private
  attr_reader :tours
end