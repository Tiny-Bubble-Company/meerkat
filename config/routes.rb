Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  constraints(OpsHostConstraint) do
    scope module: :ops, as: :ops do
      root "dashboard#index"
      get "login", to: "sessions#new"
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"

      resources :users, only: %i[index show]
      resources :tasks, only: %i[index show]
      resources :task_runs, only: %i[index show], path: "runs"
      resources :webhook_deliveries, only: %i[index show], path: "webhooks"
    end
  end

  root "pages#home"

  get "use-cases/package-tracking", to: "use_cases#show", defaults: { slug: "package-tracking" }, as: :package_tracking
  get "use-cases/website-monitoring", to: "use_cases#show", defaults: { slug: "website-monitoring" }, as: :website_monitoring
  get "use-cases/agent-webhooks", to: "use_cases#show", defaults: { slug: "agent-webhooks" }, as: :agent_webhooks

  get "signup", to: "signup#new"
  post "signup", to: "signup#create"
  delete "logout", to: "signup#destroy"

  get "onboarding/run-status", to: "onboarding#run_status", as: :onboarding_run_status
  post "onboarding/process-run", to: "onboarding#process_run", as: :onboarding_process_run
  post "onboarding/acknowledge-key", to: "onboarding#acknowledge_key", as: :onboarding_acknowledge_key
  post "onboarding/llm-provider", to: "onboarding#save_llm_provider", as: :onboarding_save_llm_provider
  post "onboarding/create-task", to: "onboarding#create_task", as: :onboarding_create_task
  post "onboarding/run-task", to: "onboarding#run_task", as: :onboarding_run_task
  post "onboarding/complete", to: "onboarding#complete", as: :onboarding_complete
  get "onboarding/:step", to: "onboarding#show", as: :onboarding_step, constraints: { step: /api-key|llm-provider|create-task|run-task|waiting|success/ }
  get "onboarding", to: redirect("/onboarding/api-key")

  get "docs", to: "docs#show", as: :docs
  get "docs/:section", to: "docs#show", as: :docs_section
  post "docs/api-keys", to: "docs/api_keys#create", as: :docs_api_keys
  delete "docs/api-keys/:id", to: "docs/api_keys#destroy", as: :docs_api_key
  post "docs/llm-provider", to: "docs/llm_providers#update", as: :docs_llm_provider

  namespace :api do
    namespace :v1 do
      post "signup", to: "signup#create"
      resources :api_keys, only: [:index, :create, :destroy]

      get "openapi", to: "openapi#show", defaults: { format: :yaml }

      resources :tasks, only: [:index, :show, :create, :update, :destroy] do
        member do
          post :run
          post :pause
          post :resume
          get :runs
          get :events
        end
      end
    end
  end
end
