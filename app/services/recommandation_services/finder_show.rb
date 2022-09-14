module RecommandationServices
  class FinderShow
    class << self
      def find_identifiant user, recommandation
        return recommandation.id unless recommandation.webview?

        recommandation.url
      end
    end
  end
end
