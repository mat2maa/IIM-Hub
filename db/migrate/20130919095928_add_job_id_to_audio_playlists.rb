class AddJobIdToAudioPlaylists < ActiveRecord::Migration
  def self.up
    add_column :audio_playlists, :job_id, :integer
    add_column :audio_playlists, :job_finished_at, :datetime
    add_column :audio_playlists, :job_current_track, :integer
    add_column :audio_playlists, :job_current_progress, :integer
    add_column :audio_playlists, :job_total_tracks, :integer
  end

  def self.down
    remove_column :audio_playlists, :job_id
    remove_column :audio_playlists, :job_finished_at
    remove_column :audio_playlists, :job_current_track
    remove_column :audio_playlists, :job_current_progress
    remove_column :audio_playlists, :job_total_tracks
  end
end
