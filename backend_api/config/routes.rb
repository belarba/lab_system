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
        post :add_patient
        get 'export/patient/:patient_id', to: 'doctors#export_patient_results', as: :export_patient_results
        get 'export/all', to: 'doctors#export_all_results', as: :export_all_results
      end
      collection do
        get :search_patients
        get :all_patients
      end
    end

    # Pacientes
    resources :patients, only: [] do
      member do
        get '/', to: 'patients#show'
        get :blood_work_requests
        get :test_results
      end
    end

    # Requisições de exames (para médicos)
    resources :blood_work_requests, only: [:create, :index] do
      member do
        post :cancel
      end
    end

    # Requisições de pacientes (self-service)
    scope :patient do
      resources :requests, controller: 'patient_requests', only: [:create] do
        collection do
          get :my_requests
        end
        member do
          post :cancel
        end
      end
    end

    # Lab File Uploads
    resources :uploads, only: [:index, :create, :show]

    # Admin namespace - seguindo convenções REST
    namespace :admin do
      resources :users
      resources :exam_types
      resources :stats, only: [:index]
      resources :roles, only: [:index]
    end

    # Public exam types endpoint (for patients to see available types)
    resources :exam_types, only: [:index, :show]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
