class CreateUserCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :user_categories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :emoji, null: false
      t.timestamps
    end

    add_index :user_categories, [:user_id, :name], unique: true
  end
end 