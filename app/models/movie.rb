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
  belongs_to :movie_type, :class_name => "MovieType", :foreign_key => "movie_type_id"

  has_and_belongs_to_many :airline_rights_countries
  has_and_belongs_to_many :movie_genres

  attr_accessible :movie_title, :movie_type_id, :movie_distributor_id, :production_studio_id, :laboratory_id,
                  :airline_release_date, :personal_video_date, :theatrical_release_year, :screener_received_date,
                  :screener_destroyed_date, :has_press_kit, :has_poster, :poster_quantity, :rating,
                  :theatrical_runtime, :edited_runtime, :release_versions, :screener_remarks, :airline_rights,
                  :language_tracks, :language_subtitles, :movie_genre_ids, :cast, :director, :synopsis, 
                  :critics_review, :remarks, :chinese_movie_title, :chinese_cast, :chinese_director,
                  :chinese_synopsis, :imdb_synopsis, :foreign_language_title, :airline_countries, :poster, :gapp_number
    
  has_attached_file :poster,
                    styles: { 
                      small: "160x237>",
                      medium: "250x250>",
                      large: "500x500>" },
                    url: "s3_domain_url",
                    path: "/system/posters/:id/:style/:id.:extension",
                    default_url: "/assets/:attachment/missing_:style.png"

  validates_numericality_of :theatrical_runtime, :edited_runtime, :allow_nil => true
  validates_length_of :theatrical_runtime, :edited_runtime, :in => 0..999, :allow_nil => true
  
  #validates_attachment_presence :poster
  validates_attachment_size :poster, :less_than => 5.megabytes
  validates_attachment_content_type :poster, :content_type => ['image/jpeg', 'image/png']
  
  scope :with_release_version, lambda { |release_version| {:conditions => "release_versions_mask & #{2**RELEASE_VERSIONS.index(release_version.to_s)} > 0"} }
  
  RELEASE_VERSIONS = ["Th", "Ed", "M1", "M2", "W2", "M4", "W4"]
  
  serialize   :language_tracks
  serialize   :language_subtitles

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
  
  before_save :meta_tidy

  def meta_tidy

    self.language_tracks = nil if self.language_tracks.class == String
    self.language_subtitles = nil if self.language_subtitles.class == String

    self.language_tracks = self.language_tracks.delete_if{|x| x == "" }  unless self.language_tracks.nil?
    self.language_subtitles = self.language_subtitles.delete_if{|x| x == "" }  unless self.language_subtitles.nil?
        
    
    # if production studio is empty, set it to the same as movie distributor supplier
    if production_studio_id.nil? && !movie_distributor_id.nil?
      count_suppliers = SupplierCategory.joins(:suppliers)
                                        .where(["supplier_id = ? and supplier_categories.name = ? ", movie_distributor_id, "Production Studios"])
                                        .count('supplier_id')
      self.production_studio_id = movie_distributor_id if !count_suppliers.zero?
    end
    
    if laboratory_id.nil? && !movie_distributor_id.nil?
      count_suppliers = SupplierCategory.joins(:suppliers)
                                        .where(["supplier_id = ? and supplier_categories.name = ? ", movie_distributor_id, "Laboratories"])
                                        .count('supplier_id')
      self.laboratory_id = movie_distributor_id if !count_suppliers.zero?
    end
    
    self.synopsis = self.synopsis
                        .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                        .strip
                        .gsub(/(\.\s{2,})/, '. ')
                        .strip if self.synopsis.present?
    self.cast = self.cast
                    .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                    .strip
                    .gsub(/(\.\s{2,})/, '. ')
                    .strip if self.cast.present?
    self.director = self.director
                        .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                        .strip
                        .gsub(/(\.\s{2,})/, '. ')
                        .strip if self.director.present?

    self.chinese_synopsis = self.chinese_synopsis
                                .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                                .strip
                                .gsub(/(\.\s{2,})/, '. ')
                                .strip if self.chinese_synopsis.present?
    self.chinese_cast = self.chinese_cast
                            .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                            .strip
                            .gsub(/(\.\s{2,})/, '. ')
                            .strip if self.chinese_cast.present?
    self.chinese_director = self.chinese_director
                                .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                                .strip
                                .gsub(/(\.\s{2,})/, '. ')
                                .strip if self.chinese_director.present?

    self.imdb_synopsis = self.imdb_synopsis
                             .gsub(/(\r\n|\r|\n|\u0085|\u000C|\u2028|\u2029|\s{2,})/, ' ')
                             .strip
                             .gsub(/(\.\s{2,})/,'. ')
                             .strip if self.imdb_synopsis.present?
  end
  
  def movie_genres_string
    genres = self.movie_genres.collect{|genre| genre.name}
    genres.nil? ? "" : genres.join(', ')
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
  
  scope :with_screener_remark, lambda { |screener_remark| {:conditions => "screener_remarks_mask & #{2**SCREENER_REMARKS.index(screener_remark.to_s)} > 0"} }
  
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
  
  # scope :with_old_language_track, lambda { |language_track| {:conditions => "language_tracks_mask & #{2**IIM::MOVIE_LANGUAGES.index(old_language_track.to_s)} > 0"} }
  #        
  #      def old_language_tracks=(old_language_tracks)
  #        self.language_tracks_mask = (old_language_tracks & IIM::MOVIE_LANGUAGES).map { |r| 2**IIM::MOVIE_LANGUAGES.index(r) }.sum
  #      end
  #      
  #      def old_language_tracks
  #        IIM::MOVIE_LANGUAGES.reject { |r| ((language_tracks_mask || 0) & 2**IIM::MOVIE_LANGUAGES.index(r)).zero? }
  #      end
  #      
  #      def old_language_track_symbols
  #        old_language_tracks.map(&:to_sym)
  #      end
  #   
  #   scope :with_language_subtitle, lambda { |language_subtitle| {:conditions => "language_subtitles_mask & #{2**IIM::MOVIE_LANGUAGES.index(language_subtitle.to_s)} > 0"} }
  #     
  #   def old_language_subtitles=(old_language_subtitles)
  #     self.language_subtitles_mask = (old_language_subtitles & IIM::MOVIE_LANGUAGES).map { |r| 2**IIM::MOVIE_LANGUAGES.index(r) }.sum
  #   end
  #   
  #   def old_language_subtitles
  #     IIM::MOVIE_LANGUAGES.reject { |r| ((language_subtitles_mask || 0) & 2**IIM::MOVIE_LANGUAGES.index(r)).zero? }
  #   end
  #   
  #   def language_subtitle_symbols
  #     old_language_subtitles.map(&:to_sym)
  #   end
  #   
 
  
end
