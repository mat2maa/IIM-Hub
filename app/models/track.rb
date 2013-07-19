class Track < ActiveRecord::Base
  belongs_to :album, :counter_cache => true
  has_many :audio_playlists, :through => :audio_playlist_tracks
  has_many :audio_playlist_tracks
  has_and_belongs_to_many :genres
  belongs_to :language
  belongs_to :origin
  
  validates_presence_of :title_original, :artist_original, :gender, :language_id
  	
  searchable_by :title_original, :title_english, :artist_original, :artist_english, :composer
  
  attr_accessible :title_original, :title_english, :tempo, :artist_original, :tempo_intro, :artist_english,
                  :tempo_outro, :composer, :gender, :distributor, :language_id, :origin_id, :explicit_lyrics,
                  :album_id, :genre_ids, :lyrics, :track_num, :duration

  scope :greater_than_dur_min, -> dur_min {
    where("duration > ?", dur_min)
  }

  scope :less_than_dur_max, -> dur_max {
    where("duration < ?", dur_max)
  }

  def label_cached
    Rails.cache.fetch('Track.label'+ self.id.to_s) { self.album.label.name }
  end
  
  def duration_in_min 
    if !self.duration.nil?
	  
	    sec = self.duration/1000
	
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
end
