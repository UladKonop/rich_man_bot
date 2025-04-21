class ExpenseService
  def initialize(user)
    @user = user
  end

  def add_expense(category_id, amount, description = nil, date = Date.current)
    expense = @user.expenses.build(
      category_id: category_id,
      amount: amount,
      description: description,
      date: date
    )

    if expense.save
      { success: true, expense: expense }
    else
      { success: false, errors: expense.errors.full_messages }
    end
  end

  def get_expenses(category_id = nil)
    expenses = @user.expenses_by_category(category_id)
    total = @user.total_expenses(category_id)

    {
      expenses: expenses,
      total: total,
      category: category_id ? Category.find_by(id: category_id) : nil
    }
  end

  def format_expenses_report(expenses_data)
    expenses = expenses_data[:expenses]
    total = expenses_data[:total]
    category = expenses_data[:category]
    currency = @user.setting.currency
    current_month = I18n.l(Date.current, format: '%B %Y')

    message = []
    message << "*#{category ? category.display_name : I18n.t('telegram_webhooks.expenses.report.all_categories')}*"
    message << "*#{current_month}*"
    message << ""

    if expenses.any?
      expenses.each do |expense|
        message << I18n.t('telegram_webhooks.expenses.report.expense.amount', amount: expense.amount, currency: currency)
        message << I18n.t('telegram_webhooks.expenses.report.expense.date', date: I18n.l(expense.date, format: '%d.%m.%Y'))
        message << I18n.t('telegram_webhooks.expenses.report.expense.description', text: expense.description) if expense.description.present?
        message << I18n.t('telegram_webhooks.expenses.report.expense.separator')
      end
    else
      message << I18n.t('telegram_webhooks.expenses.report.no_expenses')
    end

    message << ""
    message << "*#{I18n.t('telegram_webhooks.expenses.report.total', amount: total, currency: currency)}*"

    message.join("\n")
  end
end 