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

    message = []
    message << "*#{category ? category.name : 'Все категории'}*"
    message << ""

    if expenses.any?
      expenses.each do |expense|
        message << "💰 #{expense.amount} #{currency}"
        message << "📅 #{expense.date.strftime('%d.%m.%Y')}"
        message << "📝 #{expense.description}" if expense.description.present?
        message << "---"
      end
    else
      message << "Нет расходов"
    end

    message << ""
    message << "*Итого: #{total} #{currency}*"

    message.join("\n")
  end
end 