require 'sidekiq/web'
require 'super_admin_constraint'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/super_admin/sidekiq', :constraints => SuperAdminConstraint.new

  #ADMIN
  constraints :subdomain => /\A(admin|admin-preprod|admin-test|admin-preprod-test)\z/ do
    scope :module => "admin", :as => "admin" do
      get '/' => 'base#home'
      get 'logout' => 'sessions#logout'
      get '/sessions/new', to: redirect('/admin/sessions/new')

      get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
      delete 'user_relationships' => "user_relationships#destroy"

      namespace :salesforce do
        resources :schemas, only: [] do
          collection do
            get :show_user
            get :show_outing
            get :show_lead
            get :show_contact
            get :show_sf_entreprise
          end
        end

        resources :users, only: [:index, :show]
        resources :outings, only: [:index, :show]
        resources :contacts, only: [:index]
        resources :sf_entreprises, only: [:index]
      end

      namespace :super_admin do
        get '/soliguide', action: :soliguide
        get '/soliguide_show/:id' => :soliguide_show, as: :soliguide_show
        get '/testings', action: :testings
      end

      resources :actions, only: [:index] do
        resources :matchings, :controller => 'actions/matchings', only: [:index] do
          collection do
            post :notify_best
            post :mail_best
          end

          member do
            post :notify
            post :mail
          end
        end
      end

      resources :announcements do
        collection do
          post :reorder
        end

        member do
          get '/edit/image', action: :edit_image
          get '/image_upload_success', action: :image_upload_success
          get '/edit/image_portrait', action: :edit_image_portrait
          get '/image_portrait_upload_success', action: :image_portrait_upload_success
        end
      end

      resources :chat_messages, only: [:show, :update] do
        member do
          get :cancel_update
          get '/edit/photo', action: :edit_photo
          get '/cancel_update/photo', action: :cancel_update_photo
          delete '/delete/photo', action: :delete_photo
          get '/photo_upload_success', action: :photo_upload_success
        end
      end

      resources :conversations, only: [:index, :show, :new, :create] do
        member do
          get :chat_messages
          get :prepend_chat_messages
          get :show_members
          post :message
          post :invite
          post :read_status
          post :archive_status
          post :unjoin
        end

        collection do
          delete :destroy_message
        end
      end

      resources :entourages, only: [:index, :show, :new, :create, :edit, :update] do
        member do
          post :moderator_read
          post :moderator_unread
          post :message
          get :show_members
          get :show_messages
          get :show_neighborhoods
          get 'comments/:message_id' => :show_comments, as: :show_comments
          get :show_matchings
          get :show_siblings
          post :send_matching
          post :stop_recurrences
          get :sensitive_words
          post :sensitive_words_check
          get :edit_type
          get :edit_owner
          post :close
          post :update_owner
          get :renew
          get :cancellation
          post :cancel
          post :duplicate_outing
          get '/edit/image', action: :edit_image
          put '/update/image', action: :update_image
          put :update_neighborhoods
        end

        collection do
          get :download_list_export
          post :destroy_message
          delete :destroy_message
        end
      end

      resources :entourage_areas
      resources :entourage_invitations, only: [:index]
      resources :entourage_moderations, only: [:create]

      resources :entourage_images do
        member do
          get '/edit/landscape', action: :edit_landscape
          get '/landscape_upload_success', action: :landscape_upload_success
          get '/edit/portrait', action: :edit_portrait
          get '/portrait_upload_success', action: :portrait_upload_success
        end
      end

      resources :join_requests, only: [:create]

      resources :messages, only: [:index, :destroy]

      resources :moderation_areas do
        member do
          patch 'update_animator'
          patch 'update_sourcing'
          patch 'update_community_builder'
        end
      end

      resources :neighborhoods, only: [:index, :edit, :update, :destroy] do
        member do
          put :reactivate
          put :join
          put :unjoin
          get :show_members
          get :show_outings
          get 'outing_posts/:outing_id' => :show_outing_posts, as: :show_outing_posts
          get 'outing_post_comments/:post_id' => :show_outing_post_comments, as: :show_outing_post_comments
          get :show_posts
          get 'post_comments/:post_id' => :show_post_comments, as: :show_post_comments
          get :edit_owner
          post :update_owner
          get '/edit/image', action: :edit_image
          put '/update/image', action: :update_image
          post :read_all_messages
          post :message
          post 'outing_message/:outing_id' => :outing_message, as: :outing_message
          delete 'destroy_outing_message/:chat_message_id' => :destroy_outing_message, as: :destroy_outing_message
        end

        collection do
          post 'unread_message/:chat_message_id' => :unread_message, as: :unread_message
          delete 'destroy_message/:chat_message_id' => :destroy_message, as: :destroy_message
        end
      end

      resources :neighborhood_images do
        member do
          get '/edit/photo', action: :edit_photo
          get '/photo_upload_success', action: :photo_upload_success
        end
      end

      resources :neighborhood_message_broadcasts do
        member do
          put :update_neighborhoods
          post 'broadcast'
          post 'rebroadcast'
          post 'clone'
          post 'kill'
        end
      end

      resources :newsletter_subscriptions, only: [:index]

      resources :openai_assistants, only: [:index, :edit, :update]
      resources :openai_requests, only: [:index, :show]

      resources :options, only: [:index, :update]

      resources :outings, only: [:index] do
        collection do
          get :download_list_export
        end
      end

      resources :partners do
        collection do
          post :change_admin_role
        end
        member do
          get '/edit/logo', action: :edit_logo
          get '/logo_upload_success', action: :logo_upload_success
        end
      end

      resources :partner_registrations, only: [:index, :show, :edit, :update]

      resources :pois do
        collection do
          get :export
          post :import
        end
      end

      resources :recommandations do
        member do
          get '/edit/image', action: :edit_image
          put '/update/image', action: :update_image
        end

        collection do
          post :reorder
        end
      end

      resources :recommandation_images do
        member do
          get '/edit/photo', action: :edit_photo
          get '/photo_upload_success', action: :photo_upload_success
        end
      end

      resources :resources do
        member do
          get :edit_translation
          post :update_translation
          get '/edit/image', action: :edit_image
          put '/update/image', action: :update_image
        end
      end

      resources :resource_images do
        member do
          get '/edit/photo', action: :edit_photo
          get '/photo_upload_success', action: :photo_upload_success
        end
      end

      resources :sensitive_words, only: [:show, :destroy]

      namespace :slack do
        post :message_action
        post :offensive_text
        post :user_unblock
        get :csv
        get 'entourage_links/:id' => :entourage_links, as: :entourage_links
        get 'neighborhood_links/:id' => :neighborhood_links, as: :neighborhood_links
      end

      resources :smalltalks, only: [:index, :show] do
        member do
          get :show_members
          get :show_messages
          post :message
        end
      end

      namespace :testings, only: [] do
        resources :emails, only: [] do
          collection do
            post :weekly_planning
          end
        end

        resources :jobs, only: [] do
          collection do
            post :push_notification_trigger_job
            post :notification_job
          end
        end

        resources :notifications, only: [] do
          collection do
            post :user_smalltalk_on_almost_match
            post :user_reaction_on_create
          end
        end

        resources :salesforce, only: [] do
          collection do
            post :outing_sync
          end
        end

        resources :sms, only: [] do
          collection do
            post :send_welcome
            post :regenerate
          end
        end
      end

      resources :users, only: [:index, :show, :edit, :update, :new, :create] do
        collection do
          get :search
          get 'moderate'
          get 'download_list_export'
        end

        member do
          get 'messages'
          get 'engagement'
          get 'rpush_notifications'
          get 'neighborhoods'
          get 'outings'
          get 'history'
          get 'blocked_users'
          put 'destroy_avatar'
          get 'new_spam_warning'
          post 'create_spam_warning'

          get 'edit_block'
          put 'block'
          put 'temporary_block'
          put 'unblock'
          put 'banish'
          put 'validate'
          put 'cancel_phone_change_request'
          get 'download_export'
          get 'send_export'
          put 'anonymize'
        end
      end

      resources :user_message_broadcasts do
        member do
          post 'broadcast'
          post 'rebroadcast'
          post 'clone'
          post 'kill'
        end
      end

      resources :user_smalltalks do
        member do
          get :show_matches
          get :show_almost_matches
          post :match
          post :notify_almost_match
        end
      end

      resources :uploads, only: :new
      namespace :uploads do
        get '/success', action: :update
      end
    end
  end

  namespace :admin do
    get '/' => 'users#index'
    get 'logout' => 'sessions#logout'

    resources :sessions, only: [:new, :create]
    resources :password_resets, only: [:new, :create, :edit, :update]
  end

  #API
  namespace :api do
    namespace :v1 do
      match '(*path)' => 'base#options', via: [:options]

      resources :home, only: [:index] do
        collection do
          get :metadata
          get :summary
        end
      end

      resources :chat_messages, only: [:update, :destroy]

      resources :inapp_notifications, only: [:index, :destroy] do
        collection do
          get :count
        end
      end

      resources :notification_permissions, only: [:index, :create]

      resources :feeds, only: [:index] do
        collection do
          get :outings
        end
      end

      resources :myfeeds, only: [:index]

      resources :stats, only: [:index]
      resources :messages, only: [:create]
      resources :map, only: [:index]
      resources :contact_subscriptions, only: [:create]

      resources :newsletter_subscriptions, only: [:create] do
        collection do
          get :show
          delete :destroy
        end
      end

      resources :pois, only: [:index, :show, :create] do
        collection do
          get :clusters
        end

        member do
          post 'report'
        end
      end

      resources :users, only: [:show, :create, :destroy, :update] do
        collection do
          get :unread
          patch 'me' => 'users#update'
          post 'lookup'
          post :ethics_charter_signed
          post :request_phone_change
        end

        member do
          patch 'code'
          post :report
          get :notify
          get :notify_force
          post :presigned_avatar_upload
          post :address
          get :email_preferences, action: :update_email_preferences
          match :address_suggestion, via: [:get, :post], action: :confirm_address_suggestion
          post :following
        end

        resources :entourages, :controller => 'users/entourages', only: [:index]
        resources :neighborhoods, :controller => 'users/neighborhoods', only: [:index] do
          collection do
            get :default
          end
        end

        resources :outings, :controller => 'users/outings', only: [:index] do
          collection do
            get :past
          end
        end

        resources :actions, :controller => 'users/actions', only: [:index]

        resources :addresses, controller: 'users/addresses', only: [] do
          collection do
            post   ':position' => :create_or_update
            delete ':position' => :destroy
          end
        end
      end

      resources :user_blocked_users, only: [:index, :create, :show, :destroy] do
        collection do
          delete :destroy
        end
      end

      resources :neighborhoods do
        collection do
          get :joined # see my neighborhoods
          get :default # show default user neighborhood
        end

        member do
          get :find # either q or coordinates
          post :join # join a neighborhood
          post :leave # leave a neighborhood
          post :report # report an issue with the neighborhood
        end

        resources :chat_messages, :controller => 'neighborhoods/chat_messages', only: [:index, :show, :create, :update, :destroy] do
          post :report # report an issue with a chat_message

          member do
            get :comments
          end

          collection do
            post :presigned_upload
          end

          resources :reactions, :controller => 'neighborhoods/chat_messages/reactions', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end

            member do
              get :details
            end
          end

          resources :survey_responses, :controller => 'neighborhoods/chat_messages/survey_responses', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end
          end
        end

        resources :users, :controller => 'neighborhoods/users', only: [:index, :create, :destroy] do
          collection do
            # we want to avoid specific id to unjoin
            delete :destroy
          end
        end

        resources :outings, :controller => 'neighborhoods/outings', only: [:index, :create]
      end

      resources :resources, only: [:index, :show] do
        collection do
          get :home
          get "tag/:tag" => :tag, as: :tag
        end

        resources :users, :controller => 'resources/users', only: [:create, :destroy] do
          collection do
            # we want to avoid specific id to unjoin
            delete :destroy
          end
        end
      end

      resources :entourages, only: [:index, :show, :create, :update] do
        collection do
          get :search
          get :joined
          get :owned
          get :invited
        end
        resources :users, :controller => 'entourages/users', only: [:index, :destroy, :update, :create]
        resources :invitations, :controller => 'entourages/invitations', only: [:create]
        resources :chat_messages, :controller => 'entourages/chat_messages', only: [:index, :create]

        member do
          put :read
          get 'update', action: :one_click_update, as: :one_click_update
          post :report
          delete :report_prompt, action: :dismiss_report_prompt
        end
      end

      resources :outings do
        collection do
          get :smalltalk
        end

        member do
          put :batch_update
          get :siblings
          post :duplicate
          post :report
          post :cancel
        end

        resources :chat_messages, :controller => 'outings/chat_messages', only: [:index, :show, :create, :update, :destroy] do
          post :report # report an issue with a chat_message

          member do
            get :comments
          end

          collection do
            post :presigned_upload
          end

          resources :reactions, :controller => 'outings/chat_messages/reactions', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end

            member do
              get :details
            end
          end

          resources :survey_responses, :controller => 'outings/chat_messages/survey_responses', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end
          end
        end

        resources :users, :controller => 'outings/users', only: [:index, :create, :destroy] do
          member do
            post :confirm
            post :participate
            post :cancel_participation
            post :photo_acceptance
          end

          collection do
            post :confirm
            # we want to avoid specific id to unjoin
            delete :destroy
          end
        end
      end

      resources :actions, only: [:index]

      resources :contributions do
        member do
          post :report
        end

        collection do
          post :presigned_upload
        end
      end

      resources :solicitations do
        member do
          post :report
        end
      end

      resources :conversations do
        resources :chat_messages, :controller => 'conversations/chat_messages', only: [:index, :create, :update, :destroy] do
          member do
            get :comments
          end

          collection do
            post :presigned_upload
          end

          resources :reactions, :controller => 'conversations/chat_messages/reactions', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end

            member do
              get :details
            end
          end

          resources :survey_responses, :controller => 'conversations/chat_messages/survey_responses', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end
          end
        end

        resources :users, :controller => 'conversations/users', only: [:index, :create] do
          member do
            post :invite
          end

          collection do
            # we want to avoid specific id to unjoin
            delete :destroy
          end
        end

        member do
          post :report
        end

        collection do
          get :memberships
          get :privates
          get :private
          get :outings
          get :group
          get :metadata
        end
      end

      resources :webviews, only: [] do
        collection do
          get :url, action: :show, as: :show
        end
      end

      resources :invitations, only: [:index, :update, :destroy]

      resources :partners, only: [:index, :show] do
        collection do
          post :join_request
        end
      end

      resources :entourage_images, only: [:index, :show]
      resources :neighborhood_images, only: [:index, :show]

      resource :sharing, controller: 'sharing', only: [] do
        get :groups
      end

      resources :user_smalltalks, only: [:index, :show, :create, :update, :destroy] do
        collection do
          # these collection routes aim to define routes on in-progress user_smalltalk configuration
          get :current
          put :update
          delete :destroy

          post :match
          post :force_match
          get :matches
          get :almost_matches
          get "matches_by_criteria/:criteria" => :matches_by_criteria, as: :matches_by_criteria
        end

        member do
          post :match
          post :force_match
          get :matches
          get :almost_matches
          get "matches_by_criteria/:criteria" => :matches_by_criteria, as: :matches_by_criteria
        end
      end

      resources :smalltalks, only: [:index, :show] do
        resources :chat_messages, :controller => 'smalltalks/chat_messages', only: [:index, :create, :update, :destroy] do
          member do
            get :comments
          end

          collection do
            post :presigned_upload
          end

          resources :reactions, :controller => 'smalltalks/chat_messages/reactions', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end

            member do
              get :details
            end
          end

          resources :survey_responses, :controller => 'smalltalks/chat_messages/survey_responses', only: [:index, :create] do
            collection do
              get :users
              delete :destroy
            end
          end
        end

        resources :users, :controller => 'smalltalks/users', only: [:index] do
          collection do
            delete :destroy
          end
        end
      end

      resources :links, only: [] do
        member do
          get :redirect
          get 'mesure-impact' => :mesure_impact
        end
      end

      resources :announcements, only: [:index] do
        member do
          get :icon
          get 'redirect/:token' => :redirect, as: :redirect
        end
      end

      namespace :uptimes, only: [] do
        get :soliguides
        get :soliguide
      end

      resources :anonymous_users, only: [:create]

      put 'applications' => 'user_applications#update'
      delete 'applications' => 'user_applications#destroy'

      post 'login' => 'users#login'
      get 'check' => 'base#check'
      get 'ping' => 'base#ping'
      get 'ping_db' => 'base#ping_db'
      get 'ping_mq' => 'base#ping_mq'
      get 'ping_op_lapin' => 'base#ping_op_lapin'
      get 'organization_admin_redirect' => 'users#organization_admin_redirect'

      namespace :public do
        resources :stats, only: [:index]
        resources :entourages, only: [:index]
        match 'entourages/:uuid' => 'entourages#show', :via => :get
      end

      resources :tags, only: [] do
        collection do
          get :interests
        end
      end
    end
  end

  #ORGANIZATION_ADMIN (backoffice association)
  organization_admin_url = URI(ENV['ORGANIZATION_ADMIN_URL'] || "//#{ENV['HOST']}/organization_admin")
  organization_admin_scope = {
    host: organization_admin_url.host,
    path: organization_admin_url.path
  }.compact

  scope organization_admin_scope.merge(
    as: :organization_admin, :module => :organization_admin,
    constraints: organization_admin_scope.slice(:host)) do

    get '/' => 'base#home'
    get 'auth' => 'base#auth'
    get 'webapp_redirect' => 'base#webapp_redirect'
    resource :session, only: [:new] do
      collection do
        match :identify, via: [:post, :get]
        post :authenticate
        post :reset_password
        post :logout
      end
    end
    resources :invitations, only: [:new, :create, :index, :destroy] do
      member do
        post :resend
      end
      with_scope_level(:member) do
        scope(parent_resource.collection_scope) do
          get ':token/join', action: :join, as: :join
          post ':token/accept', action: :accept, as: :accept
        end
      end
    end
    resources :members, only: [:index, :show, :edit, :update, :destroy]
    resource :description, only: [:edit, :update] do
      member do
        get '/edit/logo', action: :edit_logo
        get '/logo_upload', action: :new_logo_upload
        get '/logo_upload_success', action: :logo_upload_success
      end
    end
    resources :entourages, only: [:edit] do
      member do
        get '/edit/image', action: :edit_image
        get '/image_upload_success', action: :image_upload_success
      end
    end
    resources :uploads, only: :new
    namespace :uploads do
      get '/success', action: :update
    end
  end

  #WEB
  resources :sessions, only: [:new, :create, :destroy] do
    collection do
      get 'switch_user' => 'admin/sessions#switch_user'
    end
  end

  resources :users, only: [:index, :edit, :create, :update, :destroy] do
    member do
      post 'send_sms'
    end
  end

  get 'apps' => 'home#apps', as: :apps
  get 'store_redirection' => 'home#store_redirection'
  get 'cgu' => 'home#cgu'
  get 'ping' => 'application#ping'
  get 'ping_db' => 'application#ping_db'

  #PUBLIC USER
  namespace :public_user do
    root to: "users#edit"

    resources :users, only: [:edit, :update]
  end

  namespace :mailjet do
    post :event
  end

  namespace :iraiser do
    post :notification
  end

  root 'home#index'
end
