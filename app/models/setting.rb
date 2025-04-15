# frozen_string_literal: true

class Setting < ApplicationRecord
  belongs_to :user
  has_one :subscription, through: :user

  scope :active, -> { joins(user: :subscription).merge(Subscription.active).where(active: true) }

  def filtered_tenders
    Tender.by_industries(industries).by_keywords(keywords)
  end

  def industries
    f = filters || {}
    f['industries'] ||= []
  end

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

  def add_industries!(industries)
    add_filter!('industries', industries)
  end

  def reset_industries!
    add_filter!('industries', [])
  end

  def add_keywords!(raw_keywords)
    new_keywords = raw_keywords.join(', ').split(/[,\.\s]+/)
    update(keywords: new_keywords)
  end

  def reset_keywords!
    update(keywords: [])
  end

  def add_filter!(key, value)
    f = filters || {}
    f[key] = value
    self.filters = f
    save!
  end

  def pretty_keywords
    keywords.join(", ")
  end
end
