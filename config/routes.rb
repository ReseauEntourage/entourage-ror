Rails.application.routes.draw do

  root 'home#tours_map'
  get 'latest_tours' => 'home#latest_tours'

  resources :tours, only: [:index,:create,:show,:update] do
    resources :tour_points, only:[:create]
    resources :encounters, only: [:create]
  end
  resources :newsletter_subscriptions
  resources :pois, only: [:index]
  resources :encounters, only: [:create]
  resources :users, only: [:index, :create, :update, :destroy]

  post 'login' => 'users#login'
  post 'users/send_message' => 'users#send_message'

  get 'map' => 'map#index'

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

end
