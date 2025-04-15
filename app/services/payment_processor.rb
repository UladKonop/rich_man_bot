# frozen_string_literal: true

class PaymentProcessor
  include ActiveModel::Model

  attr_accessor :params
  attr_reader :user

  validates :params, presence: true

  validate :validate_payload, unless: :test?

# Example of params
#  {"notification_type"=>"p2p-incoming",
#  "bill_id"=>"",
#  "amount"=>"791.77",
#  "datetime"=>"2020-09-02T14:24:30Z",
#  "codepro"=>"false",
#  "sender"=>"41001000040",
#  "sha1_hash"=>"9703c86510f42d17d179c01cfe85740f291c7842",
#  "test_notification"=>"false",
#  "operation_label"=>"",
#  "operation_id"=>"test-notification",
#  "currency"=>"643",
#  "label"=>"{\"chat_id\":417205227,\"subscription_type\":\"month\"}",
#  "controller"=>"payments",
#  "action"=>"create"}

  def initialize(params:)
    @params = params
  end

  def run
    return true if test?

    log_payment_info
    if invalid?
      log_errors
      return
    end

    Payment.transaction do
      create_payment!
      renew_subcription!
      send_message(chat_id, msg)
      true
    end
  end

  private

  def test?
    params[:test_notification] == 'true'
  end

  def create_payment!
    subscription.payments.create!(payment_params)
  rescue ActiveRecord::RecordInvalid => e
    handle_invalid_record(e.record)
  end

  def renew_subcription!
    subscription.renew!
  rescue ActiveRecord::RecordInvalid => e
    handle_invalid_record(e.record)
  end

  def subscription
    user&.subscription
  end

  def user
    @user ||= User.find_by(chat_id: chat_id)
  end

  def validate_payload
    return errors[:payment_label] << 'can not be empty' if params[:label].blank?
    return errors[:payment_label] << 'invalid json' if payload.blank?
    return errors[:payment_label] << 'could not found chat_id' if chat_id.blank?

    errors[:payment_label] << 'could not found subscription_type' if subscription_type.blank?
  end

  def chat_id
    payload[:chat_id]
  end

  def subscription_type
    payload[:subscription_type].to_sym
  end

  def payload
    @payload ||= begin
                   JSON(params[:label], symbolize_names: true)
                 rescue StandardError
                   ''
                 end
  end

  def payment_params
    accepted = params[:unaccepted] != 'true'

    base_params = params
                  .slice(:amount)
                  .merge(
                    accepted: accepted,
                    subscription_type: subscription_type
                  )

    additional_params = params
                        .slice(:sender, :sha1_hash, :operation_id, :email, :phone, :city, :datetime, :codepro)

    base_params.merge(parameters: additional_params)
  end

  def log_payment_info
    user_info = user ? user.name || user.id : 'unknown'
    logger.info "for user #{user_info} with params: #{params.inspect}"
  end

  def handle_invalid_record(record)
    errors.copy!(record.errors)
    log_errors
    raise ActiveRecord::Rollback
  end

  def log_errors
    logger.error errors.full_messages.to_sentence
  end

  def logger
    Rails.logger
  end

  def send_message(chat_id, msg)
    return if Rails.env.test?
    
    Telegram.bot.send_message(chat_id: chat_id, text: msg, parse_mode: 'Markdown')
  end

  def msg
    <<~MSG
      *Спасибо #{user&.name || ""}!*
      Подписка успешно продлена до #{subscription.payed_for.strftime("%d.%m.%Y")}
    MSG
  end
end
