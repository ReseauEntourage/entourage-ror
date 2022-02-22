require 'sidekiq/web'
require 'super_admin_constraint'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/super_admin/sidekiq', :constraints => SuperAdminConstraint.new

  #ADMIN
  constraints :subdomain => /\A(admin|admin-preprod)\z/ do
    scope :module => "admin", :as => "admin" do
      get '/' => 'base#home'
      get 'logout' => 'sessions#logout'
      get '/sessions/new', to: redirect('/admin/sessions/new')

      resources :generate_tours, only: [:index, :create]

      resources :users, only: [:index, :show, :edit, :update, :new, :create] do
        collection do
          get 'moderate'
          get 'fake'
          post 'generate'
          get 'download_list_export'
        end

        member do
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
          post 'experimental_pending_request_reminder'
        end
      end

      resources :pois
      resources :entourage_images do
        member do
          get '/edit/landscape', action: :edit_landscape
          get '/landscape_upload_success', action: :landscape_upload_success
          get '/edit/portrait', action: :edit_portrait
          get '/portrait_upload_success', action: :portrait_upload_success
        end
      end
      resources :registration_requests, only: [:index, :show, :update, :destroy]
      resources :messages, only: [:index, :destroy]
      resources :organizations, only: [:show, :index, :edit, :update]
      resources :partners, except: [:create, :update] do
        collection do
          post '/new', action: :create, as: nil
          post :change_admin_role
        end
        member do
          match '/edit', via: [:patch, :put], action: :update, as: nil
          get '/edit/logo', action: :edit_logo
          get '/logo_upload_success', action: :logo_upload_success
        end
      end

      resources :options, only: [:index, :update]

      resources :partner_registrations, only: [:index, :show, :edit, :update]

      resources :moderation_areas
      resources :tour_areas

      resources :uploads, only: :new
      namespace :uploads do
        get '/success', action: :update
      end


      namespace :super_admin do
        get '/announcements_images', action: :announcements_images
        get '/entourage_images', action: :entourage_images
        get '/outings_images', action: :outings_images
        get '/soliguide', action: :soliguide
        get '/soliguide_show/:id' => :soliguide_show, as: :soliguide_show
        # sidekiq: /super_admin/sidekiq defined previously
        get '/jobs_crons', action: :jobs_crons
        post '/force_close_tours', action: :force_close_tours
        post '/unread_reminder_email', action: :unread_reminder_email
        post '/onboarding_sequence_send_welcome_messages', action: :onboarding_sequence_send_welcome_messages
      end

      resources :newsletter_subscriptions, only: [:index]
      resources :entourage_invitations, only: [:index]
      resources :entourages, only: [:index, :show, :new, :create, :edit, :update] do
        member do
          post :moderator_read
          post :moderator_unread
          post :message
          get :show_members
          get :show_joins
          get :show_invitations
          get :show_messages
          get :sensitive_words
          post :sensitive_words_check
          get :edit_type
          get :edit_owner
          post :close
          post :update_owner
          post :pin
          post :unpin
          post :admin_pin
          post :admin_unpin
          get :renew
          get :cancellation
          post :cancel
          get '/edit/image', action: :edit_image
          put '/update/image', action: :update_image
        end
        collection do
          post :destroy_message
        end
      end
      resources :entourage_moderations, only: [:create]
      resources :sensitive_words, only: [:show, :destroy]
      resources :conversations, only: [:index, :show] do
        member do
          post :message
          post :read_status
          post :archive_status
        end
      end

      resources :join_requests, only: [:create]

      resources :digest_emails, only: [:index, :show, :edit, :update] do
        member do
          post :send_test
        end
      end

      resources :announcements, only: [:index, :new, :edit] do
        collection do
          post '/new', action: :create, as: nil
          post :reorder
        end
        member do
          match '/edit', via: [:patch, :put], action: :update, as: nil
          get '/edit/image', action: :edit_image
          get '/image_upload_success', action: :image_upload_success
          get '/edit/image_portrait', action: :edit_image_portrait
          get '/image_portrait_upload_success', action: :image_portrait_upload_success
        end
      end

      get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
      delete 'user_relationships' => "user_relationships#destroy"
    end
  end

  namespace :admin do
    get '/' => 'users#index'
    get 'logout' => 'sessions#logout'

    resources :sessions, only: [:new, :create]

    resources :password_resets, only: [:new, :create, :edit, :update]

    resources :generate_tours, only: [:index, :create]

    resources :users, only: [:index, :edit, :update, :new, :create] do
      collection do
        get 'moderate'
        get 'fake'
        post 'generate'
      end

      member do
        get 'messages'
        get 'engagement'
        get 'history'
        put 'destroy_avatar'
        put 'banish'
        put 'validate'
        get 'new_spam_warning'
        post 'create_spam_warning'
      end
    end

    resources :pois
    resources :registration_requests, only: [:index, :show, :update, :destroy]
    resources :messages, only: [:index, :destroy]
    resources :organizations, only: [:index, :edit, :update]
    resources :newsletter_subscriptions, only: [:index]
    resources :entourage_invitations, only: [:index]
    resources :entourages, only: [:index, :show, :edit, :update]
    resources :join_requests, only: [:create]
    resources :conversation_message_broadcasts do
      member do
        post 'broadcast'
        post 'clone'
        post 'kill'
      end
    end

    get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
    delete 'user_relationships' => "user_relationships#destroy"

    namespace :slack do
      post :message_action
      post :user_unblock
      get :csv
      get 'entourage_links/:id' => :entourage_links, as: :entourage_links
    end
  end

  #API
  namespace :api do
    namespace :v1 do
      match '(*path)' => 'base#options', via: [:options]
      resources :home, only: [:index]

      resources :feeds, only: [:index] do
        collection do
          get :outings
        end
      end

      resources :myfeeds, only: [:index]
      resources :tours, only: [:index, :create, :show, :update] do
        resources :tour_points, only:[:create]
        resources :encounters, only: [:index, :create, :update], :shallow => true
        resources :users, :controller => 'tours/users', only: [:index, :destroy, :update, :create]
        resources :chat_messages, :controller => 'tours/chat_messages', only: [:index, :create]

        member do
          put :read
        end
      end

      resources :stats, only: [:index]
      resources :messages, only: [:create]
      resources :registration_requests, only: [:create]
      resources :map, only: [:index]
      resources :newsletter_subscriptions, only: [:create]
      resources :questions, only: [:index]

      resources :tour_areas, only: [:index, :show] do
        member do
          post :request, action: :tour_request
        end
      end

      resources :pois, only: [:index, :show, :create] do
        member do
          post 'report'
        end
      end

      resources :users, only: [:show, :create, :destroy, :update] do
        collection do
          patch 'me' => 'users#update'
          post 'lookup'
          post :ethics_charter_signed
          post :request_phone_change
        end

        member do
          patch 'code'
          post :report
          post :presigned_avatar_upload
          post :address
          get :email_preferences, action: :update_email_preferences
          match :address_suggestion, via: [:get, :post], action: :confirm_address_suggestion
          post :following
        end

        resources :tours, :controller => 'users/tours', only: [:index]
        resources :entourages, :controller => 'users/entourages', only: [:index]

        resources :addresses, controller: 'users/addresses', only: [] do
          collection do
            post   ':position' => :create_or_update
            delete ':position' => :destroy
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

      resources :conversations, :controller => 'entourages', only: [] do
        collection do
          get :private
          get :group
          get :lists
        end
      end

      resources :invitations, only: [:index, :update, :destroy]

      resources :partners, only: [:index, :show] do
        collection do
          post :join_request
        end
      end

      resources :entourage_images, only: [:index, :show]

      resource :sharing, controller: 'sharing', only: [] do
        get :groups
      end

      resources :links, only: [] do
        member do
          get :redirect
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
      get 'organization_admin_redirect' => 'users#organization_admin_redirect'

      namespace :public do
        resources :stats, only: [:index]
        resources :entourages, only: [:index]
        match 'entourages/:uuid' => 'entourages#show', :via => :get
      end
    end
  end

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

  good_waves_url = URI(ENV['GOOD_WAVES_URL'] || "//#{ENV['HOST']}/good_waves")
  good_waves_scope = {
    host: good_waves_url.host,
    path: good_waves_url.path
  }.compact

  scope good_waves_scope.merge(
    as: :good_waves, :module => :good_waves,
    constraints: good_waves_scope.slice(:host)) do

    get '/' => 'base#home'
    get '/onboarding' => 'base#onboarding'
    post '/onboarding' => 'base#update_profile'
    get '/invitation/:id' => 'invitations#show', as: :invitation

    resources :groups, only: [:index, :new, :create, :show] do
      collection do
        post :parse_members
      end
      member do
        get :invitation, action: :new_invitation
        post :invitation, action: :create_invitation
        post :remove_member
        post :cancel_invitation
      end
    end

    resource :session, only: [:new] do
      collection do
        match :identify, via: [:post, :get]
        post :authenticate
        post :reset_password
        post :logout
      end
    end
  end

  #WEB
  resources :sessions, only: [:new, :create, :destroy] do
    collection do
      get 'switch_user' => 'admin/sessions#switch_user'
    end
  end
  resources :organizations, only: [:new, :create, :edit, :update] do
    collection do
      get 'dashboard'
      get 'statistics'
      get 'tours'
      get 'simplified_tours'
      get 'encounters'
      get 'map_center'
      post 'send_message'
    end
  end
  resources :users, only: [:index, :edit, :create, :update, :destroy] do
    member do
      post 'send_sms'
    end
  end
  resources :tours, only: [:show, :destroy] do
    member do
      get :map_center
      get :map_data
    end
  end

  resources :scheduled_pushes, only: [:index] do
    collection do
      delete :destroy
    end
  end

  resources :questions, only: [:create, :destroy]

  get 'apps' => 'home#apps', as: :apps
  get 'store_redirection' => 'home#store_redirection'
  get 'cgu' => 'home#cgu'
  get 'ping' => 'application#ping'

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
