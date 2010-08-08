class Movie < ActiveRecord::Base
  
  #cattr_reader :per_page
  #@@per_page = 50
  
  validates_presence_of :movie_title, :movie_type, :rating
          
  validates_numericality_of :poster_quantity
  
  has_many :movie_playlist_items , :dependent => :destroy
  has_many :movie_playlists, :through=>:movie_playlist_items

  belongs_to :movie_distributor, :class_name => "Supplier", :foreign_key => "movie_distributor_id"
  belongs_to :laboratory, :class_name => "Supplier", :foreign_key => "laboratory_id"
  belongs_to :production_studio, :class_name => "Supplier", :foreign_key => "production_studio_id"

  has_and_belongs_to_many :airline_rights_countries
  has_and_belongs_to_many :movie_genres
    
  has_attached_file :poster, :styles => { 
                    :small => "160x237>",
                    :medium => "250x250>",
                    :large => "500x500>"},
                    :url  => "/system/posters/:id/:style/:id.:extension",
                    :path => ":rails_root/public/system/posters/:id/:style/:id.:extension",
                    :default_url => "/images/:attachment/missing_:style.png"

  validates_numericality_of :theatrical_runtime, :edited_runtime, :allow_nil => true
  validates_length_of :theatrical_runtime, :edited_runtime, :in => 0..999, :allow_nil => true
  
  #validates_attachment_presence :poster
  validates_attachment_size :poster, :less_than => 5.megabytes
  validates_attachment_content_type :poster, :content_type => ['image/jpeg', 'image/png']
  
  named_scope :with_release_version, lambda { |release_version| {:conditions => "release_versions_mask & #{2**RELEASE_VERSIONS.index(release_version.to_s)} > 0"} }
  
  RELEASE_VERSIONS = ["Th", "Ed", "M1", "M2", "W2", "M4", "W4"]
  
  def before_save
    self.synopsis = self.synopsis.gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ').strip.gsub(/(\.\s{2,})/, '. ').strip      
    self.cast = self.cast.gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ').strip.gsub(/(\.\s{2,})/, '. ').strip    
    self.director = self.director.gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ').strip.gsub(/(\.\s{2,})/, '. ').strip
  end
  
  def movie_genres_string
    genres = self.movie_genres.collect{|genre| genre.name}
    genres.join(', ')
  end

  def release_versions=(release_versions)
    self.release_versions_mask = (release_versions & RELEASE_VERSIONS).map { |r| 2**RELEASE_VERSIONS.index(r) }.sum
  end
  
  def release_versions
    RELEASE_VERSIONS.reject { |r| ((release_versions_mask || 0) & 2**RELEASE_VERSIONS.index(r)).zero? }
  end
  
  def release_version_symbols
    release_versions.map(&:to_sym)
  end
  
  named_scope :with_screener_remark, lambda { |screener_remark| {:conditions => "screener_remarks_mask & #{2**SCREENER_REMARKS.index(screener_remark.to_s)} > 0"} }
  
  SCREENER_REMARKS = ["VHS", "VHS B&W", "VHS Chinese Subs", "DVD B&W", "DVD Chinese Subs", "Other"]
  
  def screener_remarks=(screener_remarks)
    self.screener_remarks_mask = (screener_remarks & SCREENER_REMARKS).map { |r| 2**SCREENER_REMARKS.index(r) }.sum
  end
  
  def screener_remarks
    SCREENER_REMARKS.reject { |r| ((screener_remarks_mask || 0) & 2**SCREENER_REMARKS.index(r)).zero? }
  end
  
  def screener_remark_symbols
    screener_remarks.map(&:to_sym)
  end
  
  named_scope :with_language_track, lambda { |language_track| {:conditions => "language_tracks_mask & #{2**IIM::MOVIE_LANGUAGES.index(language_track.to_s)} > 0"} }
    
  def language_tracks=(language_tracks)
    self.language_tracks_mask = (language_tracks & IIM::MOVIE_LANGUAGES).map { |r| 2**IIM::MOVIE_LANGUAGES.index(r) }.sum
  end
  
  def language_tracks
    IIM::MOVIE_LANGUAGES.reject { |r| ((language_tracks_mask || 0) & 2**IIM::MOVIE_LANGUAGES.index(r)).zero? }
  end
  
  def language_track_symbols
    language_tracks.map(&:to_sym)
  end
  
  named_scope :with_language_subtitle, lambda { |language_subtitle| {:conditions => "language_subtitles_mask & #{2**IIM::MOVIE_LANGUAGES.index(language_subtitle.to_s)} > 0"} }
    
  def language_subtitles=(language_subtitles)
    self.language_subtitles_mask = (language_subtitles & IIM::MOVIE_LANGUAGES).map { |r| 2**IIM::MOVIE_LANGUAGES.index(r) }.sum
  end
  
  def language_subtitles
    IIM::MOVIE_LANGUAGES.reject { |r| ((language_subtitles_mask || 0) & 2**IIM::MOVIE_LANGUAGES.index(r)).zero? }
  end
  
  def language_subtitle_symbols
    language_subtitles.map(&:to_sym)
  end
  
 
  
end
