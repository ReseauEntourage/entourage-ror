module EntourageServices
  class ListExporter
    EntourageStruct = Struct.new(:entourage_id) do
      def initialize(entourage_id)
        @entourage = Entourage.find(entourage_id)
      end

      def display_address
        @entourage.metadata[:display_address]
      end

      def recurrency
        return unless @entourage.recurrent?
        return unless recurrence = OutingRecurrence.find_by_identifier(@entourage.recurrency_identifier)

        recurrence.recurrency
      end

      def method_missing(method_name)
        if @entourage.respond_to?(method_name)
          @entourage.send(method_name)
        else
          super
        end
      end

      def respond_to_missing?(method_name)
        @entourage.respond_to?(method_name) || super
      end
    end

    DEFAULT_PATH = "#{Rails.root}/tmp"

    FIELDS = %w{
      id
      title
      description
      display_address
      recurrency
      created_at
      starts_at
      ends_at
      image_url
      members_count
    }

    class << self
      def export entourage_ids
        file = path

        CSV.open(file, 'w+') do |writer|
          writer << FIELDS.map { |field| I18n.t("activerecord.attributes.entourage.#{field}") }

          entourage_ids.each do |entourage_id|
            entourage = EntourageStruct.new(entourage_id)
            writer << FIELDS.map { |field| entourage.send(field) }
          end
        end

        file
      end

      def path
        "#{DEFAULT_PATH}/entourages-#{Time.now.to_i}.csv"
      end
    end
  end
end
