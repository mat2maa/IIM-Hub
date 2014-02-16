class AlbumPlaylist < ActiveRecord::Base

  # mount_uploader :album_playlist_zip, AlbumPlaylistZipUploader

  has_many :album_playlist_items, :dependent => :destroy
  has_many :albums, :through => :album_playlist_items
  
  belongs_to :program
  belongs_to :airline
  belongs_to :user
	
	def album_playlist_items_sorted
		#self.album_playlist_items.sort_by {|a| [a.position, a]}
    return AlbumPlaylistItem.where(:album_playlist_id => self.id).order(:position)
	end
	
  attr_accessible :client_playlist_code, :in_out, :start_playdate, :start_playdate, :start_playdate, :end_playdate,
                  :end_playdate, :end_playdate, :airline_id, :job_id, :job_finished_at, :job_current_track,
                  :job_current_progress, :job_total_tracks

  def self.download_playlist(id)
    find(id).download_playlist
  end

  def download_playlist
    job = Delayed::Job.enqueue(DownloadAlbumPlaylist.new(album_playlist_id: id))
    update_attribute(:job_id, job.id)
  end

  def working?
    job_id.present?
  end

  def finished?
    job_finished_at.present?
  end

  def progress
    job_current_progress
  end

  def current_track
    job_current_track
  end

end
