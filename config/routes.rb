Rails.application.routes.draw do

  resources :tours, only: [:index,:create,:show] do
    resources :tour_points, only:[:create]
    resources :encounters, only: [:create]
  end
  resources :newsletter_subscriptions
  resources :pois, only: [:index]
  resources :encounters, only: [:create]
  resources :users, only: [:index, :create, :update, :destroy]

  post 'login' => 'users#login'

  get 'map' => 'map#index'

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

end
