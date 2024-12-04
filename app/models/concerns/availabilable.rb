module Availabilable
  extend ActiveSupport::Concern

  included do
    validate :validate_availability_format
  end

  def validate_availability_format
    return if availability.blank?

    unless availability.is_a?(Hash)
      errors.add(:availability, 'doit être un hash')
      return
    end

    availability.each do |day, slots|
      unless day.to_i.between?(1, 7)
        errors.add(:availability, "contient un jour invalide (#{day})")
      end

      unless slots.is_a?(Array)
        errors.add(:availability, "les créneaux pour le jour #{day} doivent être un tableau")
        next
      end

      slots.each do |slot|
        unless slot.match?(/^\d{2}:\d{2}-\d{2}:\d{2}$/)
          errors.add(:availability, "le créneau #{slot} pour le jour #{day} est invalide")
          next # next slot if invalid format
        end

        # check hour format
        start_time, end_time = slot.split('-').map { |time| time.split(':').map(&:to_i) }
        unless start_time[0].between?(0, 23) && end_time[0].between?(0, 24) &&
               start_time[1].between?(0, 59) && end_time[1].between?(0, 59) &&
               (end_time[0] > start_time[0] || (end_time[0] == start_time[0] && end_time[1] > start_time[1]))
          errors.add(:availability, "le créneau #{slot} pour le jour #{day} contient une heure invalide")
        end
      end
    end
  end

  def availability_formatted
    availability.map do |day_number, hours|
      "#{Availabilable.day_name(day_number)} : #{hours.join(', ')}"
    end.join("\n")
  end

  def self.day_name day_number
    I18n.t("date.day_names")[day_number.to_i % 7]
  end
end
