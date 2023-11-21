module ResourceServices
  class Format
    def initialize resource:, lang:
      @resource = resource
      @lang = lang
    end

    def to_html
      ApplicationController.render(
        template: 'resources/api_show',
        assigns: { resource: @resource, lang: @lang },
        layout: nil
      )
    end
  end
end
