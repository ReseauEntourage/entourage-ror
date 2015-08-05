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
  resources :users, only: [:index, :create, :update, :destroy] do
    post 'send_message', on: :collection
    post 'send_sms', on: :member
  end

  post 'login' => 'users#login'
  get 'map' => 'map#index'

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

end
