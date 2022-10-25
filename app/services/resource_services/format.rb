module ResourceServices
  class Format
    def initialize resource:
      @resource = resource
    end

    def to_html
      ApplicationController.render(
        template: 'resources/api_show',
        assigns: { resource: @resource },
        layout: nil
      )
    end
  end
end
