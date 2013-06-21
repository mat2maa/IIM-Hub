class AddChineseFieldsToVideos < ActiveRecord::Migration
  def change
    add_column :videos, :chinese_programme_title, :string
    add_column :videos, :chinese_synopsis, :text
  end
end
