class ChangeKeywordsToBeArrayInSettings < ActiveRecord::Migration[7.1]
  def change
    change_column :settings, :keywords, :string, array: true, default: [], using: "(string_to_array(keywords, ','))"
  end
end
