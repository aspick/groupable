Groupable::Engine.routes.draw do
  resources :groups do
    collection do
      resource :join, only: [:show, :create], controller: 'joins'
    end

    member do
      resources :invites, only: [:create]
    end

    resources :members, only: [:index, :show, :update, :destroy]
  end
end
