class VideoMasterPlaylist < ActiveRecord::Base
  include Iim
  
  has_many :video_master_playlist_items, :dependent => :destroy
  has_many :masters, :through => :video_master_playlist_items, :order => "position"
  belongs_to :master_playlist_type
  belongs_to :airline
  belongs_to :user
  
  scope :with_same_airline_and_master, lambda { |video_master_id, airline_id| {
    :select=>"video_master_playlists.id, video_master_playlists.airline_id, video_master_playlists.start_cycle", 
    :conditions=>"video_master_playlist_items.master_id=#{video_master_id} AND video_master_playlists.airline_id='#{airline_id}'",
    :joins=>"LEFT JOIN video_master_playlist_items on video_master_playlists.id=video_master_playlist_items.video_master_playlist_id"} }

  attr_accessible :airline_id, :start_cycle, :end_cycle, :master_playlist_type_id,
      :edit_runtime, :media_instruction, :user_id
  
  def total_runtime
    total = 0
    self.masters.each do |master|
      total += master.duration_in_seconds
    end
    convert_seconds_to_timecode(total)
  end
  
  def video_master_playlist_items_sorted
    return VideoMasterPlaylistItem.where(:video_master_playlist_id => self.id).order(:position)
	end
end
