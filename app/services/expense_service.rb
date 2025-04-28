class ExpenseService
  def initialize(user)
    @user = user
  end

  def add_expense(category_id, amount, description, date = Date.current)
    expense = @user.expenses.new(
      amount: amount,
      description: description,
      user_category_id: category_id,
      date: date
    )
    if expense.save
      { success: true, expense: expense }
    else
      { success: false, errors: expense.errors.full_messages }
    end
  end

  def get_expenses_report(category_id = nil, start_date = Date.current.beginning_of_month, end_date = Date.current.end_of_month)
    expenses = @user.expenses
                    .between_dates(start_date, end_date)
    expenses = expenses.for_category(category_id) if category_id

    total = expenses.total_amount
    message = format_report_message(expenses, category_id, total, start_date, end_date)
    [message, total]
  end

  private

  def format_expense_message(expense)
    category = expense.user_category
    I18n.t('telegram_webhooks.expenses.added',
           amount: format_amount(expense.amount),
           category: category ? category.display_name : I18n.t('telegram_webhooks.expenses.no_category'),
           description: expense.description)
  end

  def format_report_message(expenses, category_id, total, start_date = Date.current.beginning_of_month, end_date = Date.current.end_of_month)
    category = category_id ? @user.user_categories.find_by(id: category_id) : nil
    message = []
    
    # Header section
    message << "*#{category ? category.display_name : I18n.t('telegram_webhooks.expenses.report.all_categories')}*"
    message << I18n.t('telegram_webhooks.expenses.report.period',
                     start_date: start_date.strftime('%d.%m.%Y'),
                     end_date: end_date.strftime('%d.%m.%Y'))
    message << I18n.t('telegram_webhooks.expenses.report.total', amount: format_amount(total), currency: @user.setting.currency)
    message << ""

    # Expenses section
    if expenses.any?
      expenses.order(date: :desc).each do |expense|
        message << I18n.t('telegram_webhooks.expenses.report.expense.amount', amount: format_amount(expense.amount), currency: @user.setting.currency)
        message << I18n.t('telegram_webhooks.expenses.report.expense.date', date: expense.date.strftime('%d.%m.%Y'))
        message << I18n.t('telegram_webhooks.expenses.report.expense.description', text: expense.description) if expense.description.present?
        message << I18n.t('telegram_webhooks.expenses.report.expense.separator')
      end
    else
      message << I18n.t('telegram_webhooks.expenses.report.no_expenses')
    end

    message.join("\n")
  end

  def format_amount(amount)
    format('%.2f', amount)
  end
end
