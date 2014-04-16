class Album < ActiveRecord::Base

  mount_uploader :album_zip, AlbumZipUploader

  has_many :tracks, :dependent => :destroy
  belongs_to :label
  belongs_to :publisher
  belongs_to :language
  belongs_to :album_category
  has_many :album_playlist_items
  has_many :album_playlists, :through => :album_playlist_items
  has_many :audio_playlist_tracks, :through => :tracks

  has_and_belongs_to_many :genres

  validates_presence_of :title_original, :artist_original, :label_id, :publisher_id, :release_year, :gender, :language_id, :disc_num, :disc_count, :cd_code

  searchable_by :title_original, :title_english, :artist_original, :artist_english, :cd_code

  has_attached_file :cover,
                    styles: {
                        small: "50x50>",
                        medium: "100x100>",
                        large: "300x300>"},
                    url: "/s3_assets/system/covers/:id/:style/:basename.:extension",
                    default_url: "/assets/:attachment/missing_:style.png",
                    remote: true

  validates_attachment_size :cover, :less_than => 5.megabytes
  validates_attachment_content_type :cover, :content_type => ['image/jpeg', 'image/png', 'image/gif']

  attr_accessible :title_original, :label_id, :title_english, :release_year, :artist_original, :publisher_id,
                  :artist_english, :disc_num, :disc_count, :cd_code, :live_album, :explicit_lyrics, :cover, :cover_remote_url, :gender,
                  :language_id, :compilation, :origin_id, :synopsis, :genre_ids, :cover, :tracks_attributes,
                  :to_delete, :mp3_exists, :job_id, :job_finished_at, :job_current_track,
                  :job_current_progress, :job_total_tracks, :album_category_id, :album_category_auto_increment

  accepts_nested_attributes_for :tracks

  def tracks_sorted
    self.tracks.sort_by { |a| [a.track_num] }
  end

  def duration
    t = 0

    self.tracks.each do |track|
      if !track.duration.nil?
        t += track.duration
      else
        t += 0
      end
    end
    t
  end

  def duration_in_min

    if !self.total_duration.nil?
      sec = self.total_duration/1000

      min = sec/60

      sec = sec%60

      if  sec < 10 then
        sec = "0#{sec}"
      end
      if  sec == 0 then
        sec = "00"
      end
      if  min == 0 then
        min = "0"
      end

      t = "#{min}:#{sec}"
    else
      t = "0:00"
    end
    t
  end

  def self.delete_album(id)
    Delayed::Job.enqueue(DeleteAlbum.new(album_id: id))
  end

  def self.download_playlist(id)
    find(id).download_playlist
  end

  def download_playlist
    job = Delayed::Job.enqueue(DownloadAlbum.new(album_id: id))
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
