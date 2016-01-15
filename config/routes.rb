Rails.application.routes.draw do

  root 'organizations#dashboard'

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
      resources :newsletter_subscriptions

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
      resources :feeds, only: [:index]
      resources :tours, only: [:index,:create,:show,:update] do
        resources :tour_points, only:[:create]
        resources :encounters, only: [:create]
      end
      resources :stats, only: [:index]
      resources :messages, only: [:create]
      resources :registration_requests, only: [:create]
      resources :map, only: [:index]
      resources :newsletter_subscriptions
      resources :applications, only: [:create]

      resources :pois, only: [:index, :create] do
        member do
          post 'report'
        end
      end

      resources :users, only: [:show] do
        collection do
          patch 'update'
        end

        member do
          patch 'code'
        end

        resources :tours, :controller => 'users/tours', only: [:index]
      end

      resources :entourages, only: [:index, :show, :create, :update] do
        resources :users, :controller => 'entourages/users', only: [:index, :destroy, :update, :create]
      end
      resources :contacts, only: [:update]

      post 'login' => 'users#login'
      get 'check' => 'base#check'
    end
  end

  #WEB
  resources :sessions, only: [:new, :create, :destroy]
  resources :organizations, only: [:new, :create, :edit, :update] do
    collection do
      get 'dashboard'
      get 'statistics'
      get 'tours'
      get 'snap_tours'
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
  resources :tours, only: [:show] do
    member do
      get :map_center
      get :map_data
    end
  end
  resources :registration_requests, only: [:index, :show, :update, :destroy]
  resources :scheduled_pushes, only: [:index] do
    collection do
      delete :destroy
    end
  end

  get 'apps' => 'home#apps', as: :apps
  get 'store_redirection' => 'home#store_redirection'
  get 'cgu' => 'home#cgu'

  #ADMIN
  namespace :admin do
    get 'logout' => 'sessions#logout'
    post 'generate_tour' => 'generate_tour#generate'

    resources :sessions, only: [:none] do
      collection do
        get 'switch_user'
      end
    end
  end
  ActiveAdmin.routes(self)

end
