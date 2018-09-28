Rails.application.routes.draw do

  #ADMIN
  constraints :subdomain => /\A(admin|admin-preprod)\z/ do
    scope :module => "admin", :as => "admin" do
      get '/' => 'users#index'
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
      resources :newsletter_subscriptions, only: [:index]
      resources :ambassadors, only: [:index, :edit, :update, :new, :create]
      resources :entourage_invitations, only: [:index]
      resources :entourages, only: [:index, :show, :edit, :update] do
        member do
          post :moderator_read
          post :moderator_unread
          post :message
          get :sensitive_words
          post :sensitive_words_check
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
        end
      end

      resources :marketing_referers, only: [:index, :edit, :update, :new, :create]
      resources :join_requests, only: [:create]

      get 'public_user_search' => "users_search#public_user_search"
      get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
      get 'pro_user_search' => "users_search#pro_user_search"
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
    resources :ambassadors, only: [:index, :edit, :update, :new, :create]
    resources :entourage_invitations, only: [:index]
    resources :entourages, only: [:index, :show, :edit, :update]
    resources :marketing_referers, only: [:index, :edit, :update, :new, :create]
    resources :join_requests, only: [:create]

    get 'public_user_search' => "users_search#public_user_search"
    get 'public_user_autocomplete' => "users_search#public_user_autocomplete"
    get 'pro_user_search' => "users_search#pro_user_search"
    delete 'user_relationships' => "user_relationships#destroy"

    namespace :slack do
      post :message_action
      get 'entourage_links/:id' => :entourage_links, as: :entourage_links
    end
  end

  #API
  namespace :api do
    namespace :v0 do
      resources :tours, only: [:index,:create,:show,:update] do
        resources :tour_points, only:[:create]
        resources :encounters, only: [:create]
      end
      resources :stats, only: [:index]
      resources :messages, only: [:create]
      resources :registration_requests, only: [:create]
      resources :map, only: [:index]
      resources :newsletter_subscriptions, only: [:create]

      resources :pois, only: [:index, :create] do
        member do
          post 'report'
        end
      end

      resources :users, only: [:none] do
        collection do
          patch 'update_me'
        end

        member do
          patch 'code'
        end

        resources :tours, :controller => 'users/tours', only: [:index]
      end

      post 'login' => 'users#login'
      get 'check' => 'base#check'
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
      resources :newsletter_subscriptions
      resources :questions, only: [:index]

      resources :pois, only: [:index, :create] do
        member do
          post 'report'
        end
      end

      resources :users, only: [:show, :create, :destroy, :update] do
        collection do
          patch 'me' => 'users#update'
          post 'lookup'
        end

        member do
          patch 'code'
          post :report
          post :presigned_avatar_upload
          post :address
        end

        resources :tours, :controller => 'users/tours', only: [:index]
        resources :entourages, :controller => 'users/entourages', only: [:index]
        resources :authentication_providers, only: [:create]
        resources :partners, :controller => 'users/partners'
      end

      resources :entourages, only: [:index, :show, :create, :update] do
        resources :users, :controller => 'entourages/users', only: [:index, :destroy, :update, :create]
        resources :invitations, :controller => 'entourages/invitations', only: [:create]
        resources :chat_messages, :controller => 'entourages/chat_messages', only: [:index, :create]

        member do
          put :read
          get 'update', action: :one_click_update, as: :one_click_update
        end
      end
      resources :invitations, only: [:index, :update, :destroy]
      resources :contacts, only: [:update]
      resources :partners, only: [:index]

      resources :links, only: [] do
        member do
          get :redirect
        end
      end

      resources :announcements, only: [] do
        member do
          get :icon
          get :avatar
          get 'redirect/:token' => :redirect, as: :redirect
        end
      end

      resources :action_zones, only: [] do
        collection do
          get :confirm
        end
      end

      put 'applications' => 'user_applications#update'
      post 'login' => 'users#login'
      get 'check' => 'base#check'
      get 'ping' => 'base#ping'
      get 'csv_matching' => 'csv_matching#show'

      namespace :public do
        resources :stats, only: [:index]
        resources :entourages, only: [:index]
        match 'entourages/:uuid' => 'entourages#show', :via => :get
      end
    end
  end

  community_admin_url = URI(ENV['COMMUNITY_ADMIN_URL'] || 'community_admin')
  community_admin_scope = {
    host: community_admin_url.host,
    path: community_admin_url.path
  }.compact

  scope community_admin_scope.merge(
        as: :community_admin, :module => :community_admin) do
    get '/' => 'base#root'
    resources :sessions, only: [:new, :create] do
      collection do
        post :logout, action: :destroy
      end
    end
    resources :users, only: [:index, :show, :edit, :update, :new, :create] do
      post :group_role, action: :update_group_role
      post :groups, action: :add_to_group
      delete :groups, action: :remove_from_group
    end
    resources :neighborhoods, only: [:index, :show, :edit, :update, :new, :create]
    resources :private_circles, only: [:index, :show, :edit, :update, :new, :create]
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

  root 'home#index'
end
