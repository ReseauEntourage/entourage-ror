Rails.application.routes.draw do

  resources :tours, only: [:index,:create,:show] do
    resources :tour_points, only:[:create]
  end

  resources :newsletter_subscriptions

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get 'map' => 'map#index'
  post 'login' => 'users#login'
  resources :pois, only: [:index]
  resources :encounters, only: [:create]

end
