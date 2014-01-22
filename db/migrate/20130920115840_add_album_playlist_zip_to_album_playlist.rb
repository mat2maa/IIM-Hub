class AddAlbumPlaylistZipToAlbumPlaylist < ActiveRecord::Migration
  def change
    add_column :album_playlists, :album_playlist_zip, :string
  end
end
