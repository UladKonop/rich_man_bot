class AddActiveToSetting < ActiveRecord::Migration[7.1]
  def change
    add_column :settings, :active, :boolean, default: true
  end
end
