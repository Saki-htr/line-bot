Rails.application.routes.draw do
  get '/admin' => 'admin#index'
  post '/callback' => 'line_bot#callback'
  post '/send_attendance_check' => 'line_bot#send_attendance_check'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
