module V1
  module Actions
    class ContributionSerializer < V1::Actions::GenericSerializer
      def image_url
        return unless object.image_url.present?

        Contribution.url_for(object.image_url)
      end
    end
  end
end
