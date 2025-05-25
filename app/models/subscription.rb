# frozen_string_literal: true

class Subscription < ApplicationRecord
  belongs_to :user
  has_many :payments

  TYPES = %i[
    month
    three_month
    six_month
  ].freeze

  COSTS = {
    month: 10,
    three_month: 20,
    six_month: 30
  }.freeze

  PERIODS = {
    free_tier: 30.days,
    month: 1.month,
    three_month: 3.month,
    six_month: 6.month
  }.with_indifferent_access
   .freeze

  scope :active, -> { where(Subscription.arel_table[:payed_for].gt(DateTime.now)) }

  class << self
    def build_with_free_tier(user_id)
      new(
        user_id: user_id,
        payed_for: DateTime.now + PERIODS[:free_tier]
      )
    end

    def plans
      TYPES.map do |type|
        I18n.t(type, scope: 'subscriptions')
          .merge(cost: COSTS[type])
          .merge(type: type)
      end
    end
  end

  def active?
    payed_for >= DateTime.now
  end

  def renew!
    Subscription.transaction do
      payments.not_used.each do |payment|
        update_payed_for!(PERIODS[payment.subscription_type.to_sym])
        payment.use!
      end
    end
  end

  private

  def update_payed_for!(period)
    now = DateTime.now
    start_time = if payed_for
                   payed_for > now ? payed_for : now
                 else
                   now
                 end
    new_payed_for = start_time + period

    update(payed_for: new_payed_for)
  end
end
