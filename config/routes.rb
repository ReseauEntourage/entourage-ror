Rails.application.routes.draw do

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get 'map' => 'map#index'
  post 'login' => 'users#login'
  resources :pois, only: [:index]
  resources :encounters, only: [:create]

end
