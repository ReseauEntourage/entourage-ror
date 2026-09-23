module Preloaders
  # URL d'images redimensionnées : une requête ImageResizeAction par bucket et par taille pour
  # toute la page, au lieu d'une par image (@see ImageResizeAction.find_path_for)
  module Images
    # @see V1::PartnerSerializer#image_url
    def self.preload_partners partners, size: :medium
      partners = partners.compact.uniq

      ::ImageResizeAction.preload_paths(bucket: ::Partner.bucket_name, paths: partners.map(&:image_url_with_bucket), size: size)
    end

    # @see V1::ChatMessages::GenericSerializer#image_url, V1::Images::ChatMessageSerializer#url
    def self.preload_chat_messages chat_messages, size: :medium
      ::ImageResizeAction.preload_paths(bucket: ::ChatMessage.bucket_name, paths: chat_messages.map(&:image_url_with_bucket), size: size)
    end

    # logos des partenaires des auteurs (@see V1::EntourageSerializer#author) : l'auteur affiché
    # d'une conversation est l'autre participant, pris dans accepted_members quand ils sont chargés
    def self.preload_entourage_authors entourages
      preload_partners(entourages.flat_map do |entourage|
        members = entourage.conversation? && entourage.association(:accepted_members).loaded? ? entourage.accepted_members : []

        [entourage.user, *members].compact.map(&:partner)
      end)
    end
  end
end
