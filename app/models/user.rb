# frozen_string_literal: true

class User < ApplicationRecord
  has_one :setting, dependent: :destroy
  has_one :subscription, dependent: :destroy

  before_create :initialize_setting, :initialize_subscription

  private

  def initialize_setting
    build_setting
  end

  def initialize_subscription
    self.subscription = Subscription.build_with_free_tier(id)
  end
end
