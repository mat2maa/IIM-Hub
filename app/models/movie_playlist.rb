class MoviePlaylist < ActiveRecord::Base
  has_many :movie_playlist_items, :dependent => :destroy
  has_many :movies, :through => :movie_playlist_items, :order => "position"

  belongs_to :airline
  belongs_to :user
  belongs_to :movie_playlist_type, :class_name => "MoviePlaylistType", :foreign_key => "movie_playlist_type_id"

  scope :with_same_airline_and_movie, lambda { |movie_id, airline_id| {
    :select=>"movie_playlists.id, movie_playlists.airline_id, movie_playlists.start_cycle", 
    :conditions=>"movie_playlist_items.movie_id=#{movie_id} AND movie_playlists.airline_id='#{airline_id}'",
    :joins=>"LEFT JOIN movie_playlist_items on movie_playlists.id=movie_playlist_items.movie_playlist_id"} }

  attr_accessible :airline_id, :start_cycle, :end_cycle, :movie_playlist_type_id, :user_id

  def movie_playlist_items_sorted
    return MoviePlaylistItem.where(:movie_playlist_id => self.id)
                            .order("position ASC")
	end
	
	def movies_already_programmed(movie_id)
	  MoviePlaylist.with_same_airline_and_movie(movie_id, airline_id)
	end

  scope :with_language_track, -> language_track {
    where("language_tracks like ?", "%#{language_track}%")
  }

  scope :with_language_subtitle, -> language_subtitle {
    where("language_subtitles like ?", "%#{language_subtitle}%")
  }

  scope :with_screener_destroyed,
        where("screener_destroyed_date <> 'NULL'")

  scope :with_screener_held,
        where("screener_received_date <> 'NULL'")

end
