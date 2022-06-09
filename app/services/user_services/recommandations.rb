module UserServices
  class Recommandations
    def initialize user
      @user = user
    end

    def find
      Recommandation.all.map do |recommandation|
        next recommandation unless recommandation.show?

        method = "find_#{recommandation.instance}".to_sym

        next unless self.class.instance_methods.include?(method)

        key, id = send(method)

        recommandation.instance_key = key
        recommandation.instance_id = id
        recommandation
      end.compact
    end

    def find_neighborhood
      [:id, Neighborhood.last.id]
    end

    def find_outing
      [:id, Entourage.where(group_type: :outing).last.id]
    end

    def find_resource
      # [:id, Resource.last.id]
    end

    def find_conversation
      [:id, Entourage.where(group_type: :conversation).last.id]
    end

    def find_contribution
      [:id, Entourage.where(entourage_type: :contribution).last.id]
    end

    def find_ask_for_help
      [:id, Entourage.where(entourage_type: :ask_for_help).last.id]
    end
  end
end
