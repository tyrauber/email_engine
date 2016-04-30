Rails.application.routes.draw do
  unless respond_to?(:has_named_route?) && has_named_route?("email_engine")
     mount EmailEngine::Engine => "/email", as: 'email_engine'
  end
end

EmailEngine::Engine.routes.draw do
    resources :admin, only:[ :index, :show, :stats, :sent, :open, :click, :bounce, :complaint] do
      get :stats, on: :collection
      get ':type', on: :collection, action: 'index', :constraints => {:type => /sent|open|click|bounce|complaint/i }
    end
    resources :messages, only: [] do
      get :open, on: :member
      get :click, on: :member
      get :unsubscribe, on: :member
    end
end
