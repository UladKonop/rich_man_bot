class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :user_category, null: true, foreign_key: true
      t.decimal :amount, null: false, precision: 10, scale: 2
      t.text :description
      t.date :date, null: false
      t.timestamps
    end

    add_index :expenses, :date
  end
end 