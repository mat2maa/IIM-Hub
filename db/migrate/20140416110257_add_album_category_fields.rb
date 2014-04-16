class AddAlbumCategoryFields < ActiveRecord::Migration
  def change
    add_column :albums, :album_category_id, :integer
    add_column :albums, :album_category_auto_increment, :integer, limit: 8
  end
end
