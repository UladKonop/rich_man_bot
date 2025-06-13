class UserCategory < ApplicationRecord
  belongs_to :user
  has_many :expenses, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 50 }
  validates :emoji, presence: true

  def display_name
    "#{emoji} #{name}"
  end

  def total_amount
    expenses.sum(:amount)
  end
end
