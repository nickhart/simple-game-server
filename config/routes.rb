Rails.application.routes.draw do
  devise_for :users

  # Public root path for web (optional)
  root "game_sessions#index"

  # Web views for registration
  resources :users, only: %i[new create]
  resources :players, only: %i[new create]

  # Public API
  namespace :api do
    # Auth routes
    resources :users, only: %i[create show update destroy]
    get "users/me", to: "users#me"

    # Token-based authentication routes
    post   "tokens/login",   to: "tokens#create"
    post   "tokens/refresh", to: "tokens#refresh"
    delete "tokens/logout",  to: "tokens#destroy"

    # Player profile
    resources :players, only: %i[create show] do
      get :me, on: :collection
    end

    # Public games
    resources :games, only: %i[index show] do
      resources :sessions, controller: "games/sessions", only: %i[index show create update] do
        member do
          post :join
          post :start
          delete :leave
        end
      end
    end

    # Admin namespace
    namespace :admin do
      resources :users, only: %i[index show update create] do
        member do
          post :make_admin
          post :remove_admin
        end
      end

      resources :games, only: %i[create update destroy] do
        post :schema, on: :member
      end

      resources :game_sessions, only: %i[destroy] do
        collection do
          post :cleanup
        end
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
