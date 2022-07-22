module V1
  module Actions
    class ContributionHomeSerializer < V1::Actions::GenericHomeSerializer
      def image_url
        return unless object.image_url.present?

        Contribution.url_for(object.image_url)
      end
    end
  end
end
