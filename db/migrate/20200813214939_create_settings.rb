class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.references :user

      t.timestamps
    end
  end
end
