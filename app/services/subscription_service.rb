class SubscriptionService
  def initialize(user)
    @user = user
  end

  def extend_subscription(duration)
    current_expiry = @user.subscription.payed_for
    new_expiry = calculate_new_expiry(current_expiry, duration)
    @user.subscription.update!(payed_for: new_expiry)
  end

  def subscription_status
    expiry_date = @user.subscription.payed_for
    {
      active: expiry_date > Time.current,
      expires_at: expiry_date,
      expired: expiry_date <= Time.current
    }
  end

  def days_remaining
    return 0 if subscription_status[:expired]
    
    ((subscription_status[:expires_at] - Time.current) / 1.day).ceil
  end

  def format_expiry_date
    @user.subscription.payed_for.strftime('%d.%m.%Y')
  end

  private

  def calculate_new_expiry(current_expiry, duration)
    # If subscription is already expired, start from current time
    # Otherwise, extend from current expiry date
    current_expiry < Time.current ? Time.current + duration : current_expiry + duration
  end
end
