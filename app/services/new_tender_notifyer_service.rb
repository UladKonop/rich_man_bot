# frozen_string_literal: true

class NewTenderNotifyerService
  LIMIT_TENDERS_TO_SEND = 10

  def call
    Setting.active.includes(:user).find_each do |setting|
      last_tenders = last_tenders(setting).load
      next unless last_tenders.present?

      last_sended_id = setting.last_sended_tender_id || 0
      not_sended_tenders = last_tenders.select { |tender| tender.id > last_sended_id }

      next if not_sended_tenders.blank?

      not_sended_tenders.each do |tender|
        msg = prepare_msg(tender)

        send_message(setting.user.chat_id, msg)
      end

      setting.update(last_sended_tender_id: not_sended_tenders.first.id)
    end
  end

  private

  def send_message(chat_id, msg)
    Telegram.bot.send_message(chat_id: chat_id, text: msg, parse_mode: 'Markdown')
  rescue
  end

  def prepare_msg(tender)
    Message.new(tender: tender).to_s
  end

  # latest fetched tenders the first is newest
  def last_tenders(setting)
    setting
      .filtered_tenders.reorder(id: :desc)
      .limit(LIMIT_TENDERS_TO_SEND)
  end
end
