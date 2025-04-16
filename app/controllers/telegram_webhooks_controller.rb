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
      show_expenses_menu if main_menu_buttons[:expenses].include?(value)
      show_add_expense if main_menu_buttons[:add_expense].include?(value)
      show_instruction if main_menu_buttons[:instruction].include?(value)
      show_settings_menu if main_menu_buttons[:settings].include?(value)
      # buy_subscription if main_menu_buttons[:buy_subscription].include?(value)
      show_instruction if main_menu_buttons[:instruction].include?(value)
    else
      show_main_menu
    end
  end

  def hhh!(*)
    binding.pry if Rails.env.development?
  end

  def message(message)
    if session[:context] == :add_expense
      handle_add_expense(message.text)
    else
      show_main_menu
    end
  end

  def callback_query(action)
    if action.start_with?('category_')
      category_id = action.split('_').last
      category_id = category_id == 'all' ? nil : category_id.to_i
      show_expenses_for_category(category_id)
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
    save_context :add_expense
    respond_with_markdown_message(
      text: translation('add_expense.prompt'),
      reply_markup: back_button_inline('keyboard!')
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
    respond_with_markdown_message(
      text: translation('instruction.main'),
      reply_markup: main_keyboard_markup
    )
  end

  def add_expense(*)
    handle_add_expense(payload['text'])
  end

  def handle_add_expense(text)
    # Формат: сумма категория описание
    parts = text.split(' ', 3)
    amount = parts[0].to_f
    category_name = parts[1]
    description = parts[2]

    category = Category.find_by('lower(name) = ?', category_name.downcase)
    
    if category && amount > 0
      expense_service = ExpenseService.new(@user)
      result = expense_service.add_expense(category.id, amount, description)
      
      if result[:success]
        show_main_menu(translation('expense_added'))
      else
        show_main_menu(translation('expense_error', errors: result[:errors].join(', ')))
      end
    else
      show_main_menu(translation('invalid_expense_format'))
    end
  end

  private

  def find_user
    @user = User.find_or_create_by(chat_id: chat['id'])
    @user.update(name: chat['username']) unless @user.name.present?
  end

  def respond_with_markdown_message(params = {})     
    respond_with :message, params.merge(parse_mode: 'Markdown')
  end

  def main_keyboard_markup
    expenses_button = "#{main_menu_buttons[:expenses]} #{ICONS[:money]}"
    add_expense_button = "#{main_menu_buttons[:add_expense]} #{ICONS[:credit_card]}"
    instruction_button = "#{main_menu_buttons[:instruction]} #{ICONS[:instruction]}"

    buttons = [[expenses_button, add_expense_button], [instruction_button]]
    {
      keyboard: buttons,
      resize_keyboard: true,
      one_time_keyboard: true,
      selective: true
    }
  end

  def expenses_menu_keyboard_markup
    categories_buttons = Category.ordered.map do |category|
      { text: "#{category.icon} #{category.name}", callback_data: "category_#{category.id}" }
    end

    all_expenses_button = { text: "#{ICONS[:list]} Все расходы", callback_data: "category_all" }

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

  def save_context(context)
    session[:context] = context
  end
end
