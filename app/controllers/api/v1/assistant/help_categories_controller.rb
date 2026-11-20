module Api
  module V1
    module Assistant
      # The categories of help that exist in the app. None is added for the assistant.
      class HelpCategoriesController < BaseController
        def read
          render json: { categories: ::Tag.sections.map { |id, names| { id: id.to_s, name: names[:name] } } }
        end
      end
    end
  end
end
