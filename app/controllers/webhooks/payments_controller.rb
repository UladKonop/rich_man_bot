class Webhooks::PaymentsController < ApplicationController
  # POST /payments
  def create
    # if unaccepted - true send to user info
    if PaymentProcessor.new(params: payment_params).run
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def payment_params
    params.permit(:amount, :sender, :label, :bill_id, :sha1_hash, :operation_id, :email, :phone, :city, :datetime, :codepro, :unaccepted, :test_notification)
  end
end
