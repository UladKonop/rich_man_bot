class Payment < ApplicationRecord
  belongs_to :subscription

  validates :accepted, inclusion: [true]
  validates :subscription_type, presence: true, inclusion: Subscription::TYPES.map(&:to_s)

  scope :not_used, -> { where(used: false) }

  def use!
    update(used: true)
  end
end
