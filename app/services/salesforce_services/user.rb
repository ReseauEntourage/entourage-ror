module SalesforceServices
  class User < Connect
    TABLE_NAME = "Compte_App__c"

    UPDATABLE_FIELDS = [:validation_status, :first_name, :last_name, :email, :phone, :goal, :targeting_profile]

    GOAL_MAPPING = {
      ask_for_help: "preca",
      offer_help: "riverain",
      organization: "asso",
      default: "inconnu"
    }
    TARGETING_PROFILE_MAPPING = {
      asks_for_help: "preca",
      offers_help: "riverain",
      partner: "asso",
      team: "asso",
      ambassador: "riverain",
      default: "inconnu"
    }

    def find_id_by_user user
      return unless attributes = find_by_external_id(user.id)
      return unless attributes.any?

      attributes["Id"]
    end

    def update user
      client.update(TABLE_NAME, Id: find_id_by_user(user), **user_to_hash(user))
    end

    def upsert user
      fields = user_to_hash(user).merge({
        "Prospect__c" => lead_id(user),
        "Contact__c" => contact_id!(user),
      })

      client.upsert!(TABLE_NAME, "UserId__c", "UserId__c": user.id, **fields)
    end

    def destroy user
      client.destroy(TABLE_NAME, find_id_by_user(user))
    end

    # helpers

    def user_to_hash user
      {
        "Prenom__c" => user.first_name,
        "Nom__c" => user.last_name,
        "Email__c" => user.email,
        "Telephone__c" => user.phone,
        "ProfilDeclare__c" => profil_declare(user),
        "ProfilModeration__c" => profil_moderation(user),
        "Antenne__c" => antenne(user),
        "Code_postal__c" => user.postal_code,
        "Geolocalisation__Latitude__s" => user.latitude,
        "Geolocalisation__Longitude__s" => user.longitude,
        "DateCreationCompte__c" => user.created_at.strftime("%Y-%m-%d"),
        "DateDerniereConnexion__c" => user.last_sign_in_at.strftime("%Y-%m-%d"),
      }
    end

    def updatable_fields
      UPDATABLE_FIELDS
    end

    private

    def find_by_external_id user_id
      client.query("select Id from #{TABLE_NAME} where UserId__c = #{user_id}").first
    end

    def lead_id user
      Lead.new.find_id_by_user(user)
    end

    def contact_id! user
      Contact.new.creasert(user)
    end

    def profil_declare user
      return GOAL_MAPPING[:default] unless user.goal.present?
      return GOAL_MAPPING[user.goal.to_sym] if GOAL_MAPPING[user.goal.to_sym]

      GOAL_MAPPING[:default]
    end

    def profil_moderation user
      return TARGETING_PROFILE_MAPPING[:default] unless user.targeting_profile.present?
      return TARGETING_PROFILE_MAPPING[user.targeting_profile.to_sym] if TARGETING_PROFILE_MAPPING[user.targeting_profile.to_sym]

      TARGETING_PROFILE_MAPPING[:default]
    end

    def antenne user
      user.sf.from_address_to_antenne
    end
  end
end
