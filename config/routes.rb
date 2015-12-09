Rails.application.routes.draw do

  root 'home#index'

  namespace :api do
    namespace :v0 do
      resources :tours, only: [:index,:create,:show,:update] do
        resources :tour_points, only:[:create]
        resources :encounters, only: [:create]
      end
    end
  end


  get 'apps' => 'home#apps', as: :apps

  resources :sessions, only: [:new, :create, :destroy]

  resources :newsletter_subscriptions
  resources :pois, only: [:index, :create] do
    post 'report', on: :member
  end
  resources :encounters, only: [:create]
  resources :users, only: [:index, :create, :update, :destroy] do
    post 'send_message', on: :collection
    post 'send_sms', on: :member
    patch 'update_me', on: :collection
  end
  get 'organization/dashboard' => 'organization#dashboard', as: :organization_dashboard
  get 'organization/edit' => 'organization#edit', as: :organization_edit
  patch 'organization' => 'organization#update', as: :organization
  get 'organization/tours' => 'organization#tours'
  get 'organization/encounters' => 'organization#encounters'
  get 'organization/map_center' => 'organization#map_center'
  post 'organization/send_message' => 'organization#send_message'
  
  namespace :organization do
    resources :users do
      post 'send_sms', on: :member
    end
  end

  post 'login' => 'users#login'
  get 'map' => 'map#index'

  resources :stats, only: [:index]
  resources :messages, only: [:create]
  resources :registration_requests, except: [:edit]

  #ADMIN
  namespace :admin do
    get 'logout' => 'sessions#logout'
    post 'generate_tour' => 'generate_tour#generate'
  end
  ActiveAdmin.routes(self)
end
