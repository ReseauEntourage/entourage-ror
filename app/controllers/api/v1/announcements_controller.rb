module Api
  module V1
    class AnnouncementsController < Api::V1::BaseController
      skip_before_filter :authenticate_user!, only: [:icon, :avatar, :image]
      skip_before_filter :ensure_community!,  only: [:icon, :avatar, :image]
      allow_anonymous_access only: [:redirect]

      def icon
        # https://material.io/resources/icons/
        # white 48dp png
        # convert [...]-white-48dp/2x/[...]_white_48dp.png -gravity center -crop 84x84+0+0 [...].png
        # ImageOptim
        icon = {
          2 => :heart,
          3 => :pin,
          4 => :video,
          5 => :megaphone,
          6 => :megaphone,
          7 => :trophy,
          8 => :heart,
          9 => :heart,
          10 => :heart,
          11 => :trophy,
          12 => :text,
          13 => :megaphone,
          14 => :heart,
          15 => :megaphone,
          16 => :pin,
          17 => :heart,
          18 => :video,
          19 => :megaphone,
          20 => :video,
          21 => :heart,
          22 => :megaphone,
          23 => :megaphone,
          24 => :heart,
          25 => :video,
          26 => :megaphone,
          27 => :heart,
          28 => :video,
          29 => :text,
          30 => :megaphone,
          31 => :pin,
          32 => :video,
          33 => :heart,
          34 => :heart,
          35 => :chat,
          36 => :video,
          37 => :trophy,
          38 => :video,
          39 => :megaphone,
          40 => :megaphone,
          41 => :megaphone,
          42 => :megaphone,
          43 => :megaphone,
          44 => :megaphone,
          45 => :megaphone,
          46 => :megaphone,
          47 => :heart,
          48 => :heart,
          49 => :info,
          50 => :chat,
          51 => :heart,
          52 => :question,
          53 => :heart,
          54 => :video,
          55 => :question,
          56 => :video,
          57 => :heart,
          58 => :heart,
          59 => :chat,
          60 => :video,
          61 => :heart,
          62 => :question,
          63 => :heart,
          64 => :chat,
        }[params[:id].to_i]

        redirect_to view_context.asset_url("assets/announcements/icons/#{icon}.png")
      end

      def avatar
        avatar =
          case params[:id].to_i
          when 12
            'apero.png'
          else
            '1.jpg'
          end

        redirect_to view_context.asset_url("assets/announcements/avatars/#{avatar}")
      end

      def image
        image = {
          10 => 'guillaume.jpg',
          11 => 'action.jpg',
          13 => 'ambassadors-3.jpg',
          14 => 'collecte-2018.jpg',
          16 => 'noel.jpg',
          17 => '2.png',
          18 => 'scb.jpg',
          19 => 'grand-froid.png?2',
          20 => 'paroles-de-femmes.jpg',
          21 => 'talents-2018.jpg',
          22 => 'scb.jpg',
          23 => 'reseaux-sociaux.jpg',
          24 => 'webapp.jpg',
          25 => 'video-eric.jpg',
          26 => 'paperboard.jpg',
          27 => 'conversation.jpg',
          28 => 'video-nolwenn.jpg',
          29 => 'conversation-2.jpg',
          30 => 'ordinateur.jpg',
          31 => '31.jpg',
          32 => '32.jpg',
          33 => '33.jpg',
          34 => '34.jpg',
          35 => 'guillaume-3.jpg',
          36 => '36.jpg',
          37 => '37.jpg',
          38 => '38.jpg',
          39 => 'service-civique.jpg',
          40 => 'service-civique.jpg',
          41 => 'service-civique.jpg',
          42 => 'service-civique.jpg',
          43 => 'conversation-2.jpg',
          44 => 'linkedout.jpg',
          45 => 'canicule.jpg',
          46 => '3919.png',
          47 => 'stat-smartphone.png',
          48 => 'verbatims-2.jpg',
          49 => 'seis-4.png',
          50 => '50.jpg',
          51 => 'don-2019.jpg',
          52 => '52.jpg',
          53 => '53.jpg',
          54 => '54.jpg',
          55 => '55.jpg',
          56 => '56.jpg',
          57 => '57.jpg',
          58 => '58.jpg',
          59 => '59.jpg',
          60 => '60.jpg',
          61 => '61-2.jpg',
          62 => '62.jpg',
          63 => '63.jpg',
          64 => '64.jpg',
        }[params[:id].to_i]

        return render nothing: true, status: :not_found if image.nil?

        redirect_to view_context.asset_url("assets/announcements/images/#{image}")
      end

      def redirect
        id = params[:id].to_i

        case id
        when 2
          url = "#{ENV['WEBSITE_URL']}/don"

          if current_user
            url +=
              "?firstname=#{current_user.first_name}" +
              "&lastname=#{current_user.last_name}" +
              "&email=#{current_user.email}" +
              "&external_id=#{current_user.id}" +
              "&utm_medium=APP" +
              "&utm_campaign=DEC2017"

            if current_user.id % 2 == 0
              url += "&utm_source=APP-S1"
            else
              url += "&utm_source=APP-S2"
            end
          end
        when 3
          user_id =
            if current_user
              UserServices::EncodedId.encode(current_user.id)
            else
              "anonymous"
            end
          url = "https://entourage-asso.typeform.com/to/WIg5A9?user_id=#{user_id}"
        when 4
          url = "http://www.simplecommebonjour.org/?p=153"
        when 6
          url = "https://blog.entourage.social/2018/01/15/securite-et-moderation/"
        when 7
          url = "https://blog.entourage.social/2018/03/02/top-5-des-actions-reussies/"
        when 8
          url = "https://blog.entourage.social/2017/07/28/le-comite-de-la-rue-quest-ce-que-cest/"
        when 9
          url = "https://blog.entourage.social/2018/05/17/fete-des-voisins-2018-invitons-aussi-nos-voisins-sdf/"
        when 11
          url = "https://blog.entourage.social/2017/04/28/quelles-actions-faire-avec-entourage/#site-content"
        when 12
          url = "https://blog.entourage.social/2018/07/27/roya-michael-il-avait-besoin-dun-semblant-de-famille/"
        when 13
          url = "https://www.entourage.social/devenir-ambassadeur"
        when 14
          url = "https://entourage.iraiser.eu/mon-don/~mon-don"
        when 15
          url = "https://blog.entourage.social/2018/11/30/noel-solidaire-faisons-tous-le-calendrier-de-lavent-inverse/"
        when 16
          url = "https://blog.entourage.social/2018/11/29/noel-solidaire-2018-aupres-des-personnes-sdf-du-benevolat-pour-le-reveillon/"
        when 17
          url = "https://www.entourage.social/"
        when 18
          url = "http://www.simplecommebonjour.org/?p=8"
        when 19
          url = "https://blog.entourage.social/2017/01/17/grand-froid-comment-aider-les-personnes-sans-abri-a-son-echelle/#site-content"
        when 20
          url = "http://www.simplecommebonjour.org/?p=12"
        when 21
          url = "https://blog.entourage.social/2019/01/02/soiree-de-noel-entourage-x-refettorio-la-rue-est-pleine-de-talents/#site-content"
        when 22
          url = "http://www.simplecommebonjour.org/"
        when 23
          url = "https://www.facebook.com/EntourageReseauCivique/"
        when 24
          url = "https://www.entourage.social/app"
        when 25
          url = "https://www.youtube.com/watch?v=AsUyal44DXk"
        when 26
          url = "http://bit.ly/2tvGgcH"
        when 27
          url = "https://blog.entourage.social/category/belles-histoires/#nav-search"
        when 28
          url = "https://www.youtube.com/watch?v=UcODKwV9bO8&list=PLwLEgqe22sVYuK9ySGExo8JfgAzlqWUV9"
        when 29
          url = "https://blog.entourage.social/2019/03/04/comment-puis-je-inviter-des-personnes-sdf-sur-le-reseau-entourage/#site-content"
        when 32
          url = "https://www.youtube.com/watch?v=QXcUptypnOY"
        when 33
          url = "https://blog.entourage.social/2017/07/06/appli-entourage-les-10-plus-belles-actions/#site-content"
        when 34
          url = "https://blog.entourage.social/2017/07/28/le-comite-de-la-rue-entourage/#site-content"
        when 36
          url = "https://www.youtube.com/watch?v=IYUo5WAZxXs"
        when 37
          url = "https://blog.entourage.social/2017/04/28/quelles-actions-faire-avec-entourage/#site-content"
        when 38
          url = "https://www.youtube.com/watch?v=Dk3bo__5dvs"
        when 39
          # url = "https://www.service-civique.gouv.fr/missions/paris-creer-du-lien-social-autour-des-personnes-sans-abri"
          url = "https://www.welcometothejungle.co/fr/companies/entourage/jobs/developpement-de-communaute-voisins-avec-et-sans-abri_paris"
        when 40
          # url = "https://www.service-civique.gouv.fr/missions/lyon-creer-du-lien-social-autour-des-personnes-sans-abri"
          url = "https://www.welcometothejungle.co/fr/companies/entourage/jobs/animation-de-communaute-terrain_lyon"
        when 41
          # url = "https://www.service-civique.gouv.fr/missions/lille-creer-du-lien-social-autour-des-personnes-sans-abri"
          url = "https://www.welcometothejungle.co/fr/companies/entourage/jobs/developpement-de-communaute-voisins-avec-et-sans-abri_paris"
        when 42
          # url = "https://www.welcometothejungle.co/fr/companies/entourage/jobs"
          url = "https://www.welcometothejungle.co/fr/companies/entourage/jobs/developpement-de-communaute-voisins-avec-et-sans-abri_paris"
        when 43
          url = "https://blog.entourage.social/2017/06/19/charles-aznavour-avait-tort-la-misere-nest-pas-moins-penible-au-soleil/#site-content"
        when 44
          url = "https://www.linkedout.fr/"
        when 45
          url = "https://blog.entourage.social/2017/06/19/charles-aznavour-avait-tort-la-misere-nest-pas-moins-penible-au-soleil/#site-content"
        when 46
          url = "http://www.solidaritefemmes.org/"
        when 48
          user_id =
            if current_user
              UserServices::EncodedId.encode(current_user.id)
            else
              "anonymous"
            end
          url = "https://entourage-asso.typeform.com/to/QeQ4X7?user_id=#{user_id}"
        when 49
          url = "https://www.askoria.eu/seis/"
        when 50
          url = "https://wa.me/?text=J%E2%80%99ai%20d%C3%A9couvert%20une%20super%20app%20qui%20permet%20d%E2%80%99aider%20facilement%20les%20personnes%20SDF%20pr%C3%A8s%20de%20chez%20soi%2C%20Entourage.%20Tu%20devrais%20la%20t%C3%A9l%C3%A9charger%20aussi%20%C3%A7a%20prend%2030%20secondes%20!%20bit.ly%2Fappentourage-w"
        when 51, 60
          url = "https://www.effet.entourage.social/?utm_medium=carteannonce&utm_source=app&utm_campaign=dons2019"
          if current_user
            url += "&utm_term=db#{UserServices::EncodedId.encode(current_user.id)}"
          else
            url += "&utm_term=anonymous"
          end
        when 52
          url = "https://entourage-asso.typeform.com/to/pdm0w3"
        when 53
          url = "https://blog.entourage.social/2019/12/04/noel-solidaire-2019-aupres-des-personnes-sdf-du-benevolat-pour-le-reveillon/#site-content"
        when 54
          url = "http://www.simplecommebonjour.org/?p=169"
        when 55
          url = "https://entourage-asso.typeform.com/to/MgHVyc?mc_user_id=#{current_user&.id}"
        when 56
          url = "https://www.facebook.com/watch/?v=402957420659669"
        when 57
          url = "https://blog.entourage.social/2019/11/28/calendrier-de-lavent-solidaire-2019-24-jours-guides-par-entourage/#site-content"
        when 61
          url = "https://blog.entourage.social/2020/03/13/covid-19-et-personnes-sdf-quelques-conseils/#site-content"
        when 62
          url = "http://www.solinum.org/category/info-coronavirus/"
        when 63
          url = "https://blog.entourage.social/2020/03/20/gardons-le-moral-convivialite-100-digitale-loin-des-yeux-pres-du-coeur-%f0%9f%a7%a1/#site-content"
        when 64
          url = "https://blog.entourage.social/2020/03/18/journal-du-confinement-de-personnes-sdf/#site-content"
        end

        begin
          uri = URI(url)
          url_params = CGI.parse(uri.query || '')
          {
            utm_source: 'app',
            utm_medium: 'announcement-card'
          }.each do |key, value|
            url_params[key] = value unless url_params.key?(key.to_s)
          end
          uri.query = URI.encode_www_form(url_params).presence
          url = uri.to_s
        rescue => e
          Raven.capture_exception(e)
        end

        unless current_user_or_anonymous.anonymous?
          mixpanel.track("Opened Announcement", { "Announcement" => id })
        end

        redirect_to url
      end
    end
  end
end
