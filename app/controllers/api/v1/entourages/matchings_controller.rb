module Api
  module V1
    module Entourages
      class MatchingsController < Api::V1::BaseController
        skip_before_action :authenticate_user!

        before_action :set_entourage

        def index
          render json: {
            contributions: ActiveModel::Serializer::CollectionSerializer.new(
              get_contributions,
              serializer: ::V1::Matchings::ActionSerializer,
              scope: { latitude: latitude, longitude: longitude }
            ),
            solicitations: ActiveModel::Serializer::CollectionSerializer.new(
              get_solicitations,
              serializer: ::V1::Matchings::ActionSerializer,
              scope: { latitude: latitude, longitude: longitude }
            ),
            outings: ActiveModel::Serializer::CollectionSerializer.new(
              get_outings,
              serializer: ::V1::Matchings::OutingSerializer,
              scope: { latitude: latitude, longitude: longitude }
            ),
            resources: ActiveModel::Serializer::CollectionSerializer.new(
              get_resources,
              serializer: ::V1::Matchings::ResourceSerializer
            ),
            pois: ActiveModel::Serializer::CollectionSerializer.new(
              get_pois,
              serializer: ::V1::Matchings::PoiSerializer,
              scope: { latitude: latitude, longitude: longitude }
            )
          }
        end

        def contributions
          render json: get_contributions, root: :contributions, each_serializer: ::V1::Matchings::ActionSerializer, scope: {
            latitude: latitude,
            longitude: longitude
          }
        end

        def solicitations
          render json: get_solicitations, root: :solicitations, each_serializer: ::V1::Matchings::ActionSerializer, scope: {
            latitude: latitude,
            longitude: longitude
          }
        end

        def outings
          render json: get_outings, root: :outings, each_serializer: ::V1::Matchings::OutingSerializer, scope: {
            latitude: latitude,
            longitude: longitude
          }
        end

        def resources
          render json: Resource.where(status: :active), root: :resources, each_serializer: ::V1::Matchings::ResourceSerializer, scope: {
            latitude: latitude,
            longitude: longitude
          }
        end

        def pois
          render json: get_pois, root: :pois, each_serializer: ::V1::Matchings::PoiSerializer, scope: {
            latitude: latitude,
            longitude: longitude
          }
        end

        private

        def set_entourage
          @entourage = Entourage.findable_by_id_or_uuid(params[:entourage_id])
        end

        def get_contributions
          ContributionServices::Finder.new(@entourage.user, index_params).find_all.page(page).per(per)
        end

        def get_solicitations
          SolicitationServices::Finder.new(@entourage.user, index_params).find_all.page(page).per(per)
        end

        def get_outings
          OutingsServices::Finder.new(@entourage.user, index_params).find_all.page(page).per(per)
        end

        def get_resources
          Resource.where(status: :active)
        end

        def get_pois
          Poi.validated.around(latitude, longitude, distance).limit(per)
        end

        def index_params
          # no params for now
          Hash.new
        end

        def latitude
          @entourage.latitude
        end

        def longitude
          @entourage.longitude
        end

        def distance
          @entourage.user.travel_distance
        end

        def page
          params[:page] || 1
        end
      end
    end
  end
end
