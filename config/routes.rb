Rails.application.routes.draw do

  # letsencrypt TLS challenge
  get "/.well-known/acme-challenge/#{ENV['ACME_CHALLENGE_WELL_KNOWN']}", to: proc { |env|
    [200, {}, [ENV["ACME_CHALLENGE_KEY"]]]
  }

  devise_for :users, :controllers => { :registrations => 'registrations' }

  root 'home#index'
  get '/terms' => 'home#terms', as: :terms
  get '/terms_agreement' => 'home#terms_agreement', as: :terms_agreement
  post '/terms_agreement/i_agree' => 'home#terms_i_agree', as: :i_agree
  get '/our_lessons' => 'home#our_lessons', as: :our_lessons
  post '/process_purchase/:id' => 'home#process_purchase', as: :process_purchase
  get '/instructors' => 'home#instructors', as: :instructors
  get '/contact' => 'home#contact', as: :contact
  post '/contact' => 'home#submit_contact', as: :submit_contact
  get '/schedule' => 'schedule#index', as: :schedule
  get '/testimonials' => 'home#testimonials', as: :testimonials
  get '/schedule/events.json' => 'schedule#events'
  get '/schedule/time_slots.json' => 'schedule#time_slots'
  get '/schedule/instructors.json' => 'schedule#instructors'

  get '/referrals' => 'referrals#index', as: :referrals
  get '/join' => 'referrals#join', as: :join

  get '/scheduler', to: redirect('/'), as: :old_scheduler
  scope "/:location_id" do
    get '/scheduler' => 'schedule#scheduler', as: :scheduler
    get '/scheduler/:id/assign' => 'schedule#assign_time_slot', as: :assign_time_slot
    post '/scheduler/assign_student' => 'schedule#assign_student_to_time_slot', as: :assign_student_to_time_slot
    get '/scheduler/:id/unassign' => 'schedule#unassign_time_slot', as: :unassign_time_slot
    post '/scheduler/:id/unassign' => 'schedule#perform_unassign_time_slot', as: :perform_unassign_time_slot
    post '/scheduler/switch_time_slot_times' => 'schedule#switch_time_slot_times', as: :switch_time_slot_times

    post '/schedule/assign.json' => 'schedule#assign'
    post '/schedule/unassign.json' => 'schedule#unassign'
  end

  get '/profile' => 'profile#show', as: :profile
  get '/profile/show/:id' => 'profile#show', as: :view_profile
  get '/profile/edit' => 'profile#edit', as: :edit_profile
  match '/profile/edit' => 'profile#update', as: :update_profile, via: [:put, :patch]
  get '/profile/export_ical' => 'profile#export_ical', as: :export_ical

  post '/merchant/ipn' => 'merchant#ipn'
  get '/merchant/vertex' => 'merchant#vertex'

  get '/return_to_admin' => 'home#return_to_admin', as: :return_to_admin

  # Cart
  resource :cart, only: [:show]
  resources :order_items, only: [:create, :update, :destroy]

  resources :students, :path => "learners"

  namespace :admin do
    resources :locations
    namespace :reports do
      get :lessons
      get :instructor_lessons
      get :export_csv
    end
    resources :users do
      collection do
        get :search
      end
      member do
        get :login_as
        get :order_details
        get :lesson_transfer_details
        get :add_lessons
        post :create_lessons
        get :transfer_lessons
        post :perform_transfer
        delete :delete_order
        match :delete_lessons, via: [:delete, :post]
      end
    end
    resources :products
    resources :testimonials
    get 'schedule' => 'schedule#index'
    get 'schedule/builder' => 'schedule#schedule_builder', as: :schedule_builder
    post 'schedule/builder' => 'schedule#process_schedule_builder', as: :process_schedule_builder
    get 'schedule/resources' => 'schedule#resources', as: :schedule_resources
    post 'schedule/create_time_slot' => 'schedule#create_time_slot', as: :create_time_slot
    post 'update_schedule' => 'schedule#update', as: :update_schedule
    match 'delete_time_slot/:id' => 'schedule#destroy_time_slot', as: :delete_time_slot, via: [:delete, :get]
    match 'unassign_time_slot/:id' => 'schedule#unassign_time_slot', as: :unassign_time_slot, via: [:post, :get]
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
