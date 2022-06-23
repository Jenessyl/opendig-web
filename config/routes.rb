Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :fields, only: [:index, :new, :create] do
    resources :squares, only: [:index, :new, :create] do
      resources :pails, only: [:index]
      resources :loci, only: [:index, :show, :edit, :new, :create, :update]
    end
  end

  # resources :squares, only: [:show]
  # resources :loci, only: [:show]

  root to: 'fields#index'
end
