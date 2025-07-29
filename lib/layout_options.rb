module LayoutOptions
  # Conçu pour être inclus dans un controller.
  # Permet de définir en cascade des options pour le layout
  # permettant par exemple de masquer un élément du header
  # pour toutes les pages d'un controller, ou pour une action unique.
  #
  # Quand aucun paramètre n'est passé, retourne le Hash des options.
  # Quand un Hash est passé, fusionne ce Hash aux options existantes.
  #
  # Exemple :
  #
  # >> layout_options
  # >> => {}
  # >> layout_options header_search: true, header_login: true
  # >> => {header_search: true, header_login: true}
  # >> layout_options header_search: false
  # >> => {header_search: false, header_login: true}
  # >> layout_options
  # >> => {header_search: false, header_login: true}
  # >> layout_options[:header_search]
  # >> => false
  #
  # Ordre de priorité, de la plus faible à la plus élevée :
  #   default_layout_options dans un partial du layout (ex : layouts/header)
  #   default_layout_options dans un layout
  #   default_layout_options dans une view
  #   layout_options dans un controller
  #   layout_options dans une action
  #   layout_options dans une view
  #   layout_options dans un layout (devrait être évité)

  private
  def self.included(controller)
    controller.class_eval do
      private
      extend ControllerMethods
      def layout_options options={}
        @layout_options ||= {}
        case options
        when nil
          @layout_options
        when Hash
          @layout_options = @layout_options.merge(options)
        else
          raise ArgumentError.new('layout_options takes an optional Hash')
        end
      end
      helper_method :layout_options
      helper ViewMethods
    end
  end

  module ControllerMethods
    private
    # Exemple :
    # layout_options header_search: false, only: :home
    #
    # Si un block est passé, il est évalué dans le contexte du controller.
    # Exemple :
    # layout_options do
    #   { chat: current_user.present? }
    # end
    def layout_options options={}, &block
      filter_options = options.extract!(:only, :except)
      before_action filter_options do
        options = options.merge(self.instance_eval(&block)) if block.present?
        layout_options options
      end
    end
  end

  module ViewMethods
    private
    def default_layout_options options={}
      case options
      when Hash
        controller.instance_eval do
          @layout_options ||= {}
          @layout_options = options.merge(@layout_options)
        end
      else
        raise ArgumentError.new('default_layout_options takes a Hash')
      end
    end
  end
end
