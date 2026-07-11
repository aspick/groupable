Groupable::Engine.routes.draw do
  resource :join, only: [ :show, :create ], controller: "joins"

  resources :groups, except: [ :new, :edit ] do
    resources :invites, only: [ :create ]
    resources :members, only: [ :index, :show, :update, :destroy ], param: :user_id
  end
end
