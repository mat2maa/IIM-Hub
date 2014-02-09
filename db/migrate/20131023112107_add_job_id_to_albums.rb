class AddJobIdToAlbums < ActiveRecord::Migration
  def self.up
    add_column :albums, :job_id, :integer
    add_column :albums, :job_finished_at, :datetime
    add_column :albums, :job_current_track, :integer
    add_column :albums, :job_current_progress, :integer
    add_column :albums, :job_total_tracks, :integer
  end

  def self.down
    remove_column :albums, :job_id
    remove_column :albums, :job_finished_at
    remove_column :albums, :job_current_track
    remove_column :albums, :job_current_progress
    remove_column :albums, :job_total_tracks
  end
end
