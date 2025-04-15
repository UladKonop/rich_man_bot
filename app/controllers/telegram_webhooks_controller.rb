class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  ICONS = {
    cross: "\xE2\x9D\x8C",
    edit: "\xE2\x9C\x8F",
    industry: "\xF0\x9F\x92\xBC",
    check: "\xE2\x9C\x85",
    rocket: "\xF0\x9F\x9A\x80",
    back_arrow: "\xE2\x86\xA9",
    credit_card: "\xF0\x9F\x92\xB3",
    instruction: "\xF0\x9F\x93\x96",
    search: "\xF0\x9F\x94\x8D",
    settings: "\xF0\x9F\x94\xA7",
    stop_search: "\xE2\x9B\x94",
    link_arrow: "\xE2\x86\x97"
  }.freeze

  before_action :find_user

  def start!(*)
    show_instruction
  end

  def keyboard!(value = nil, *)
    if value
      show_settings_menu if main_menu_buttons[:settings].include?(value)
      activate_search if main_menu_buttons[:start_search].include?(value)
      deactivate_search if main_menu_buttons[:stop_search].include?(value)
      buy_subscription if main_menu_buttons[:buy_subscription].include?(value)
      show_instruction if main_menu_buttons[:instruction].include?(value)
    else
      show_main_menu
    end
  end

  def hhh!(*)
    binding.pry if Rails.env.development?
  end

  def message(_message)
    show_main_menu
  end

  def callback_query(action)
    invoke_action(action)
  end

  # Actions

  def activate_search
    if @user.setting.activate!
      show_main_menu(translation('was_activated'))
    else
      save_context :keyboard!
      respond_with_markdown_message(text: translation('buy.need_subscription'), reply_markup: main_keyboard_markup)      
    end
  end

  def deactivate_search
    @user.setting.deactivate!
    show_main_menu(translation('was_deactivated'))
  end

  def buy_subscription
    save_context :keyboard!
    user_subscription_payed_for = @user.subscription.payed_for
    text = user_subscription_payed_for < DateTime.now ? 'buy.prompt_outdated' : 'buy.prompt'
    respond_with_markdown_message(text: translation(text, date: user_subscription_payed_for.strftime("%d.%m.%Y")), reply_markup: buy_subscription_keyboard_markup)
  end

  def change_keywords
    save_context :apply_keywords
    respond_with_markdown_message(
      text: translation('change_keywords', keywords: @user.setting.pretty_keywords),
      reply_markup: change_keywords_keyboard_markup
    )
  end

  def show_main_menu(text = translation('main_menu.prompt'))
    save_context :keyboard!
    respond_with_markdown_message(text: text, reply_markup: main_keyboard_markup)
  end

  def show_settings_menu
    save_context :keyboard!
    respond_with_markdown_message(text: translation('settings_inline_keyboard.prompt'), reply_markup: update_settings_keyboard_markup)
  end

  def show_instruction
    save_context :keyboard!
    bot.send_message(chat_id: @user.chat_id, text: Message.instruction, parse_mode: 'HTML')
    show_main_menu
  end

  def apply_keywords(*args)
    @user.setting.add_keywords!(args)

    save_context :keyboard!
    respond_with_markdown_message(text: translation('apply_keywords.done', keywords: @user.setting.pretty_keywords), reply_markup: main_keyboard_markup)
  end

  def reset_keywords
    @user.setting.reset_keywords!

    save_context :keyboard!
    respond_with_markdown_message(text: translation('reset_keywords.done'), reply_markup: main_keyboard_markup)
  end

  def choose_industry
    respond_with_markdown_message(text: translation('choose_industry.prompt'), reply_markup: choose_industry_keyboard_markup(slected_industries_ids))
  end

  # methaprogrammig! define methods like choose_industry_1, choose_industry_2 for each industry
  Industry::INDUSTRIES.each_with_index do |_indusry, id|
    define_method("choose_industry_#{id}") do
      industries_buttons_state[id] = !industries_buttons_state[id]
      edit_message :reply_markup, reply_markup: choose_industry_keyboard_markup(slected_industries_ids)
    end
  end

  # reset all selected industries
  def reset_industry
    @user.setting.reset_industries!

    save_context :keyboard!
    respond_with_markdown_message(text: translation('reset_industry.done'), reply_markup: main_keyboard_markup)
  end

  def apply_industry
    industries = Industry::INDUSTRIES.values_at(*slected_industries_ids)
    @user.setting.add_industries!(industries)
    destroy_industries_buttons_state

    save_context :keyboard!
    respond_with_markdown_message(text: translation('apply_industry.done'), reply_markup: main_keyboard_markup)
  end

  private

  def find_user
    @user = User.find_or_create_by(chat_id: chat['id'])
    # temporarry will be replaced with
    # @user = User.find_or_create_by(chat_id: chat['id'], name: chat['username'])
    @user.update(name: chat['username']) unless @user.name.present?
  end

  def respond_with_markdown_message(params = {})
    respond_with :message, params.merge(parse_mode: 'Markdown')
  end

  def main_keyboard_markup
    settings_button = "#{main_menu_buttons[:settings]} #{ICONS[:settings]}"
    stop_start_button = if @user.setting.active?
                          "#{main_menu_buttons[:stop_search]} #{ICONS[:stop_search]}"
                        else
                          "#{main_menu_buttons[:start_search]} #{ICONS[:search]}"
                        end
    instruction_button = "#{main_menu_buttons[:instruction]} #{ICONS[:instruction]}"
    buy_subscription_button = "#{main_menu_buttons[:buy_subscription]} #{ICONS[:credit_card]}"

    buttons = [[settings_button, stop_start_button], [instruction_button, buy_subscription_button]]
    {
      keyboard: buttons,
      resize_keyboard: true,
      one_time_keyboard: true,
      selective: true
    }
  end

  def back_button_inline(callback_data = 'keyboard!')
    { inline_keyboard: [back_button(callback_data)] }
  end

  def back_button(callback_data = 'keyboard!')
    [{ text: "#{translation('back_button')}  #{ICONS[:back_arrow]}", callback_data: callback_data }]
  end

  def update_settings_keyboard_markup
    options = translation('settings_inline_keyboard.choose_options')
    {
      inline_keyboard: [
        [{ text: "#{options[:change_keywords]}  #{ICONS[:edit]}", callback_data: 'change_keywords' }],
        [{ text: "#{options[:choose_industry]}  #{ICONS[:industry]}", callback_data: 'choose_industry' }],
        back_button('keyboard!')
      ]
    }
  end

  def buy_subscription_keyboard_markup
    # host = Rails.env.production? ? 'icetradebot.tk' : '92e23290c625.ngrok.io'
    # url = URI::HTTPS.build(host: host, path: '/payments/new', query: "chat_id=#{@user.chat_id}")
    {
      inline_keyboard: [
        #[{ text: "#{translation('buy.buy_button')}  #{ICONS[:link_arrow]}", url: url }],
        back_button('keyboard!')
      ]
    }
  end

  def change_keywords_keyboard_markup
    reset_button_text = "#{translation('reset_keywords.buttons.done')}  #{ICONS[:cross]}"
    reset_button = [{ text: reset_button_text, callback_data: 'reset_keywords' }]
    { inline_keyboard: [
      reset_button,
      back_button('show_settings_menu')
    ] }
  end

  def choose_industry_keyboard_markup(selected_ids = [])
    industries_buttons = Industry::INDUSTRIES.each_with_index.map do |name, id|
      selected = selected_ids.include?(id)
      { text: selected ? "#{ICONS[:check]} #{name}" : name, callback_data: "choose_industry_#{id}" }
    end

    industries_buttons_grid = industries_buttons
                              .each_slice(2)
                              .map { |buttons_group| buttons_group }

    done_button_text = "#{translation('apply_industry.buttons.done')}  #{ICONS[:rocket]}"
    done_button = [{ text: done_button_text, callback_data: 'apply_industry' }]

    reset_button_text = "#{translation('reset_industry.buttons.done')}  #{ICONS[:cross]}"
    reset_button = [{ text: reset_button_text, callback_data: 'reset_industry' }]

    {
      inline_keyboard: [
        *industries_buttons_grid,
        done_button,
        reset_button,
        back_button('show_settings_menu')
      ]
    }
  end

  def main_menu_buttons
    t('telegram_webhooks.main_menu.buttons')
  end

  def translation(path, params = {})
    if params.empty?
      t("telegram_webhooks.#{path}")
    else
      key, value = params.first
      t("telegram_webhooks.#{path}", key.to_sym => value)
    end
  end

  def invoke_action(action, *args)
    send(action, *args) if respond_to?(action, true)
  end

  def industries_buttons_state
    session[:choose_industry_buttons_state] ||= begin
      @user.setting.industries
           .map { |industry| Industry::INDUSTRIES.index(industry) }
           .compact
           .map { |id| [id, true] }
           .to_h
    end
  end

  def slected_industries_ids
    return [] unless industries_buttons_state.present?

    industries_buttons_state.select { |_id, value| value }.keys
  end

  def destroy_industries_buttons_state
    session[:choose_industry_buttons_state] = nil
  end
end
