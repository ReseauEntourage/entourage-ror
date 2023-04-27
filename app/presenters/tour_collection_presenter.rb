class TourCollectionPresenter < ApplicationPresenter
  include Enumerable
  include ActionView::Helpers

  def initialize(tours:)
    @tours = tours
  end

  def each
    tours.each {|tour| yield(TourPresenter.new(tour: tour)) }
  end

  def latest_tours
    return @latest_tours if @latest_tours != nil

    collection = tours.includes(:user => :organization).order('tours.updated_at DESC').limit(8).to_a
    collection_cache = CollectionCache.new(collection)
    @latest_tours = collection
      .group_by { |t| t.updated_at.to_date }
      .map { |day, tours| [collection_cache, day, tours] }
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

  class CollectionCache
    def initialize(tours)
      @tour_ids = tours.map(&:id)
    end

    def encounters_count(tour)
      raise "Tour##{tour.id} is not part of this collection" unless tour.id.in?(@tour_ids)
      @encounter_counts ||= collection_encounters_counts
      @encounter_counts[tour.id]
    end

    def collection_encounters_counts
      counts = Encounter.where(tour_id: @tour_ids).group(:tour_id).count
      counts.default = 0
      counts
    end

    def duration(tour)
      raise "Tour##{tour.id} is not part of this collection" unless tour.id.in?(@tour_ids)
      @durations ||= collection_durations
      @durations[tour.id]
    end

    def collection_durations
      Hash[TourPoint.where(tour_id: @tour_ids).group(:tour_id).pluck(Arel.sql("tour_id, extract(epoch from max(created_at) - min(created_at))"))]
    end
  end
end
