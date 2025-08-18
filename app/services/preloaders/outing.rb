module Preloaders
  module Outing
    def self.preload_images(outings, scope: nil)
      outings = outings.to_a
      return if outings.empty?

      images = ImageResizeAction
        .select("path, destination_path")
        .with_bucket_and_path(::Outing.bucket_name, outings.map(&:landscape_url).compact.uniq)
        .merge(scope || ChatMessage.all)
        .index_by { |image| image.path }

      outings.each do |outing|
        outing.preload_image_url = images[outing.landscape_url]
      end
    end

    def self.preload_member_ids(outings, scope: nil)
      outings = outings.to_a
      return if outings.empty?

      join_requests = ::JoinRequest
        .select("joinable_id, array_agg(user_id) as preload_member_ids")
        .where(joinable_type: :Entourage, joinable_id: outings.map(&:id))
        .merge(scope || ::JoinRequest.all)
        .group(:joinable_id)
        .index_by { |join_request| join_request.joinable_id }

      outings.each do |outing|
        next unless join_requests[outing.id].present?

        outing.preload_member_ids = join_requests[outing.id].preload_member_ids
      end
    end

    def self.sanitize_sql(condition)
      ActiveRecord::Base.send(:sanitize_sql_array, condition)
    end
  end
end
