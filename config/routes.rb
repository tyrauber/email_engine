Rails.application.routes.draw do
  unless respond_to?(:has_named_route?) && has_named_route?("email_engine")
    mount EmailEngine::Engine => "/email"
  end
end

EmailEngine::Engine.routes.draw do
  scope module: "email" do
    resources :messages, only: [] do
      get :open, on: :member
      get :click, on: :member
    end
  end
end
