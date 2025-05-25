# frozen_string_literal: true

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
    list: "\xF0\x9F\x93\x9C",
    link_arrow: "\xE2\x86\x97"
  }.freeze

  before_action :find_user

  def start!(*)
    show_instruction
  end

  def keyboard!(value = nil, *)
    if value
      show_add_expense if main_menu_buttons[:add_expense]&.include?(value)
      show_expenses_menu if main_menu_buttons[:expenses]&.include?(value)
      show_instruction if main_menu_buttons[:instruction]&.include?(value)
      show_settings_menu if main_menu_buttons[:settings]&.include?(value)
      buy_subscription if main_menu_buttons[:buy_subscription]&.include?(value)
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
    when :edit_expense_amount
      edit_expense_amount(message)
    when :edit_expense_description
      edit_expense_description(message)
    when :change_currency!
      @user.setting.update(currency: message)
      show_settings_menu
    when :period_start_day
      period_start_day!(message)
    else
      show_main_menu
    end
  end

  def callback_query(action)
    case action
    when 'add_category'
      add_category
    when /^edit_category_(\d+)$/
      edit_category(::Regexp.last_match(1).to_i)
    when /^delete_category_(\d+)$/
      delete_category(::Regexp.last_match(1).to_i)
    when /^select_category_(\d+)$/
      category_id = ::Regexp.last_match(1).to_i
      save_context :add_expense
      session[:selected_category_id] = category_id
      respond_with_markdown_message(
        text: translation('add_expense.enter_amount'),
        reply_markup: { inline_keyboard: expense_amount_keyboard_markup(category_id) }
      )
    when /^report_category_(\d+|all)$/
      category_id = ::Regexp.last_match(1)
      category_id = category_id == 'all' ? nil : category_id.to_i
      show_expenses(category_id)
    when /^select_period_(\d{4}-\d{2}-\d{2})$/
      period_start = Date.parse(::Regexp.last_match(1))
      category_id = session[:selected_category_id]
      show_expenses(category_id, nil, period_start: period_start)
    when /^show_expense_(\d+)(?:_(\w+))?$/
      expense_id = ::Regexp.last_match(1).to_i
      context = ::Regexp.last_match(2)
      show_expense(expense_id, context)
    when /^edit_expense_(\d+)(?:_(\w+))?$/
      expense_id = ::Regexp.last_match(1).to_i
      context = ::Regexp.last_match(2)
      edit_expense(expense_id, context)
    when /^delete_expense_(\d+)$/
      expense_id = ::Regexp.last_match(1).to_i
      delete_expense(expense_id)
    when /^edit_expense_amount_(\d+)$/
      expense_id = ::Regexp.last_match(1).to_i
      save_context :edit_expense_amount
      session[:editing_expense_id] = expense_id
      respond_with_markdown_message(
        text: translation('expenses.edit_amount'),
        reply_markup: back_button_inline('show_expenses')
      )
    when /^edit_expense_description_(\d+)$/
      expense_id = ::Regexp.last_match(1).to_i
      save_context :edit_expense_description
      session[:editing_expense_id] = expense_id
      respond_with_markdown_message(
        text: translation('expenses.edit_description'),
        reply_markup: back_button_inline('show_expenses')
      )
    when 'category_all'
      show_expenses
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
            [{ text: translation('settings.language.russian'), callback_data: 'set_language_ru' }],
            [{ text: translation('settings.language.english'), callback_data: 'set_language_en' }],
            [{ text: translation('settings.language.belarusian'), callback_data: 'set_language_be' }],
            [{ text: translation('settings.language.polish'), callback_data: 'set_language_pl' }],
            back_button('show_settings_menu')
          ]
        }
      )
    when /^set_language_(\w+)$/
      language = ::Regexp.last_match(1)
      @user.setting.update(language:)
      I18n.locale = language.to_sym
      show_settings_menu(translation('settings.language.changed', language:))
    when /^show_expense_amount_for_category_(\d+)$/
      category_id = ::Regexp.last_match(1).to_i
      save_context :add_expense
      session[:selected_category_id] = category_id
      respond_with_markdown_message(
        text: translation('add_expense.enter_amount'),
        reply_markup: { inline_keyboard: expense_amount_keyboard_markup(category_id) }
      )
    when 'show_periods_menu'
      show_periods_menu
    when 'change_period_start_day'
      handle_period_start_day
    when /^set_period_start_day_(\d+)$/
      day = ::Regexp.last_match(1).to_i
      @user.setting.update!(period_start_day: day)
      show_settings_menu(translation('settings.period_start_day.changed', day: day))
    else
      invoke_action(action)
    end
  end

  # Actions

  def show_expenses_menu(message = nil)
    expense_service = ExpenseService.new(@user)
    categories_with_totals = @user.user_categories.map do |category|
      _, total = expense_service.get_expenses_report(category.id)
      {
        text: "#{category.display_name}: #{format('%.2f', total)} #{@user.setting.currency}",
        callback_data: "report_category_#{category.id}"
      }
    end.sort_by { |cat| -cat[:text].split(': ').last.to_f }

    # Calculate total for all categories
    _, all_total = expense_service.get_expenses_report
    all_expenses_button = {
      text: "#{translation('expenses_menu.all')}: #{format('%.2f', all_total)} #{@user.setting.currency}",
      callback_data: 'report_category_all'
    }

    respond_with_markdown_message(
      text: message || translation('expenses_menu.prompt'),
      reply_markup: {
        inline_keyboard: [
          *categories_with_totals.map { |cat| [{ text: cat[:text], callback_data: cat[:callback_data] }] },
          [all_expenses_button],
          [{ text: translation('expenses_menu.previous_periods'), callback_data: 'show_periods_menu' }],
          back_button('keyboard!')
        ]
      }
    )
  end

  def show_periods_menu
    save_context :keyboard!
    periods = get_available_periods
    period_buttons = periods.map do |period|
      [{ text: period[:display], callback_data: "select_period_#{period[:start_date]}" }]
    end

    respond_with_markdown_message(
      text: translation('expenses_menu.select_period'),
      reply_markup: {
        inline_keyboard: period_buttons + [back_button('show_expenses_menu')]
      }
    )
  end

  def get_available_periods
    start_day = @user.setting.period_start_day
    today = Date.today
    periods = []

    # Get all expenses dates
    expense_dates = @user.expenses.pluck(:date).uniq.sort.reverse

    # Group expenses by periods
    expense_dates.each do |date|
      period_start = if date.day >= start_day
                      Date.new(date.year, date.month, start_day)
                    else
                      Date.new(date.year, date.month, start_day).prev_month
                    end
      
      # Calculate end date as start_day - 1 of next month
      period_end = if period_start.month == 12
                    Date.new(period_start.year + 1, 1, start_day) - 1.day
                  else
                    Date.new(period_start.year, period_start.month + 1, start_day) - 1.day
                  end
      
      # Skip if period is already added
      next if periods.any? { |p| p[:start_date] == period_start.to_s }

      # Add period if it has expenses
      if @user.expenses.where(date: period_start..period_end).exists?
        periods << {
          start_date: period_start.to_s,
          end_date: period_end.to_s,
          display: "#{I18n.l(period_start, format: '%B %Y')}"
        }
      end
    end

    periods
  end

  def show_add_expense
    show_categories
  end

  def show_categories(message = nil)
    categories_buttons = @user.user_categories.map do |category|
      [{ text: category.display_name, callback_data: "select_category_#{category.id}" }]
    end

    text = message || translation('categories.list')
    respond_with_markdown_message(
      text:,
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
    respond_with_markdown_message(
      text: translation(text, date: user_subscription_payed_for.strftime('%d.%m.%Y')),
      reply_markup: buy_subscription_keyboard_markup
    )
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

  def show_expenses(category_id = nil, message = nil, back_to_menu: false, period_start: nil)
    expense_service = ExpenseService.new(@user)
    expenses_data = expense_service.get_expenses_report(category_id, period_start)
    text = message || expenses_data[0]
    buttons = []

    if period_start
      # For previous periods, show category totals
      categories_with_totals = @user.user_categories.map do |category|
        _, total = expense_service.get_expenses_report(category.id, period_start)
        [category, total]
      end.sort_by { |_, total| -total }

      # Add category totals to the message
      text += "\n\n"
      categories_with_totals.each do |category, total|
        text += "#{category.display_name}: #{format('%.2f', total)} #{@user.setting.currency}\n"
      end

      # Add total for all categories
      _, all_total = expense_service.get_expenses_report(nil, period_start)
      text += "\n#{translation('expenses_menu.all')}: #{format('%.2f', all_total)} #{@user.setting.currency}"
    else
      # For current period, show expense buttons
      start_date, end_date = expense_service.send(:current_period_range)
      expenses = @user.expenses
      expenses = expenses.where(user_category_id: category_id) if category_id
      expenses = expenses.where(date: start_date..end_date)
      expenses = expenses.order(date: :desc)

      context = category_id.nil? ? 'all' : category_id.to_s
      buttons = expenses.map do |expense|
        [{ text: format('%.2f', expense.amount), callback_data: "show_expense_#{expense.id}_#{context}" }]
      end
    end

    respond_with_markdown_message(
      text: text,
      reply_markup: {
        inline_keyboard: buttons + [back_button('show_expenses_menu')]
      }
    )
  end

  def show_expense(expense_id, context = nil)
    expense = @user.expenses.find(expense_id)
    text = "💰 #{format('%.2f', expense.amount)}\n📅 #{expense.date.strftime('%d.%m.%Y')}\n📝 #{expense.description}"
    
    # Получаем контекст из callback_data
    callback_data = payload&.dig('callback_query', 'data')
    context ||= callback_data&.split('_', 3)&.last
    back_callback = context == 'all' ? 'report_category_all' : "report_category_#{context}"

    respond_with_markdown_message(
      text:,
      reply_markup: {
        inline_keyboard: [
          [
            { text: '✏️', callback_data: "edit_expense_#{expense.id}_#{context}" },
            { text: '🗑️', callback_data: "delete_expense_#{expense.id}" }
          ],
          back_button(back_callback)
        ]
      }
    )
  end

  def show_main_menu(text = translation('main_menu.prompt'))
    save_context :keyboard!
    respond_with_markdown_message(text:, reply_markup: main_keyboard_markup)
  end

  def show_settings_menu(message = nil)
    save_context :keyboard!
    text = message || translation('settings.prompt')
    respond_with_markdown_message(
      text:,
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
      show_main_menu(translation('add_expense.invalid_amount'))
      return
    end

    unless amount.positive?
      show_main_menu(translation('add_expense.invalid_amount'))
      return
    end

    expense_service = ExpenseService.new(@user)
    result = expense_service.add_expense(category_id, amount, description)

    if result[:success]
      session.delete(:selected_category_id)
      show_main_menu(translation('expense_added'))
    else
      errors = result[:errors]&.join(', ') || 'Unknown error'
      show_main_menu(translation('expense_error', errors:))
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
    if emoji.match?(/\p{Emoji}/) && name.present?
      @user.user_categories.create!(name:, emoji:)
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
    session[:editing_category_id] = category_id
    save_context :edit_category_name
    respond_with_markdown_message(
      text: translation('categories.edit_name', current_name: @category.name),
      reply_markup: back_button_inline("show_expense_amount_for_category_#{category_id}")
    )
  end

  def edit_category_name(message)
    @category = @user.user_categories.find(session[:editing_category_id])
    @category.update!(name: message)
    save_context :edit_category_emoji
    respond_with_markdown_message(
      text: translation('categories.edit_emoji', current_emoji: @category.emoji),
      reply_markup: back_button_inline("edit_category_#{@category.id}")
    )
  end

  def edit_category_emoji(message)
    @category = @user.user_categories.find(session[:editing_category_id])
    emoji = message
    if emoji.match?(/\p{Emoji}/)
      @category.update!(emoji:)
      session.delete(:editing_category_id)
      show_categories(translation('categories.updated'))
    else
      respond_with_markdown_message(
        text: translation('categories.invalid_emoji'),
        reply_markup: back_button_inline("edit_category_#{@category.id}")
      )
    end
  end

  def delete_category(category_id)
    category = @user.user_categories.find(category_id)
    if category.expenses.any?
      respond_with_markdown_message(
        text: translation('categories.cannot_delete_has_expenses'),
        reply_markup: back_button_inline("show_expense_amount_for_category_#{category_id}")
      )
    else
      category.destroy!
      show_categories(translation('categories.deleted'))
    end
  end

  # Keyboard for entering amount with edit and delete category buttons
  def expense_amount_keyboard_markup(category_id)
    [
      [
        { text: '✏️', callback_data: "edit_category_#{category_id}" },
        { text: '🗑️', callback_data: "delete_category_#{category_id}" }
      ],
      back_button('show_add_expense')
    ]
  end

  def edit_expense(expense_id, context = nil)
    expense = @user.expenses.find(expense_id)
    
    # Получаем контекст из callback_data
    callback_data = payload&.dig('callback_query', 'data')
    context ||= callback_data&.split('_', 3)&.last
    back_callback = context == 'all' ? 'report_category_all' : "report_category_#{context}"

    respond_with_markdown_message(
      text: translation('expenses.edit_prompt', amount: expense.amount, description: expense.description),
      reply_markup: {
        inline_keyboard: [
          [
            { text: translation('expenses.edit_amount'), callback_data: "edit_expense_amount_#{expense_id}" },
            { text: translation('expenses.edit_description'), callback_data: "edit_expense_description_#{expense_id}" }
          ],
          back_button(back_callback)
        ]
      }
    )
  end

  def delete_expense(expense_id)
    expense = @user.expenses.find(expense_id)
    category_id = expense.user_category_id
    expense.destroy!
    # Показываем полный отчёт, но с сообщением об удалении
    expenses_data = ExpenseService.new(@user).get_expenses_report(category_id)
    text = "#{translation('expenses.deleted')}\n\n#{expenses_data[0]}"
    show_expenses(category_id, text, back_to_menu: true)
  end

  def edit_expense_amount(message, *_args)
    expense_id = session[:editing_expense_id]
    amount = message.gsub(',', '.').to_f

    if amount.positive?
      expense = @user.expenses.find(expense_id)
      expense.update!(amount:)
      session.delete(:editing_expense_id)
      expenses_data = ExpenseService.new(@user).get_expenses_report(expense.user_category_id)
      text = "#{translation('expenses.updated')}\n\n#{expenses_data[0]}"
      show_expenses(expense.user_category_id, text, back_to_menu: true)
    else
      respond_with_markdown_message(
        text: translation('add_expense.invalid_amount'),
        reply_markup: back_button_inline("edit_expense_#{expense_id}")
      )
    end
  end

  def edit_expense_description(message, *_args)
    expense_id = session[:editing_expense_id]
    expense = @user.expenses.find(expense_id)
    expense.update!(description: message)
    session.delete(:editing_expense_id)
    expenses_data = ExpenseService.new(@user).get_expenses_report(expense.user_category_id)
    text = "#{translation('expenses.updated')}\n\n#{expenses_data[0]}"
    show_expenses(expense.user_category_id, text, back_to_menu: true)
  end

  def handle_period_start_day(*)
    respond_with_markdown_message(
      text: translation('settings.period_start_day.prompt'),
      reply_markup: {
        inline_keyboard: [
          (1..7).map { |day| { text: day.to_s, callback_data: "set_period_start_day_#{day}" } },
          (8..14).map { |day| { text: day.to_s, callback_data: "set_period_start_day_#{day}" } },
          (15..21).map { |day| { text: day.to_s, callback_data: "set_period_start_day_#{day}" } },
          (22..28).map { |day| { text: day.to_s, callback_data: "set_period_start_day_#{day}" } },
          back_button('show_settings_menu')
        ]
      }
    )
  end

  # Add a new context for handling period start day input
  def period_start_day!(message, *)
    begin
      day = Integer(message)
      if day >= 1 && day <= 28
        @user.setting.update!(period_start_day: day)
        show_settings_menu(translation('settings.period_start_day.changed', day: day))
      else
        respond_with_markdown_message(
          text: translation('settings.period_start_day.invalid') + "\n\n" + translation('settings.period_start_day.prompt'),
          reply_markup: back_button_inline('show_settings_menu')
        )
      end
    rescue ArgumentError
      respond_with_markdown_message(
        text: translation('settings.period_start_day.invalid') + "\n\n" + translation('settings.period_start_day.prompt'),
        reply_markup: back_button_inline('show_settings_menu')
      )
    end
  end

  private

  def find_user
    @user = User.find_or_create_by(chat_id: chat['id']) do |user|
      user.name = chat['username']
    end

    # Get language from Telegram
    telegram_language = payload['from']['language_code']&.to_sym
    supported_language = if telegram_language && I18n.available_locales.include?(telegram_language)
                           telegram_language
                         else
                           :en
                         end

    # Create or update setting
    if @user.setting.present?
      @user.setting.update!(language: supported_language.to_s) if @user.setting.language.nil?
    else
      @user.create_setting!(language: supported_language.to_s)
    end

    @user.update(name: chat['username']) unless @user.name.present?
    I18n.locale = @user.setting.language&.to_sym || :en
  end

  def respond_with_markdown_message(params = {})
    respond_with :message, params.merge(parse_mode: 'Markdown')
  end

  def main_keyboard_markup
    expenses_button = "#{main_menu_buttons[:expenses]} #{ICONS[:money]}"
    add_expense_button = "#{main_menu_buttons[:add_expense]} #{ICONS[:credit_card]}"
    instruction_button = "#{main_menu_buttons[:instruction]} #{ICONS[:instruction]}"
    settings_button = "#{main_menu_buttons[:settings]} #{ICONS[:settings]}"
    subscription_button = "#{main_menu_buttons[:buy_subscription]} #{ICONS[:credit_card]}"

    buttons = []
    buttons << if @user.setting.active?
                 [add_expense_button, expenses_button]
               else
                 [expenses_button]
               end
    buttons << [settings_button, instruction_button]
    buttons << [subscription_button]

    {
      keyboard: buttons,
      resize_keyboard: true,
      one_time_keyboard: true,
      selective: true
    }
  end

  def expenses_menu_keyboard_markup
    expense_service = ExpenseService.new(@user)
    categories_with_totals = @user.user_categories.map do |category|
      _, total = expense_service.get_expenses_report(category.id)
      [category, total]
    end.sort_by { |_, total| -total }.map do |category, total|
      {
        text: "#{category.display_name} - #{format('%.2f', total)} #{@user.setting.currency}",
        callback_data: "report_category_#{category.id}"
      }
    end

    _, all_total = expense_service.get_expenses_report
    all_expenses_button = {
      text: "#{ICONS[:list]} #{translation('expenses_menu.all')} - #{format('%.2f',
                                                                            all_total)} #{@user.setting.currency}",
      callback_data: 'report_category_all'
    }

    {
      inline_keyboard: [
        *categories_with_totals.map { |cat| [{ text: cat[:text], callback_data: cat[:callback_data] }] },
        [all_expenses_button],
        [{ text: translation('expenses_menu.previous_periods'), callback_data: 'show_periods_menu' }],
        back_button('keyboard!')
      ]
    }
  end

  def back_button_inline(callback_data = 'keyboard!')
    { inline_keyboard: [back_button(callback_data)] }
  end

  def back_button(callback_data = 'keyboard!', arg = nil)
    data = arg ? "#{callback_data}_#{arg}" : callback_data
    [{ text: "#{translation('back_button')}  #{ICONS[:back_arrow]}", callback_data: data }]
  end

  def main_menu_buttons
    {
      expenses: translation('main_menu.buttons.expenses'),
      add_expense: translation('main_menu.buttons.add_expense'),
      instruction: translation('main_menu.buttons.instruction'),
      settings: translation('main_menu.buttons.settings'),
      buy_subscription: translation('main_menu.buttons.buy_subscription')
    }
  end

  def translation(path, params = {})
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
          { text: translation('settings.currency.current', currency: @user.setting.currency),
            callback_data: 'change_currency' }
        ],
        [
          { text: translation('settings.language.current', language: @user.setting.language || 'en'),
            callback_data: 'show_language_info' }
        ],
        [
          { text: translation('settings.period_start_day.current', day: @user.setting.period_start_day),
            callback_data: 'change_period_start_day' }
        ],
        back_button('keyboard!')
      ]
    }
  end

  def buy_subscription_keyboard_markup
    {
      inline_keyboard: [
        back_button('keyboard!')
      ]
    }
  end
end
