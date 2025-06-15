class SubscriptionPlan
  PLANS = {
    month: {
      duration: 30.days,
      stars: 99,
      discount: 0
    },
    three_month: {
      duration: 90.days,
      stars: 239,
      discount: 10
    },
    six_month: {
      duration: 180.days,
      stars: 439,
      discount: 17
    },
    year: {
      duration: 365.days,
      stars: 799,
      discount: 25
    }
  }.freeze

  def self.all
    PLANS
  end

  def self.find(key)
    PLANS[key.to_sym]
  end

  def self.monthly_price(plan)
    (plan[:stars].to_f / (plan[:duration].to_f / 30.days)).round(2)
  end
end
