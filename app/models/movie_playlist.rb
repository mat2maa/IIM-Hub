class MoviePlaylist < ActiveRecord::Base
  has_many :movie_playlist_items, :dependent => :destroy
  has_many :movies, :through => :movie_playlist_items, :order => "position"

  belongs_to :airline
  belongs_to :user
  
  named_scope :with_same_airline_and_movie, lambda { |movie_id, airline_id| {
    :select=>"movie_playlists.id", 
    :conditions=>"movie_playlist_items.movie_id=#{movie_id} AND movie_playlists.airline_id='#{airline_id}'",
    :joins=>"LEFT JOIN movie_playlist_items on movie_playlists.id=movie_playlist_items.movie_playlist_id"} }
  
  def movie_playlist_items_sorted
    return MoviePlaylistItem.find(:all, :conditions=>{:movie_playlist_id => self.id}, :order_by=>:position)
	end
  
end
