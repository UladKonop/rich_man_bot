class Message
  include ActiveModel::Model

  attr_accessor :tender

  validates :tender, presence: true

  class << self
    def instruction
      I18n.t("instruction.main", point: "\xE2\x97\xBD")
    end
  end

  def to_s
    <<~MSG
      *#{tender.header}*

      #{tender.url}
    MSG
  end
end
