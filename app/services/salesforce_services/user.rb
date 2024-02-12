module SalesforceServices
  class User < Connect
    TABLE_NAME = "Compte_App__c"

    # ProfilDeclare__c inconnu 01JAa00000Gfflx
    # ProfilDeclare__c riverain 01JAa00000Gffly
    # ProfilDeclare__c preca 01JAa00000Gfflz
    # ProfilDeclare__c asso 01JAa00000Gffm0

    # ProfilModeration__c inconnu 01JAa00000GfVMt
    # ProfilModeration__c riverain 01JAa00000GfVMu
    # ProfilModeration__c preca 01JAa00000GfVMv
    # ProfilModeration__c asso 01JAa00000GfVMw

    def id user
      return unless attributes = find_by_external_id(user.id)
      return unless attributes.any?

      attributes["Id"]
    end

    def find_by_external_id user_id
      client.query("select Id from #{TABLE_NAME} where UserId__c = #{user_id}").first
    end

    def update user
      client.update(TABLE_NAME, Id: id(user), **user_to_hash(user))
    end

    def upsert user
      fields = user_to_hash(user).merge({
        "Prospect__c" => lead_id(user),
        "Contact__c" => contact_id!(user),
      })

      client.upsert!(TABLE_NAME, "UserId__c", "UserId__c": user.id, **fields)
    end

    def destroy user
      client.destroy(TABLE_NAME, id(user))
    end

    # helpers

    def user_to_hash user
      {
        "Prenom__c" => user.first_name,
        "Nom__c" => user.last_name,
        "Email__c" => user.email,
        "Telephone__c" => user.phone,
        "ProfilDeclare__c" => user.ask_for_help? ? "preca" : "riverain",
        "ProfilModeration__c" => user.is_ask_for_help? ? "preca" : "riverain",
        "Antenne__c" => "National",
        "Code_postal__c" => user.postal_code,
        "Geolocalisation__Latitude__s" => user.latitude,
        "Geolocalisation__Longitude__s" => user.longitude,
        "DateCreationCompte__c" => user.created_at.strftime("%Y-%m-%d"),
        "DateDerniereConnexion__c" => user.last_sign_in_at.strftime("%Y-%m-%d"),
      }
    end

    def lead_id user
      Lead.new.find_id_by_user(user)
    end

    def contact_id! user
      Contact.new.creasert(user)
    end
  end
end
