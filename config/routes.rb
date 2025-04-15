Rails.application.routes.draw do
  # namespace :webhooks do
  #   resources :payments, only: [:create]
  # end
  # resources :payments, only: [:new]

  telegram_webhook TelegramWebhooksController
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
