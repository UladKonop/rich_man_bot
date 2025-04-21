# frozen_string_literal: true

class User < ApplicationRecord
  has_one :setting, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :expenses, dependent: :destroy

  before_create :initialize_setting, :initialize_subscription

  validates :chat_id, presence: true, uniqueness: true

  def expenses_by_category(category_id = nil)
    expenses = self.expenses.by_date
                  .between_dates(Date.current.beginning_of_month, Date.current.end_of_month)
    expenses = expenses.for_category(category_id) if category_id
    expenses
  end

  def total_expenses(category_id = nil)
    expenses = self.expenses
                  .between_dates(Date.current.beginning_of_month, Date.current.end_of_month)
    expenses = expenses.for_category(category_id) if category_id
    expenses.total_amount
  end

  private

  def initialize_setting
    build_setting
  end

  def initialize_subscription
    self.subscription = Subscription.build_with_free_tier(id)
  end
end
