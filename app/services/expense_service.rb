# frozen_string_literal: true

class ExpenseService
  def initialize(user)
    @user = user
  end

  def add_expense(category_id, amount, description, date = Date.current)
    expense = @user.expenses.new(
      amount:,
      description:,
      user_category_id: category_id,
      date:
    )
    if expense.save
      { success: true, expense: }
    else
      { success: false, errors: expense.errors.full_messages }
    end
  end

  def get_expenses_report(category_id = nil, period_start = nil)
    start_date, end_date = if period_start
                            [period_start, period_start.next_month - 1.day]
                          else
                            current_period_range
                          end

    expenses = @user.expenses
                    .between_dates(start_date, end_date)
    expenses = expenses.for_category(category_id) if category_id

    total = expenses.total_amount
    message = format_report_message(expenses, category_id, total, start_date, end_date)
    [message, total]
  end

  def period_range_for(date)
    start_day = @user.setting.period_start_day || 1
    if date.day >= start_day
      period_start = Date.new(date.year, date.month, start_day)
    else
      prev_month = date.prev_month
      period_start = Date.new(prev_month.year, prev_month.month, start_day)
    end

    period_end = if period_start.month == 12
                  Date.new(period_start.year + 1, 1, start_day) - 1.day
                else
                  Date.new(period_start.year, period_start.month + 1, start_day) - 1.day
                end
    [period_start, period_end]
  end

  def current_period_range
    period_range_for(Date.current)
  end

  private

  def format_expense_message(expense)
    category = expense.user_category
    I18n.t('telegram_webhooks.expenses.added',
           amount: format_amount(expense.amount),
           category: category ? category.display_name : I18n.t('telegram_webhooks.expenses.no_category'),
           description: expense.description)
  end

  def format_report_message(expenses, category_id, total, start_date = Date.current.beginning_of_month,
                            end_date = Date.current.end_of_month)
    message = []

    # Header section
    category = category_id ? @user.user_categories.find(category_id) : nil
    message << "*#{category ? category.display_name : I18n.t('telegram_webhooks.expenses.report.all_categories')}*"
    message << I18n.t('telegram_webhooks.expenses.report.period',
                      start_date: start_date.strftime('%d.%m.%Y'),
                      end_date: end_date.strftime('%d.%m.%Y'))
    
    # Only show total if we're showing a specific category
    if category_id
      message << I18n.t('telegram_webhooks.expenses.report.total', amount: format_amount(total),
                                                                   currency: @user.setting.currency)
    end
    message << ''

    message << I18n.t('telegram_webhooks.expenses.report.no_expenses') unless expenses.any?

    message.join("\n")
  end

  def format_amount(amount)
    format('%.2f', amount)
  end
end
