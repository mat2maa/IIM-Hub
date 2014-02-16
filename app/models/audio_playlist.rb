class AudioPlaylist < ActiveRecord::Base

  # mount_uploader :audio_playlist_zip, AudioPlaylistZipUploader

  has_many :audio_playlist_tracks, :dependent => :destroy
  has_many :tracks, :through => :audio_playlist_tracks

  belongs_to :program  
  belongs_to :vo  
  belongs_to :airline
  belongs_to :user

  attr_accessible :client_playlist_code, :airline_id, :program_id, :in_out, :vo_id, :start_playdate,
                  :start_playdate, :start_playdate, :end_playdate, :end_playdate, :end_playdate, :airline_duration,
                  :vo, :user_id, :airline_cache, :program_cache, :job_id, :job_finished_at, :job_current_track,
                  :job_current_progress, :job_total_tracks

	def audio_playlist_tracks_sorted
		#self.audio_playlist_tracks.sort_by {|a| [a.position]}
    AudioPlaylistTrack.includes(:track, {:track=>:album},{:track=>{:album=>:label}})
                      .where({:audio_playlist_id => self.id})
                      .order(:position)
	end
	
  def total_duration_cached
    Rails.cache.fetch('AudioPlaylist.'+self.id.to_s+'.total_duration' + self.updated_at.strftime('%Y%m%d%H%M%S')){duration_from_sec total_duration}
  end


  def total_duration
    t = 0
    
  	self.audio_playlist_tracks.each do |audio_playlist_track|
			if audio_playlist_track.track.nil?
				 t+=0
			else
				t += audio_playlist_track.track.duration/1000
				t += audio_playlist_track.vo_duration.to_i if !audio_playlist_track.vo_duration.nil?			
			end
  	end

  	#duration_from_sec t
  	t
    
  end
  
  def duration_from_sec sec
    if !sec.nil?
  	
      min = sec/60
  
      sec = sec%60

      if  sec < 10  then   sec = "0#{sec}"
      end 
      if  sec == 0  then   sec = "00"
      end
      if  min == 0  then   min = "0"
      end

      t = "#{min}:#{sec}"
    else 
      t = "0:00"
    end
    t
  end

  def self.download_playlist(id)
    find(id).download_playlist
  end

  def download_playlist
    job = Delayed::Job.enqueue(DownloadAudioPlaylist.new(audio_playlist_id: id))
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
