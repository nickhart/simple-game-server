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

    resources :sessions, only: %i[create destroy] do
      post :refresh, on: :collection
    end

    # Player profile
    resources :players, only: %i[create show] do
      get :me, on: :collection
    end

    # Public games
    resources :games, only: %i[index show], param: :name do
      resources :sessions, controller: "games/sessions", only: %i[index show create] do
        member do
          post :join
          post :start
          post :move
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

      resources :games, only: %i[create update destroy], param: :name do
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
