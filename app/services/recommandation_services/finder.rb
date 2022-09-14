module RecommandationServices
  class Finder
    def initialize user
      @user = user
    end

    def find recommandation
      klass = "finder_#{recommandation.action}".classify

      return recommandation unless method_exists?(klass, :find_identifiant)

      recommandation.instance_key = recommandation.webview? ? :url : :id
      recommandation.instance_id = call_method(klass, :find_identifiant, @user, recommandation)
      recommandation
    end

    private

    def method_exists? klass, method
      RecommandationServices.const_get(klass).methods.include?(method)

      true
    rescue NameError
      false
    end

    def call_method klass, method, user, recommandation
      RecommandationServices.const_get(klass).send(method, user, recommandation)
    rescue
      nil
    end
  end
end
