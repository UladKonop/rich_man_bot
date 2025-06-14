class PaymentService
  def initialize(user)
    @user = user
    @subscription_service = SubscriptionService.new(user)
  end

  def process_subscription_payment(payment_data)
    return false unless valid_subscription_payment?(payment_data)

    plan_key = payment_data['invoice_payload'].split('_').last.to_sym
    plan = SubscriptionPlan.find(plan_key)
    
    save_payment_record(payment_data)
    @subscription_service.extend_subscription(plan[:duration])
    
    true
  rescue => e
    Rails.logger.error "Failed to process subscription payment: #{e.message}"
    false
  end

  def create_subscription_invoice(plan_key)
    plan = SubscriptionPlan.find(plan_key)
    monthly_price = SubscriptionPlan.monthly_price(plan)
    savings = SubscriptionPlan.savings(plan)

    description = if savings.zero?
      I18n.t('telegram_webhooks.buy.invoice_description_simple',
        days: plan[:duration].to_i / 1.day,
        monthly_price: monthly_price
      )
    else
      I18n.t('telegram_webhooks.buy.invoice_description_with_savings',
        days: plan[:duration].to_i / 1.day,
        monthly_price: monthly_price,
        savings: savings
      )
    end

    {
      title: I18n.t("telegram_webhooks.buy.invoice_title_#{plan_key}"),
      description: description,
      payload: "subscription_payment_#{plan_key}",
      provider_token: '', # Empty for Telegram Stars
      currency: 'XTR',
      prices: [
        { 
          label: I18n.t("telegram_webhooks.buy.subscription_label_#{plan_key}"), 
          amount: plan[:stars]
        }
      ]
    }
  end

  private

  def valid_subscription_payment?(payment_data)
    payload_parts = payment_data['invoice_payload'].split('_')
    return false unless payload_parts.first == 'subscription'
    
    plan_key = payload_parts.last.to_sym
    plan = SubscriptionPlan.find(plan_key)
    
    payment_data['currency'] == 'XTR' &&
    payment_data['total_amount'] == plan[:stars]
  end

  def save_payment_record(payment_data)
    # Log payment for now - in production, save to Payment model
    Rails.logger.info "Subscription payment processed: #{payment_data.inspect}"
    
    # Future implementation:
    # Payment.create!(
    #   user: @user,
    #   telegram_payment_charge_id: payment_data['telegram_payment_charge_id'],
    #   provider_payment_charge_id: payment_data['provider_payment_charge_id'],
    #   currency: payment_data['currency'],
    #   total_amount: payment_data['total_amount'],
    #   invoice_payload: payment_data['invoice_payload'],
    #   processed_at: Time.current
    # )
  end
end
