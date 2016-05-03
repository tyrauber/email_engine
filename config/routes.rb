Rails.application.routes.draw do
  unless respond_to?(:has_named_route?) && has_named_route?("email_engine")
     mount EmailEngine::Engine => "/", as: 'email_engine'
  end
end
EmailEngine::Engine.routes.draw do
  resources :emails, only:[:stats, :sent, :open, :click, :bounce, :complaint] do
    get :open, on: :member
    get :click, on: :member
    get :unsubscribe, on: :member
  end
  scope :admin do
    resources :emails, only:[ :index, :show, :stats] do
      get :stats, on: :collection
      get ':type', on: :collection, action: 'index', :constraints => {:type => /sent|open|click|bounce|complaint/i }
    end
  end
end