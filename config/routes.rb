Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  get "login" => "sessions#new", as: :login

  resource :session, only: %i[create destroy] do
    post :nonce
  end

  ActiveAdmin.routes(self)

  resources :communities do
    resources :threads, controller: :threads, shallow: true
    resources :members, controller: :community_members, only: %i[index create destroy] do
      member do
        post :ban
        post :unban
      end
    end
  end

  resources :threads, only: [] do
    resources :posts, shallow: true do
      resources :reports, only: %i[new create]
    end
  end

  resources :comments do
    resources :reports, only: %i[new create]
  end

  resources :reports, only: %i[index update]

  resources :images, only: [:create]

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public entry point. Signed-in members are sent straight to their communities.
  root "landing#index"
end
