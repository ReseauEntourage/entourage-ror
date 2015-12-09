Rails.application.routes.draw do

  root 'organization#dashboard'

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

      resources :users, only: [:index, :create, :update, :destroy] do
        collection do
          post 'login'
          post 'send_message'
          patch 'update_me'
        end

        member do
          post 'send_sms'
        end
      end
    end
  end

  #WEB
  resources :registration_requests, only: [:index, :show, :update, :destroy]
  resources :sessions, only: [:new, :create, :destroy]
  resources :organizations, only: [:edit, :update] do
    collection do
      get 'dashboard'
      get 'tours'
      get 'encounters'
      get 'map_center'
      post 'send_message'
    end
  end
  get 'apps' => 'home#apps', as: :apps

  # get 'organization/dashboard' => 'organization#dashboard', as: :organization_dashboard
  # get 'organization/edit' => 'organization#edit', as: :organization_edit
  # patch 'organization' => 'organization#update', as: :organization
  # get 'organization/tours' => 'organization#tours'
  # get 'organization/encounters' => 'organization#encounters'
  # get 'organization/map_center' => 'organization#map_center'
  # post 'organization/send_message' => 'organization#send_message'


  #ADMIN
  namespace :admin do
    get 'logout' => 'sessions#logout'
    post 'generate_tour' => 'generate_tour#generate'
  end
  ActiveAdmin.routes(self)

  
  namespace :organization do
    resources :users do
      post 'send_sms', on: :member
    end
  end



end
