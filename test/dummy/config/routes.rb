Dummy::Application.routes.draw do
  get "/authenticated", :to => 'authenticated#index'
  root :to => 'home#index'
end
