class CreateAlbumCategories < ActiveRecord::Migration
  def change
    create_table :album_categories do |t|
      t.string :name
      t.string :code

      t.timestamps
    end
  end
end
