class Expense < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :description, length: { maximum: 1000 }

  scope :by_date, -> { order(date: :desc) }
  scope :for_category, ->(category_id) { where(category_id: category_id) }
  scope :between_dates, ->(start_date, end_date) { where(date: start_date..end_date) }

  def self.total_amount
    sum(:amount)
  end
end 