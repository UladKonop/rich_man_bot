class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  ICONS = {
    cross: "\xE2\x9D\x8C",
    edit: "\xE2\x9C\x8F",
    check: "\xE2\x9C\x85",
    back_arrow: "\xE2\x86\xA9",
    credit_card: "\xF0\x9F\x92\xB3",
    instruction: "\xF0\x9F\x93\x96",
    settings: "\xF0\x9F\x94\xA7",
    money: "\xF0\x9F\x92\xB0",
    calendar: "\xF0\x9F\x93\x85",
    list: "\xF0\x9F\x93\x9C"
  }.freeze

  before_action :find_user

  def start!(*)
    show_instruction
  end

  def keyboard!(value = nil, *)
    if value
      show_add_expense if main_menu_buttons[:add_expense].include?(value)
      show_expenses_menu if main_menu_buttons[:expenses].include?(value)
      show_instruction if main_menu_buttons[:instruction].include?(value)
      show_settings_menu if main_menu_buttons[:settings].include?(value)
      # buy_subscription if main_menu_buttons[:buy_subscription].include?(value)
    else
      show_main_menu
    end
  end

  def hhh!(*)
    binding.pry if Rails.env.development?
  end

  def message(message)
    case session[:context]
    when :add_category_name
      add_category_name(message)
    when :add_category_emoji
      add_category_emoji(message)
    when :edit_category_name
      edit_category_name(message)
    when :edit_category_emoji
      edit_category_emoji(message)
    when :add_expense
      handle_add_expense(message)
    when :change_currency!
      @user.setting.update(currency: message)
      show_settings_menu
    else
      show_main_menu
    end
  end

  def callback_query(action)
    case action
    when 'add_category'
      add_category
    when /^edit_category_(\d+)$/
      edit_category($1.to_i)
    when /^delete_category_(\d+)$/
      delete_category($1.to_i)
    when /^select_category_(\d+)$/
      category_id = $1.to_i
      save_context :add_expense
      session[:selected_category_id] = category_id
      respond_with_markdown_message(
        text: translation('add_expense.enter_amount'),
        reply_markup: back_button_inline('show_add_expense')
      )
    when /^report_category_(\d+)$/
      category_id = $1.to_i
      show_expenses(category_id)
    when 'change_currency'
      save_context :change_currency!
      respond_with_markdown_message(
        text: translation('settings.currency.prompt'),
        reply_markup: back_button_inline('show_settings_menu')
      )
    when 'show_language_info'
      respond_with_markdown_message(
        text: translation('settings.language.select'),
        reply_markup: {
          inline_keyboard: [
            [
              { text: translation('settings.language.russian'), callback_data: 'set_language_ru' },
              { text: translation('settings.language.english'), callback_data: 'set_language_en' },
              { text: translation('settings.language.belarusian'), callback_data: 'set_language_be' }
            ],
            back_button('show_settings_menu')
          ]
        }
      )
    when /^set_language_(\w+)$/
      language = $1
      @user.setting.update(language: language)
      I18n.locale = language.to_sym
      show_settings_menu(translation('settings.language.changed', language: language))
    else
      invoke_action(action)
    end
  end

  # Actions

  def show_expenses_menu
    save_context :keyboard!
    respond_with_markdown_message(
      text: translation('expenses_menu.prompt'),
      reply_markup: expenses_menu_keyboard_markup
    )
  end

  def show_add_expense
    show_categories
  end

  def show_categories
    categories_buttons = @user.user_categories.map do |category|
      [
        { text: category.display_name, callback_data: "select_category_#{category.id}" },
        { text: "✏️", callback_data: "edit_category_#{category.id}" },
        { text: "🗑️", callback_data: "delete_category_#{category.id}" }
      ]
    end

    respond_with_markdown_message(
      text: translation('categories.list'),
      reply_markup: {
        inline_keyboard: categories_buttons + [
          [{ text: translation('categories.add'), callback_data: 'add_category' }],
          back_button('keyboard!')
        ]
      }
    )
  end

  def buy_subscription
    save_context :keyboard!
    user_subscription_payed_for = @user.subscription.payed_for
    text = user_subscription_payed_for < DateTime.now ? 'buy.prompt_outdated' : 'buy.prompt'
    respond_with_markdown_message(text: translation(text, date: user_subscription_payed_for.strftime("%d.%m.%Y")), reply_markup: buy_subscription_keyboard_markup)
  end

  def show_expenses_for_category(category_id)
    expense_service = ExpenseService.new(@user)
    expenses_data = expense_service.get_expenses(category_id)
    message = expense_service.format_expenses_report(expenses_data)

    respond_with_markdown_message(
      text: message,
      reply_markup: back_button_inline('show_expenses_menu')
    )
  end

  def show_expenses(category_id = nil)
    expense_service = ExpenseService.new(@user)
    expenses_data = expense_service.get_expenses_report(category_id)
    message = expenses_data[0]
    total = expenses_data[1]

    respond_with_markdown_message(
      text: message,
      reply_markup: back_button_inline('show_expenses_menu')
    )
  end

  def show_main_menu(text = translation('main_menu.prompt'))
    save_context :keyboard!
    respond_with_markdown_message(text: text, reply_markup: main_keyboard_markup)
  end

  def show_settings_menu(message = nil)
    save_context :keyboard!
    text = message || translation('settings.prompt')
    respond_with_markdown_message(
      text: text,
      reply_markup: update_settings_keyboard_markup
    )
  end

  def show_instruction
    save_context :keyboard!
    respond_with_markdown_message(
      text: translation('instruction.main'),
      reply_markup: main_keyboard_markup
    )
  end

  def add_expense(*)
    handle_add_expense(payload['text'])
  end

  def handle_add_expense(text)
    parts = text.split(' ', 2)
    amount = parts[0].gsub(',', '.').to_f
    description = parts[1].to_s.strip
    category_id = session[:selected_category_id]
  
    unless category_id.present?
      Rails.logger.error "No selected_category_id in session! Session: #{session.inspect}"
      show_main_menu(translation('invalid_amount'))
      return
    end
  
    unless amount.positive?
      show_main_menu(translation('invalid_amount'))
      return
    end
  
    expense_service = ExpenseService.new(@user)
    result = expense_service.add_expense(category_id, amount, description)
    
    # binding.irb
    if result[:success]
      session.delete(:selected_category_id)
      show_main_menu(translation('expense_added'))
    else
      errors = result[:errors]&.join(', ') || 'Unknown error'
      show_main_menu(translation('expense_error', errors: errors))
    end
  end

  def change_currency!(*)
    @user.setting.update(currency: payload['text'])
    show_settings_menu
  end

  def add_category
    save_context :add_category_name
    respond_with_markdown_message(
      text: translation('categories.add_name'),
      reply_markup: back_button_inline('keyboard!')
    )
  end

  def add_category_name(message)
    session[:category_name] = message
    save_context :add_category_emoji
    respond_with_markdown_message(
      text: translation('categories.add_emoji'),
      reply_markup: back_button_inline('keyboard!')
    )
  end

  def add_category_emoji(message)
    emoji = message
    name = session[:category_name]
    if emoji.length == 1 && emoji.ord > 1000 && name.present?
      @user.user_categories.create!(name: name, emoji: emoji)
      session.delete(:category_name)
      show_categories
    else
      respond_with_markdown_message(
        text: translation('categories.invalid_emoji'),
        reply_markup: back_button_inline('keyboard!')
      )
    end
  end

  def edit_category(category_id)
    @category = @user.user_categories.find(category_id)
    save_context :edit_category_name
    respond_with_markdown_message(
      text: translation('categories.edit_name', current_name: @category.name),
      reply_markup: back_button_inline('keyboard!')
    )
  end

  def edit_category_name(message)
    @category.update!(name: message.text)
    save_context :edit_category_emoji
    respond_with_markdown_message(
      text: translation('categories.edit_emoji', current_emoji: @category.emoji),
      reply_markup: back_button_inline('keyboard!')
    )
  end

  def edit_category_emoji(message)
    emoji = message.text
    if emoji.length == 1 && emoji.ord > 1000
      @category.update!(emoji: emoji)
      show_categories(translation('categories.updated'))
    else
      respond_with_markdown_message(
        text: translation('categories.invalid_emoji'),
        reply_markup: back_button_inline('keyboard!')
      )
    end
  end

  def delete_category(category_id)
    category = @user.user_categories.find(category_id)
    if category.expenses.any?
      respond_with_markdown_message(
        text: translation('categories.cannot_delete_has_expenses'),
        reply_markup: back_button_inline('keyboard!')
      )
    else
      category.destroy!
      show_categories(translation('categories.deleted'))
    end
  end

  private

  def find_user
    @user = User.find_or_create_by(chat_id: chat['id'])
    @user.update(name: chat['username']) unless @user.name.present?
    I18n.locale = @user.setting.language&.to_sym || :ru
  end

  def respond_with_markdown_message(params = {})
    Rails.logger.debug "Original params: #{params.inspect}"
    Rails.logger.debug "Original text: #{params[:text]}"
    Rails.logger.debug "Text bytes: #{params[:text].bytes.inspect}"
    
    response = respond_with :message, params.merge(parse_mode: 'Markdown')
    Rails.logger.debug "Response: #{response.inspect}"
    response
  end

  def main_keyboard_markup
    expenses_button = "#{main_menu_buttons[:expenses]} #{ICONS[:money]}"
    add_expense_button = "#{main_menu_buttons[:add_expense]} #{ICONS[:credit_card]}"
    instruction_button = "#{main_menu_buttons[:instruction]} #{ICONS[:instruction]}"
    settings_button = "#{main_menu_buttons[:settings]} #{ICONS[:settings]}"

    buttons = []
    if @user.setting.active?
      buttons << [add_expense_button, expenses_button]
    else
      buttons << [expenses_button]
    end
    buttons << [settings_button, instruction_button]

    {
      keyboard: buttons,
      resize_keyboard: true,
      one_time_keyboard: true,
      selective: true
    }
  end

  def expenses_menu_keyboard_markup
    categories_buttons = @user.user_categories.order(:name).map do |category|
      { text: category.display_name, callback_data: "report_category_#{category.id}" }
    end

    all_expenses_button = { text: "#{ICONS[:list]} #{translation('expenses_menu.all')}", callback_data: "category_all" }

    {
      inline_keyboard: [
        *categories_buttons.each_slice(2).to_a,
        [all_expenses_button],
        back_button('keyboard!')
      ]
    }
  end

  def back_button_inline(callback_data = 'keyboard!')
    { inline_keyboard: [back_button(callback_data)] }
  end

  def back_button(callback_data = 'keyboard!')
    [{ text: "#{translation('back_button')}  #{ICONS[:back_arrow]}", callback_data: callback_data }]
  end

  def main_menu_buttons
    {
      expenses: translation('main_menu.buttons.expenses'),
      add_expense: translation('main_menu.buttons.add_expense'),
      instruction: translation('main_menu.buttons.instruction'),
      settings: translation('main_menu.buttons.settings')
    }
  end

  def translation(path, params = {})
    Rails.logger.debug "Current locale: #{I18n.locale}"
    Rails.logger.debug "Available locales: #{I18n.available_locales.inspect}"
    Rails.logger.debug "Looking for translation at: telegram_webhooks.#{path}"
    Rails.logger.debug "Translation exists? #{I18n.exists?("telegram_webhooks.#{path}")}"
    
    if params.empty?
      t("telegram_webhooks.#{path}")
    else
      t("telegram_webhooks.#{path}", **params)
    end
  end

  def invoke_action(action, *args)
    send(action, *args) if respond_to?(action, true)
  end

  def save_context(context)
    session[:context] = context
  end

  def update_settings_keyboard_markup
    {
      inline_keyboard: [
        [
          { text: translation('settings.currency.current', currency: @user.setting.currency), callback_data: 'change_currency' }
        ],
        [
          { text: translation('settings.language.current', language: @user.setting.language || 'ru'), callback_data: 'show_language_info' }
        ],
        back_button('keyboard!')
      ]
    }
  end
end
