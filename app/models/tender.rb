# frozen_string_literal: true

class Tender < ApplicationRecord
  include PgSearch::Model

  FIELD_KEYS = {
    industry: 'industry'
  }.freeze

  FIELDS_EQ_TEMPLATE = '(fields ->> %<key>s = %<value>s)'
  FIELDS_ILIKE_TEMPLATE ='(fields ->> %<key>s ilike %<value>s)'

  validates :url, presence: true, uniqueness: true

  pg_search_scope :search_any_word, against: [
    [:header, 'A'],
    [:body, 'B']
  ], using: {
    tsearch: { any_word: true }
  }

  scope :by_industries, ->(industries) { fields_ilike(FIELD_KEYS[:industry], industries) }
  scope :by_keywords, ->(keywords) { search_any_word keywords.join(' ') if keywords.present? }

  scope :fields_ilike, lambda { |key, query_values|
    # surround by % to find all records
    # that include at least one occurrence of the given values
    values = query_values&.map { |value| "%#{value}%" }
    by_fields_template(key, values, FIELDS_ILIKE_TEMPLATE)
  }

  scope :fields_eq, lambda { |key, value|
    values = value.split(/[\s,]+/).reject(&:empty?)
    by_fields_template(key, values, FIELDS_EQ_TEMPLATE)
  }

  scope :by_fields_template, lambda { |key, values, fields_template|
    return all unless values.present?
    # use connection quote to prevent possible SQL injections
    connection = ActiveRecord::Base.connection
    quoted_key = connection.quote(key)

    # allowing multiple values separated by commas
    comparison_expression = values.map do |val|
      quoted_value = connection.quote(val.strip)
      format(fields_template, key: quoted_key, value: quoted_value)
    end.join(' OR ')

    where("fields ? #{quoted_key} AND (#{comparison_expression})")
  }

  def add_field!(key, value)
    f = fields || {}
    f[key] = value
    self.fields = f
    save!
  end
end
