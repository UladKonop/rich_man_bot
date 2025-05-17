class AddPeriodStartDayToSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :period_start_day, :integer, null: false, default: 1
  end
end
