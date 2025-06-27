Rails.application.routes.draw do
  namespace :api do
    # Autenticação
    scope :auth do
      post :login, to: 'auth#login'
      post :refresh, to: 'auth#refresh'
      post :logout, to: 'auth#logout'
    end

    # Perfil do usuário
    scope :users do
      get :me, to: 'users#me'
      put :me, to: 'users#update_me'
    end

    # Médicos e seus pacientes
    resources :doctors, only: [] do
      member do
        get :patients
        get :blood_work_requests
      end
    end

    # Pacientes
    resources :patients, only: [:show] do
      member do
        get :blood_work_requests
        get :test_results
      end
    end

    # Requisições de exames
    resources :blood_work_requests, only: [:create, :index] do
      member do
        post :cancel
      end
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
