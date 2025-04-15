class CreatePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :payments do |t|
      t.references :subscription, foreign_key: true
      t.boolean :used, default: false
      t.boolean :accepted
      t.decimal :amount
      t.string :subscription_type
      t.jsonb :parameters

      t.timestamps
    end
  end
end
