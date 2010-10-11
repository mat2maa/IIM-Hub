class VideoMasterPlaylist < ActiveRecord::Base
  has_many :video_master_playlist_items, :dependent => :destroy
  has_many :masters, :through => :video_master_playlist_items, :order => "position"
  belongs_to :master_playlist_type
  
  belongs_to :airline
  belongs_to :user
  
  def video_master_playlist_items_sorted
    return VideoMasterPlaylistItem.find(:all, :conditions=>{:video_master_playlist_id => self.id}, :order_by=>:position)
	end
end
