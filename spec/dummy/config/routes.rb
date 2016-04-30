Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  root to: "welcome#index"
end