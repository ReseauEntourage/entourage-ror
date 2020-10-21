Rails.application.routes.draw do

  #ADMIN
  constraints :subdomain => /\A(admin|admin-preprod)\z/ do
    scope :module => "admin", :as => "admin" do
      get '/' => 'base#home'
      get 'logout' => 'sessions#logout'

      resources :generate_tours, only: [:index, :create]

      resources :users, only: [:index, :show, :edit, :update, :new, :create] do
        collection do
          get 'moderate'
          get 'fake'
          post 'generate'
        end

        member do
          put 'block'
          put 'unblock'
          put 'banish'
          put 'validate'
          post 'experimental_pending_request_reminder'
        end
      end

      resources :pois
      resources :registration_requests, only: [:index, :show, :update, :destroy]
      resources :messages, only: [:index, :destroy]
      resources :organizations, only: [:index, :edit, :update]
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
      resources :moderation_areas, only: [:index, :edit] do
        member do
          match '/edit', via: [:patch, :put], action: :update, as: nil
        end
      end

      resources :uploads, only: :new
      namespace :uploads do
        get '/success', to: :update
      end

      resources :newsletter_subscriptions, only: [:index]
      resources :entourage_invitations, only: [:index]
      resources :entourages, only: [:index, :show, :edit, :update] do
        member do
          post :moderator_read
          post :moderator_unread
          post :message
          get :sensitive_words
          post :sensitive_words_check
          get :edit_type
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
        end
      end

      get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
      get 'user_search' => "users_search#user_search"
      delete 'user_relationships' => "user_relationships#destroy"
    end
  end

  namespace :admin do
    get '/' => 'users#index'
    get 'logout' => 'sessions#logout'

    resources :generate_tours, only: [:index, :create]

    resources :users, only: [:index, :edit, :update, :new, :create] do
      collection do
        get 'moderate'
        get 'fake'
        post 'generate'
      end

      member do
        get 'messages'
        put 'banish'
        put 'validate'
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

    get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
    get 'user_search' => "users_search#user_search"
    delete 'user_relationships' => "user_relationships#destroy"

    namespace :slack do
      post :message_action
      get 'entourage_links/:id' => :entourage_links, as: :entourage_links
    end
  end

  #API
  namespace :api do
    namespace :v0 do
      match '(*path)', to: "base#deprecated", via: :all
    end

    namespace :v1 do
      match '(*path)' => 'base#options', via: [:options]
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

        collection do
          delete 'delete_all' => 'tours#delete_all'
        end

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

      resources :pois, only: [:index, :show, :create] do
        collection do
          get :soliguide_test
        end
        member do
          post 'report'
        end
      end

      resources :users, only: [:show, :create, :destroy, :update] do
        collection do
          patch 'me' => 'users#update'
          post 'lookup'
          post :ethics_charter_signed
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
        # resources :partners, :controller => 'users/partners'

        resources :addresses, controller: 'users/addresses', only: [] do
          collection do
            post   ':position' => :create_or_update
            delete ':position' => :destroy
          end
        end
      end

      resources :entourages, only: [:index, :show, :create, :update] do
        resources :users, :controller => 'entourages/users', only: [:index, :destroy, :update, :create]
        resources :invitations, :controller => 'entourages/invitations', only: [:create]
        resources :chat_messages, :controller => 'entourages/chat_messages', only: [:index, :create]

        member do
          put :read
          get 'update', action: :one_click_update, as: :one_click_update
          post :report
        end
      end
      resources :invitations, only: [:index, :update, :destroy]
      # resources :contacts, only: [:update]
      resources :partners, only: [:index, :show] do
        collection do
          post :join_request
        end
      end

      resource :sharing, controller: 'sharing', only: [] do
        get :groups
      end

      resources :links, only: [] do
        member do
          get :redirect
        end
      end

      resources :announcements, only: [] do
        member do
          get :icon
          get 'redirect/:token' => :redirect, as: :redirect
        end
      end

      resources :anonymous_users, only: [:create]

      put 'applications' => 'user_applications#update'
      delete 'applications' => 'user_applications#destroy'

      post 'login' => 'users#login'
      get 'check' => 'base#check'
      get 'ping' => 'base#ping'
      # get 'csv_matching' => 'csv_matching#show'
      get 'organization_admin_redirect' => 'users#organization_admin_redirect'

      namespace :public do
        resources :stats, only: [:index]
        resources :entourages, only: [:index]
        match 'entourages/:uuid' => 'entourages#show', :via => :get
      end
    end
  end

  community_admin_url = URI(ENV['COMMUNITY_ADMIN_URL'] || "//#{ENV['HOST']}/community_admin")
  community_admin_scope = {
    host: community_admin_url.host,
    path: community_admin_url.path
  }.compact

  scope community_admin_scope.merge(
    as: :community_admin, :module => :community_admin,
    constraints: community_admin_scope.slice(:host)) do

    get '/' => 'base#root'
    resources :sessions, only: [:new, :create] do
      collection do
        post :logout, action: :destroy
      end
    end
    namespace :dashboard do
      get '', action: :index, as: ''
    end
    resources :users, only: [:index, :show, :edit, :update, :new, :create] do
      post :group_role, action: :update_group_role
      post :groups, action: :add_to_group
      delete :groups, action: :remove_from_group
      collection do
        get :archived
      end
      member do
        post :archive, action: :archive
        post :unarchive, action: :unarchive
      end
    end
    resources :neighborhoods, only: [:index, :show, :edit, :update, :new, :create]
    resources :private_circles, only: [:index, :show, :edit, :update, :new, :create]
  end

  organization_admin_url = URI(ENV['ORGANIZATION_ADMIN_URL'] || "//#{ENV['HOST']}/organization_admin")
  organization_admin_scope = {
    host: organization_admin_url.host,
    path: organization_admin_url.path
  }.compact

  scope organization_admin_scope.merge(
    as: :organization_admin, :module => :organization_admin,
    constraints: community_admin_scope.slice(:host)) do

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
  get 'redirect/:signature/*url' => 'redirection#redirect', format: false, as: :escaped_redirect

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
