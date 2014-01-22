class AddAlbumZipToAlbum < ActiveRecord::Migration
  def change
    add_column :albums, :album_zip, :string
  end
end
