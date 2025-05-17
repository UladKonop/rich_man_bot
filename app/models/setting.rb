# frozen_string_literal: true

class Setting < ApplicationRecord
  belongs_to :user
  has_one :subscription, through: :user

  validates :period_start_day, presence: true, inclusion: { in: 1..28 }

  scope :active, -> { joins(user: :subscription).merge(Subscription.active).where(active: true) }

  # only users with active subscription will be notifyed
  def active?
    active && subscription.active?
  end

  def activate!
    return false unless subscription.active?

    update(active: true)
  end

  def deactivate!
    update(active: false)
  end
end
