class AddAudioPlaylistZipToAudioPlaylist < ActiveRecord::Migration
  def change
    add_column :audio_playlists, :audio_playlist_zip, :string
  end
end
