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
      end

      post 'login' => 'users#login'
    end
  end

  #WEB
  resources :registration_requests, only: [:index, :show, :update, :destroy]
  resources :sessions, only: [:new, :create, :destroy]
  resources :organizations, only: [:edit, :update] do
    collection do
      get 'dashboard'
      get 'statistics'
      get 'tours'
      get 'encounters'
      get 'map_center'
      post 'send_message'
      get 'export_dashboard'
    end
  end
  resources :users, only: [:index, :edit, :create, :update, :destroy] do
    member do
      post 'send_sms'
    end
  end

  get 'apps' => 'home#apps', as: :apps


  #ADMIN
  namespace :admin do
    get 'logout' => 'sessions#logout'
    post 'generate_tour' => 'generate_tour#generate'
  end
  ActiveAdmin.routes(self)

end
