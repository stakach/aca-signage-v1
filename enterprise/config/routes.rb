Signage::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  
  root to: "sessions#new"
	match "/auth/:provider/callback", to: "sessions#create"
	match "/auth/failure", to: "sessions#failure"
	match "/logout", to: "sessions#destroy", :as => "logout"
	resources :identities
	resources :authentications
	resources :invites
  
  
  scope "(:locale)", :locale => /en|de/ do
  	#
	# Using ACA Auth (doubling routes here for language support)
	#
  	  	
  	
  	
	resources :users
	resources :sub_groups
	resources :ug do
		get		:subgroups,		:on => :collection
	end
	resources :medias do
		get		:row,			:on => :member
		post	:recover,		:on => :collection
		post	:error_retry,	:on => :member
	end
	resources :playlists do
		put		:publish,	:on => :member
		get		:preview,	:on => :member
		get		:footer,	:on => :member
		put		:move,	:on => :member
	end
	resources :playitems do
		put		:move, :on => :collection	# Put as we are updating
		post	:copy, :on => :collection	# Post as we are creating
		delete	:destroy, :on => :collection	# So we don't have to define an item id for destroy here
		put		:order, :on => :collection	# Update the order of things
	end
	resources :converters do
		put		:order, :on => :collection	# Update the order of things
	end
	resources :displays do
		delete	:destroy, :on => :collection
		get		:present, :on => :member
	end
	resources :group_displays
	resources :groups do
		get		:footer,	:on => :member
	end
	resources :groupitems do
		put		:move, :on => :collection
		post	:copy, :on => :collection
		delete	:destroy, :on => :collection
	end
	resources :schedules do
		put		:update_runtime,	:on => :member
		put		:update_move,	:on => :member
	end
	resources :plugins

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

	resources :monitors
	put 'switch_group' => 'monitors#switch_group'
	put 'switch_subgroup' => 'monitors#switch_subgroup'
	
	
	mount Resolute::Engine => "/uploads"
	
	
	match '*permalink' => 'displays#present'
  end

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
