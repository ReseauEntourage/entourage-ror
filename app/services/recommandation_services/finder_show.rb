module RecommandationServices
  class FinderShow
    class << self
      def find_identifiant user, recommandation
        recommandation.argument_value
      end
    end
  end
end
