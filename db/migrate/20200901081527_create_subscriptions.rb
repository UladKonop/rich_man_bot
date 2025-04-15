class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions do |t|
      t.references :user, foreign_key: true
      t.datetime :payed_for

      t.timestamps
    end
  end
end
