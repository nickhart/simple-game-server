Rails.application.routes.draw do
  devise_for :users
  root "game_sessions#index"

  # Web player registration
  resources :users, only: %i[new create]
  resources :players, only: %i[new create]

  resources :game_sessions do
    member do
      post :join
    end
  end

  # Add cleanup endpoint
  post "game_sessions/cleanup", to: "game_sessions#cleanup"

  # API routes
  namespace :api do
    devise_for :users, controllers: {
      sessions: 'api/users/sessions',
      registrations: 'api/users/registrations'
    }

    resources :players, param: :id

    resources :game_sessions do
      collection do
        post 'create/:player_id', to: 'game_sessions#create'
      end
      
      member do
        post 'join/:player_id', to: 'game_sessions#join'
        delete 'leave/:player_id', to: 'game_sessions#leave'
        post 'start'
        post 'update_game_state'
      end
      
      post "cleanup", on: :collection
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
