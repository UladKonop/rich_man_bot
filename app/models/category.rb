class Category < ApplicationRecord
  has_many :expenses, dependent: :destroy

  validates :name, presence: true, uniqueness: true

  scope :ordered, -> { order(:id) }

  def display_name
    I18n.t("telegram_webhooks.categories.#{name}")
  end
end 