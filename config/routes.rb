Rails.application.routes.draw do
  get 'line_bot/callback'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  post '/callback' => 'line_bot#callback'
end
