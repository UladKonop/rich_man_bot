class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name
      t.bigint :chat_id

      t.timestamps
    end
  end
end
